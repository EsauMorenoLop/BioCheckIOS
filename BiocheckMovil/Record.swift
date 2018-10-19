//
//  Record.swift
//  BiocheckMovil
//
//  Created by Arturo Avalos on 4/19/18.
//  Copyright © 2018 Arturo Avalos. All rights reserved.
//

import UIKit

struct Record: Codable {
    var checkId: Int
    var checkInOut: Bool
    var coordinates: String?
    var id: Int
    var operationCode: Bool
    var recTime: String
    var serialNumber: String
    
    static func getEmployeeRecords() {
        
        let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
        let alert = UIAlertController(title: "Error", message: "Error no especificado",preferredStyle: .alert)
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
        
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api-m.biocheck.net"
        urlComponents.path = "/api/v1/employee/record"
        urlComponents.queryItems = [URLQueryItem(name: "endDate", value: dateFormatter.string(from: date)), URLQueryItem(name: "initDate", value: "Sat, 1 Jan 2000 16:34:19 CDT")]
        
        var request = URLRequest(url:urlComponents.url!)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        
        let sesion = URLSession.shared.dataTask(with: request) { (responseData: Data?, response: URLResponse?, error: Error?) in
            if let response = response as? HTTPURLResponse{
                if response.statusCode == 200 {
                    if let data = responseData {
                        let records = try? JSONDecoder().decode([Record].self, from: data)
                        if let records = records{
                            DispatchQueue.main.async {
                                let onGetEmployeeRecords = Notification.Name("onGetEmployeeRecords")
                                NotificationCenter.default.post(name: onGetEmployeeRecords, object: records)
                                appDelegate?.records = records                                                                
                            }
                            
                            return
                        } 
                    }
                    
                } else {
                    print(response)
                    if let data = responseData {
                        let json = try? JSONSerialization.jsonObject(with: data, options: [])
                        if let dictionary = json as? [String: Any] {
                            if let message = dictionary["message"] as? String {
                                print(message)
                                switch message {
                                default:
                                    break
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
            DispatchQueue.main.async {
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:nil))
                appDelegate?.window?.rootViewController?.present(alert, animated: true, completion: nil)
            }
        }
        sesion.resume()
    }
}
