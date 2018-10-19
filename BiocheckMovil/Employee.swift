//
//  Employee.swift
//  BiocheckMovil
//
//  Created by Arturo Avalos on 4/26/18.
//  Copyright © 2018 Arturo Avalos. All rights reserved.
//

import UIKit

struct Employee: Codable {
    let checkId: Int
    let checkMobile: Bool
    let company: String
    let deleted: Int
    let enrolled: Bool
    let id: Int
    let lastName : String
    let locations: [Location]
    let mobilePercentage: Double
    let name: String
    let nip: Int
    
    
    static func getEmployeeData() {
        
        let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
        
        let alert = UIAlertController(title: "Error", message: "Error no especificado",preferredStyle: .alert)
        alert.popoverPresentationController?.sourceView = appDelegate?.window?.rootViewController?.view
        alert.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection()
        alert.popoverPresentationController?.sourceRect = CGRect(x: (appDelegate?.window?.rootViewController?.view.bounds.midX)!, y: (appDelegate?.window?.rootViewController?.view.bounds.midY)!, width: 0, height: 0)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:nil))
        
        guard let token: String = Login.getToken() else {
            alert.message = "Token invalido"
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:{ action in
                appDelegate?.logOut()
            }))
            appDelegate?.window?.rootViewController?.present(alert, animated: true, completion: nil)
            return
        }
        
        let url = URL(string:"https://api-m.biocheck.net/api/v1/employee/")
        var request = URLRequest(url:url!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        request.timeoutInterval = 10
        
        let onGetEmployeeData = Notification.Name("onGetEmployeeData")
        
        let sesion = URLSession.shared.dataTask(with: request) { (responseData: Data?, response: URLResponse?, error: Error?) in
            if let response = response as? HTTPURLResponse{
                if response.statusCode == 200 {
                    if let data = responseData {
                        
                        var decodedEmployee: Employee?
                        decodedEmployee = try? JSONDecoder().decode(Employee.self, from: data)
                         
                        if let decodedEmployee = decodedEmployee{
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: onGetEmployeeData, object: decodedEmployee)
                                appDelegate?.employee = decodedEmployee
                            }                            
                            return
                        }
                    }
                } else {
                    if let data = responseData {
                        let json = try? JSONSerialization.jsonObject(with: data, options: [])
                        if let dictionary = json as? [String: Any] {
                            if let message = dictionary["message"] as? String {
                                switch message {
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
                NotificationCenter.default.post(name: onGetEmployeeData, object: nil)
                appDelegate?.window?.rootViewController?.present(alert, animated: true, completion: nil)
            }
        }
        sesion.resume()
    }

}


