//
//  CheckViewController.swift
//  BiocheckMovil
//
//  Created by Arturo Avalos on 4/20/18.
//  Copyright © 2018 Arturo Avalos. All rights reserved.
//

import UIKit
import CoreLocation
import MobileCoreServices
import AVFoundation

class CheckViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblCompany: UILabel!
    @IBOutlet weak var txtViewDir: UITextView!
    @IBOutlet weak var imgLocation: UIImageView!
    @IBOutlet weak var btnCheckIn: UIButton!
    @IBOutlet weak var btnCheckOut: UIButton!
    @IBOutlet weak var checkStack: UIStackView!
    @IBOutlet weak var employeStack: UIStackView!
    @IBOutlet weak var actIndicator: UIActivityIndicatorView!
    @IBOutlet weak var lblInternetError: UILabel!
    
    private var canCheckResult: Array<Int>?
    private var timer = Timer()
    private var imagePicker: UIImagePickerController!
    private var userLocation: CLLocation!
    
    var employee: Employee?
    var locationManager: CLLocationManager!
    var tokenGnrl: NSObjectProtocol?
    var tokenImage: NSObjectProtocol?
    
    enum CHECK_STATUS {
        case uknow
        case can_check
        case check_mobile
        case cant_check
    }
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("check")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if Login.getToken() != nil{
            refreshView()
        }
    }
    
    func refreshView()  {
        txtViewDir.isHidden = true
        imgLocation.isHidden = true
        actIndicator.hidesWhenStopped = true
        
        if tokenGnrl != nil {
            NotificationCenter.default.removeObserver(self.tokenGnrl!)
            tokenGnrl = nil
        }
        if tokenImage != nil {
            NotificationCenter.default.removeObserver(self.tokenImage!)
            tokenImage = nil
        }
        
        btnCheckIn.isEnabled = true
        btnCheckOut.isEnabled = true
        
        setObserverEmployee()
        determineMyCurrentLocation()
        updateClock()
        
        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(CheckViewController.updateClock), userInfo: nil, repeats: true)
    }
    
    func setObserverEmployee(){
        let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
        let onGetEmployeeData = Notification.Name("onGetEmployeeData")
        
        if tokenGnrl == nil {
            Employee.getEmployeeData()
            setViewStatus(enable: false)
            
            tokenGnrl = NotificationCenter.default.addObserver(forName: onGetEmployeeData, object: nil, queue: nil) { (notification) in
                
                if self.tokenGnrl != nil {
                    NotificationCenter.default.removeObserver(self.tokenGnrl!)
                    self.tokenGnrl = nil
                }
                
                if let employee = notification.object as? Employee {
                    if employee.enrolled == true {
                        self.lblInternetError.isHidden = true
                        self.setViewStatus(enable: true)
                        self.setEmployee(employee: employee)
                    }
                    else {
                        appDelegate?.showEnrollView()
                    }
                }
                    
                else {
                    self.lblInternetError.isHidden = false
                }
                
                self.actIndicator.stopAnimating()

            }
        }
    }
    
    func setObserverDaySettings(type: String){
        
        btnCheckIn.isEnabled = false
        btnCheckOut.isEnabled = false
        
        var cLLocation: CLLocation?
        let alert = UIAlertController(title: "Error", message: "Error no especificado",preferredStyle: .alert)
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection()
        alert.popoverPresentationController?.sourceRect = CGRect(x: (self.view.bounds.midX), y: (self.view.bounds.midY), width: 0, height: 0)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default))
        let onGetEmployeeRoutsData = Notification.Name("onGetEmployeeRoutsData")
        
        if tokenGnrl == nil {
            DaySettings.getEmployeeRoutsData()
            tokenGnrl = NotificationCenter.default.addObserver(forName: onGetEmployeeRoutsData, object: nil, queue: nil) { (notification) in
        
                if self.tokenGnrl != nil {
                    NotificationCenter.default.removeObserver(self.tokenGnrl!)
                    self.tokenGnrl = nil
                }
                
                if let daySettings = notification.object as? DaySettings {
        
                        for rout in daySettings.routes {
                            if let routeLocation = rout.routeLocations.first {
                                
                                switch type {
                                case "in":
                                    if !routeLocation.checkIn {
                                        continue
                                    }
                                    break
                                case "out":
                                    if !routeLocation.checkOut {
                                        continue
                                    }
                                    break
                                    default:
                                        break
                                }
                                
                                guard let lat = routeLocation.location.latitude else {
                                    continue
                                }
                                guard let long = routeLocation.location.longitude else {
                                    continue
                                }
                                
                                cLLocation = CLLocation(latitude: lat, longitude: long)
                                if self.userLocation != nil {
                                    let distance = self.userLocation.distance(from: cLLocation!)
                                    if distance.magnitude <= routeLocation.location.distance! {
                                        
                                        self.canCheckResult = [routeLocation.id,routeLocation.location.id!]
                                        if self.isImageCheck() {
                                            self.cameraSelected()
                                        }
                                        else {
                                            self.check(isImage: false)
                                        }
                                        
                                        return
                                    }
                                }
                            }
                        }
                    
                        alert.message = "No puedes checar en esta area"
                        self.present(alert, animated: true, completion: nil)
                }
                else  {
                    self.btnCheckIn.isEnabled = true
                    self.btnCheckOut.isEnabled = true
                    
                    return
                }
            }
        }
    }
    
    func setViewStatus(enable: Bool) {
        if enable {
            actIndicator.stopAnimating()
        }
        else {
            actIndicator.startAnimating()
        }
        employeStack.isHidden = !enable
        checkStack.isHidden = !enable

    }
    
    func setEmployee(employee: Employee){
        self.employee = employee
        lblName.text = employee.name + " " + employee.lastName
        lblCompany.text = employee.company
        
        if let location = employee.locations.first {
            txtViewDir.isHidden = false
            imgLocation.isHidden = false
            
            let str = location.street  ?? ""
            let ext = location.externalNumber  ?? ""
            let sub = location.suburb  ?? ""
            let zip = location.zipcode  ?? ""
            let mun = location.municipality  ?? ""
            
            txtViewDir.text = str + " " + ext + " " + sub + " " + zip + " " + mun
        }
    }
    
    func determineMyCurrentLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    func checkLocationPermissions() -> Bool {
        let status = CLLocationManager.authorizationStatus()
        if status == .notDetermined || status == .denied  {
            
            let settingsAppURL = URL(string: UIApplicationOpenSettingsURLString)!
            let alert = UIAlertController()
            alert.popoverPresentationController?.sourceView = self.view
            alert.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection()
            alert.popoverPresentationController?.sourceRect = CGRect(x: (self.view.bounds.midX), y: (self.view.bounds.midY), width: 0, height: 0)
            alert.title = "Error"
            alert.message = "La aplicacion requiere el servicio de ubicacion, desdeas activarlo ahora?"
            
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:{ action in
                UIApplication.shared.open(settingsAppURL, options: [:], completionHandler: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "Ahora no", style: UIAlertActionStyle.default))
            
            self.present(alert, animated: true, completion: nil)
            return false
        }
        
        return true
        
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations[0] as CLLocation
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error \(error)")
    }
    
//    func canCheck(type: String) {
//        var cLLocation: CLLocation?
//        let alert = UIAlertController(title: "Error", message: "Error no especificado",preferredStyle: .alert)
//
//        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default))
//
//        if let employee = employee {
//            if employee.checkMobile{
//                if checkLocationPermissions() {
//                    if let location = employee.locations.first {
//                        let lat = location.latitude
//                        let long = location.longitude
//
//                        if lat != nil || long != nil {
//                            cLLocation = CLLocation(latitude: lat!, longitude: long!)
//                            if userLocation != nil {
//                                let distance = userLocation.distance(from: cLLocation!)
//                                if distance.magnitude <= location.distance! {
//
//                                    canCheckResult = [0]
//                                    if isImageCheck() {
//                                        cameraSelected()
//                                    }
//                                    else {
//                                        check(isImage: false)
//                                    }
//
//                                    return
//                                }
//
//                                alert.message = "No puedes checar en esta area"
//                                self.present(alert, animated: true, completion: nil)
//                            }
//                        }
//                    }
//                    else {
//                        setObserverDaySettings(type: type)
//                        return
//                    }
//                }
//
//                return
//            }
//            else {
//                alert.message = "No cuentas con los permisos necesarios para hacer check desde tu mobil"
//            }
//        }
//        self.present(alert, animated: true, completion: nil)
//    }
    
    func canCheck(type: String) {

        let alert = UIAlertController(title: "Error", message: "Error no especificado",preferredStyle: .alert)
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection()
        alert.popoverPresentationController?.sourceRect = CGRect(x: (self.view.bounds.midX), y: (self.view.bounds.midY), width: 0, height: 0)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default))
        
        if let employee = employee {
            if employee.checkMobile{
                if checkLocationPermissions() {
                    if isImageCheck() {
                        cameraSelected()
                    }
                    else {
                        check(isImage: false)
                    }
                }

                return
            }
            else {
                alert.message = "No cuentas con los permisos necesarios para hacer check desde tu movil"
            }
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func isImageCheck() -> Bool {
        if let employee = employee {
            if employee.mobilePercentage == 0 {
                return false
            }
            
            var checkLog = Check.getCheck()
            
            if checkLog == nil {
                checkLog = Check(checks: 0, imgChecks: 0)!
                print(NSKeyedArchiver.archiveRootObject(checkLog!, toFile: Check.ArchiveURL.path))
                
            }
            
            var percent: Double
            if (checkLog?.checks)! < 1 {
                percent = 0
            }
            else {
                percent = Double((checkLog?.imgChecks)! * 100 / (checkLog?.checks)!)
            }
            return percent <= employee.mobilePercentage
        }
        return false
    }
    
    
    @objc private func updateClock(){
        let date = Date()
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateStyle = DateFormatter.Style.medium
        let dateStr = dateFormatter.string(from: date)
        
        dateFormatter.dateFormat = "HH:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        
        let timeStr = dateFormatter.string(from: date)
        
        lblTime.text = timeStr
        lblDate.text = dateStr
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onBtnRecordInTouch(_ sender: UIButton) {
        canCheck(type: "in")
    }
    
    @IBAction func onbtnRecordOutTouch(_ sender: UIButton) {
        canCheck(type: "out")
    }
    
//    func check(isImage: Bool) {
//        var rId: Int? = nil
//        var lId: Int? = nil
//        var type = "record"
//        if (canCheckResult?.count)! > 1 {
//            type = "recordRoute"
//            rId = canCheckResult?[0]
//            lId = canCheckResult?[1]
//        }
//
//        btnCheckIn.isEnabled = false
//        btnCheckOut.isEnabled = false
//
//        let onSendCheck = Notification.Name("onSendCheck")
//
//        if tokenGnrl == nil {
//            tokenGnrl = NotificationCenter.default.addObserver(forName: onSendCheck, object: nil, queue: nil) { (notification) in
//                if self.tokenGnrl != nil {
//                    NotificationCenter.default.removeObserver(self.tokenGnrl!)
//                    self.tokenGnrl = nil
//                }
//                self.btnCheckIn.isEnabled = true
//                self.btnCheckOut.isEnabled = true
//            }
//
//            Check.sendCheck(inOut: false, lat: userLocation.coordinate.latitude, long: userLocation.coordinate.longitude, isImage: isImage, type: type, rId: rId, lId: lId)
//        }
//    }
    
    
    func check(isImage: Bool) {
        let rId: Int? = nil
        let lId: Int? = nil
        let type = "record"
        
        btnCheckIn.isEnabled = false
        btnCheckOut.isEnabled = false
        
        let onSendCheck = Notification.Name("onSendCheck")
        
        if tokenGnrl == nil {
            tokenGnrl = NotificationCenter.default.addObserver(forName: onSendCheck, object: nil, queue: nil) { (notification) in
                if self.tokenGnrl != nil {
                    NotificationCenter.default.removeObserver(self.tokenGnrl!)
                    self.tokenGnrl = nil
                }
                self.btnCheckIn.isEnabled = true
                self.btnCheckOut.isEnabled = true
            }
            
            Check.sendCheck(inOut: false, lat: userLocation.coordinate.latitude, long: userLocation.coordinate.longitude, isImage: isImage, type: type, rId: rId, lId: lId)
        }
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage{
            
            let onValidateEmployee = Notification.Name("onValidateEmployee")
            tokenImage = NotificationCenter.default.addObserver(forName: onValidateEmployee, object: nil, queue: nil) { (notification) in
                if self.tokenImage != nil {
                    NotificationCenter.default.removeObserver(self.tokenImage!)
                    self.tokenImage = nil
                }
                
                if notification.object as? Bool == true {
                    self.check(isImage: true)
                }
                else {
                    self.btnCheckIn.isEnabled = true
                    self.btnCheckOut.isEnabled = true
                }
            }
            
            btnCheckIn.isEnabled = false
            btnCheckOut.isEnabled = false
            Check.validateUser(myImageView: image)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }


    func cameraSelected() {
        let deviceHasCamera = UIImagePickerController.isSourceTypeAvailable(.camera)
        if deviceHasCamera {
            let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
            switch authStatus {
            case .notDetermined:
                permissionPrimeCameraAccess()
            case .authorized:
                showCameraPicker()
            case .restricted, .denied:
                alertCameraAccessNeeded()
            }
        } else {
            let alertController = UIAlertController(title: "Error", message: "El dispositivo no cuenta con una camara", preferredStyle: .alert)
            alertController.popoverPresentationController?.sourceView = self.view
            alertController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection()
            alertController.popoverPresentationController?.sourceRect = CGRect(x: (self.view.bounds.midX), y: (self.view.bounds.midY), width: 0, height: 0)
            let defaultAction = UIAlertAction(title: "OK", style: .default)
            alertController.addAction(defaultAction)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func permissionPrimeCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: {accessGranted in
            guard accessGranted == true else { return }
            self.showCameraPicker()
        })
    }
    
    func showCameraPicker() {
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        imagePicker.cameraDevice = .front;
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func alertCameraAccessNeeded() {
        let settingsAppURL = URL(string: UIApplicationOpenSettingsURLString)!
        
        let alert = UIAlertController(
            title: "Se necesita acceso a la camara",
            message: "Se necesita acceso a la camara para hacer check",
            preferredStyle: UIAlertControllerStyle.alert
        )
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection()
        alert.popoverPresentationController?.sourceRect = CGRect(x: (self.view.bounds.midX), y: (self.view.bounds.midY), width: 0, height: 0)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (alert) -> Void in
            UIApplication.shared.open(settingsAppURL, options: [:], completionHandler: nil)
        }))
        alert.addAction(UIAlertAction(title: "Ahora no", style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let routViewController = segue.destination as? RoutViewController else {
            fatalError("Unexpected destination: \(segue.destination)")
        }
        
        if let location = employee?.locations.first{
            routViewController.location = location
        } else {
            fatalError("Localizacion invalida")
        }
    }
    
    
}
