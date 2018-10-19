//
//  EnrollViewController.swift
//  BiocheckMovil
//
//  Created by Arturo Avalos on 5/16/18.
//  Copyright © 2018 Arturo Avalos. All rights reserved.
//

import UIKit
import AVFoundation

class EnrollViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var lblPhotoCount: UILabel!
    @IBOutlet weak var btnTakePhoto: UIButton!
    private var imagePicker: UIImagePickerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onBtnBackTouch(_ sender: Any) {
        let alert = UIAlertController(title: "Cerrar Sesion", message: "Seguro que deseas cerrar sesion?", preferredStyle: UIAlertControllerStyle.alert)
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection()
        alert.popoverPresentationController?.sourceRect = CGRect(x: (self.view.bounds.midX), y: (self.view.bounds.midY), width: 0, height: 0)
        alert.addAction(UIAlertAction(title: "Cancelar", style: UIAlertActionStyle.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Continuar", style: UIAlertActionStyle.default, handler: { action in
            let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
            appDelegate?.logOut()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    @IBAction func onBtnTakePhotoTouch(_ sender: UIButton) {
        cameraSelected()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage{
            sendEnrollImg(img: image)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }

    func sendEnrollImg(img: UIImage) {
        let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
        let alert = UIAlertController(title: "Error", message: "Error no especificado", preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceView = appDelegate?.window?.rootViewController?.view
        alert.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection()
        alert.popoverPresentationController?.sourceRect = CGRect(x: (appDelegate?.window?.rootViewController?.view.bounds.midX)!, y: (appDelegate?.window?.rootViewController?.view.bounds.midY)!, width: 0, height: 0)
        
        guard let token: String = Login.getToken() else {
            alert.message = "Token invalido"
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:{ action in
                appDelegate?.logOut()
            }))
            appDelegate?.window?.rootViewController?.present(alert, animated: true, completion: nil)
            return
        }

        let myUrl = URL(string: "https://api-m.biocheck.net/api/v1/photo/enroll");

        var request = URLRequest(url:myUrl! )
        request.httpMethod = "POST";


        let boundary = Request.generateBoundaryString()

        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let imageData = UIImageJPEGRepresentation(img, 1)

        if(imageData==nil)  { return; }

        request.timeoutInterval = 10
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        request.httpBody = Request.createBodyWithImage(filePathKey: "photo", imageDataKey: imageData! as NSData, boundary: boundary) as Data

        let sesion = URLSession.shared.dataTask(with: request) { (responseData: Data?, response: URLResponse?, error: Error?) in
            DispatchQueue.main.async { self.btnTakePhoto.isEnabled = true }
            if let response = response as? HTTPURLResponse{
                if let data = responseData {
                    let json = try? JSONSerialization.jsonObject(with: data, options: [])
                    if let dictionary = json as? [String: Any] {
                        if response.statusCode == 201 {
                            let imagesNedeed = dictionary["imagesNedeed"] as? Int
                            let imagesCount = dictionary["imagesCount"] as? Int
                            let verified = dictionary["verified"] as? Bool
                        
                            if imagesNedeed == nil || imagesCount == nil || verified == nil {
                                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default ))
                            }
                        
                            if imagesNedeed! == imagesCount! && verified! {
                                alert.title = "Felicitaciones!"
                                alert.message = "Haz finalizado la face de registro"
                                alert.addAction(UIAlertAction(title: "Finalizar", style: UIAlertActionStyle.default, handler:{ action in
                                    DispatchQueue.main.async { appDelegate?.logIn() }
                                }))
                            }
                            else {
                                DispatchQueue.main.async { self.lblPhotoCount.text = "Foto " + String(imagesCount!) + "/" + String(imagesNedeed!) }
                                alert.title = "Correcto"
                                alert.message = "Continuar con la face de registro?"
                                alert.addAction(UIAlertAction(title: "Cancelar", style: UIAlertActionStyle.default,handler:{ action in
                                    DispatchQueue.main.async { appDelegate?.logOut() }
                                }))
                                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:{ action in
                                    DispatchQueue.main.async { self.cameraSelected() }
                                }))
                            }
                            DispatchQueue.main.async { self.present(alert, animated: true, completion: nil) }
                            
                            return
                        } else {
                            
                            if response.statusCode != 500 {
                                if let message = dictionary["message"] as? String {
                                    switch message {
                                    case "INVALID_FACE", "TO_MANY_FACES":
                                        alert.message = "Foto inválida, intente de nuevo."
                                        break
                                    default:
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                let error = (error! as NSError).code
                
                switch error {
                case -1001:
                    alert.message = "Sin respuesta del servidor"
                    break
                case -1009:
                    alert.message = "Error de red, revisa tu conexión a internet"
                    break
                default: break
                    
                }
            }
            
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:nil))
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        }
        btnTakePhoto.isEnabled = false
        sesion.resume()

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
            title: "Acceso a camara requerido",
            message: "Para continuar es necesario el acceso a la camara",
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

}
