//
//  Login.swift
//  BiocheckMovil
//
//  Created by Arturo Avalos on 4/25/18.
//  Copyright © 2018 Arturo Avalos. All rights reserved.
//

import UIKit
import os.log

class Check: NSObject, NSCoding  {
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("check")
    
    struct PropertyKey {
        static let checks = "checks"
        static let imgChecks = "imgChecks"
    }
    
    var checks: Int?
    var imgChecks: Int?
    
    init?(checks: Int, imgChecks: Int) {
        self.checks = checks
        self.imgChecks = imgChecks
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(checks, forKey: PropertyKey.checks)
        aCoder.encode(imgChecks, forKey: PropertyKey.imgChecks)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        guard let checks = aDecoder.decodeObject(forKey: PropertyKey.checks) as? Int else {
            return nil
        }
        
        guard let imgChecks = aDecoder.decodeObject(forKey: PropertyKey.imgChecks) as? Int else {
            return nil
        }
        
        self.init(checks: checks as! Int, imgChecks: imgChecks)
        
    }
    
    static func getCheck() -> Check?  {
        if let checkLog = NSKeyedUnarchiver.unarchiveObject(withFile: Check.ArchiveURL.path) as? Check {
            return checkLog
        } else {
            return nil
        }
    }
    
    static func deleteCheck() -> Bool{
        let exists = FileManager.default.fileExists(atPath: Check.ArchiveURL.path)
        if exists {
            do {
                try FileManager.default.removeItem(atPath: Check.ArchiveURL.path)
            }catch let error as NSError {
                print("error: \(error.localizedDescription)")
                return false
            }
        }
        return exists
    }
    
    static func sendCheck( inOut: Bool, lat: Double, long: Double, isImage: Bool, type: String, rId: Int?, lId: Int?) {
        
        let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
        let alert = UIAlertController(title: "Error", message: "Error no especificado",preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceView = appDelegate?.window?.rootViewController?.view
        alert.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection()
        alert.popoverPresentationController?.sourceRect = CGRect(x: (appDelegate?.window?.rootViewController?.view.bounds.midX)!, y: (appDelegate?.window?.rootViewController?.view.bounds.midY)!, width: 0, height: 0)
        
        
//        let alertController = UIAlertController(title: nil, message: "Alert message.", preferredStyle: .actionSheet)
//
//        let defaultAction = UIAlertAction(title: "Default", style: .default, handler: { (alert: UIAlertAction!) -> Void in
//            //  Do some action here.
//        })
//
//        let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (alert: UIAlertAction!) -> Void in
//            //  Do some destructive action here.
//        })
//
//        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (alert: UIAlertAction!) -> Void in
//            //  Do something here upon cancellation.
//        })
//
//        alertController.addAction(defaultAction)
//        alertController.addAction(deleteAction)
//        alertController.addAction(cancelAction)
//      
//
//
//
        guard let token: String = Login.getToken() else {
            alert.message = "Token invalido"
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:{ action in
                appDelegate?.logOut()
            }))
            appDelegate?.window?.rootViewController?.present(alert, animated: true, completion: nil)
            return
        }

        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api-m.biocheck.net"
        urlComponents.path = "/api/v1/employee/" + type
        
        if rId != nil && lId != nil {
            urlComponents.queryItems = [URLQueryItem (name: "rId", value: String(rId!)), URLQueryItem (name: "lId", value: String(lId!))]
        }
        
        var request = URLRequest(url:urlComponents.url!)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        request.timeoutInterval = 10
        
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        
        let timeStr = dateFormatter.string(from: date)
        print(timeStr)
        
        let checkParams: [String: Any] = ["checkInOut": inOut, "commentary": "", "date": timeStr, "latitude": lat, "longitude": long, "timeZone": 0]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: checkParams, options: []) else { return }
        request.httpBody = httpBody
        
        let sesion = URLSession.shared.dataTask(with: request) { (responseData: Data?, response: URLResponse?, error: Error?) in
            if let response = response as? HTTPURLResponse{
                if response.statusCode == 200 {
                    DispatchQueue.main.async {
                        
                        if let checkLog : Check = getCheck() {
                            checkLog.checks! += 1
                            if isImage {
                                checkLog.imgChecks! += 1
                            }
                            NSKeyedArchiver.archiveRootObject(checkLog, toFile: Check.ArchiveURL.path)
                        }
                        
                        alert.title = "Correcto"
                        alert.message = "El registro ha sido exitoso."
                    
                        DispatchQueue.main.async {
                            let onSendCheck = Notification.Name("onSendCheck")
                            NotificationCenter.default.post(name: onSendCheck, object: nil)
                        }
                        
                        return
                    }
                }
                else {
                    if let data = responseData {
                        let json = try? JSONSerialization.jsonObject(with: data, options: [])
                        if let dictionary = json as? [String: Any] {
                            if let message = dictionary["message"] as? String {
                                switch message {
                                    case "THE USER IS INVALID":
                                        alert.message = "Usuario invalido"
                                        break
                                    default:
                                        break
                                }
                            }
                        }
                    }
                }
            }
            else {
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
            
            DispatchQueue.main.async {
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:nil))
                appDelegate?.window?.rootViewController?.present(alert, animated: true, completion: nil)
            }
        }
        sesion.resume()
    }
    
    static func generateBoundary() -> String {
        return "Boundary-\(UUID().uuidString)"
    }
    
    static func validateUser(myImageView: UIImage)
    {
        let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
        
        let alert = UIAlertController()
        alert.title = "Error"
        alert.message = "Hubo un error al procesar tu foto, intenta de nuevo"
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
        
        let myUrl = URL(string: "https://api-m.biocheck.net/api/v1/photo/validate");
        
        var request = URLRequest(url:myUrl! )
        request.httpMethod = "POST";
        
        
        let boundary = Request.generateBoundaryString()
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let imageData = UIImageJPEGRepresentation(myImageView, 1)
        
        if(imageData==nil)  { return; }
        
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        request.httpBody = Request.createBodyWithImage(filePathKey: "photo", imageDataKey: imageData! as NSData, boundary: boundary) as Data
        
        
        let sesion = URLSession.shared.dataTask(with: request) { (responseData: Data?, response: URLResponse?, error: Error?) in
            if let response = response as? HTTPURLResponse{
                print(response)
                if response.statusCode == 200 {
                    DispatchQueue.main.async {
                        let onValidateEmployee = Notification.Name("onValidateEmployee")
                        NotificationCenter.default.post(name: onValidateEmployee, object: true)
                    }
                    
                    return
                }
                else {
                    if response.statusCode != 500 {
                        if response.statusCode == 404 {
                            alert.message = "Empleado invalido"
                        }
                        else {
                            if let data = responseData {
                                let json = try? JSONSerialization.jsonObject(with: data, options: [])
                                if let dictionary = json as? [String: Any] {
                                    if let message = dictionary["message"] as? String {
                                        print(message)
                                        switch message {
                                        case "INVALID_IMAGE":
                                            alert.message = "Foto invalida, prueba en un lugar con mejor contraste"
                                            break                                      
                                        default:
                                            break
                                        }
                                    }
                                }
                                
                            }
                        }
                    }

                    if alert.message == "Token invalido" {
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:{ action in
                            DispatchQueue.main.async {
                                appDelegate?.logOut()
                            }
                        }))
                    } else {
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:nil))
                    }
                }
                
                DispatchQueue.main.async {
                    let onValidateEmployee = Notification.Name("onValidateEmployee")
                    NotificationCenter.default.post(name: onValidateEmployee, object: false)
                    appDelegate?.window?.rootViewController?.present(alert, animated: true, completion: nil)
                }
            }                                            
        }
        
        sesion.resume()
    }
    
    
}




