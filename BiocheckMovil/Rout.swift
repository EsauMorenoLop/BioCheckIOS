//
//  Rout.swift
//  BiocheckMovil
//
//  Created by Arturo Avalos on 4/18/18.
//  Copyright © 2018 Arturo Avalos. All rights reserved.
//

import UIKit

class Rout {
    var name: String
    var dir: String
    
    init?(name: String, dir: String){
        guard !name.isEmpty else{
            return nil
        }
        guard !dir.isEmpty else{
            return nil
        }
        self.name = name
        self.dir = dir
    }
}

struct RouteLocation: Codable{
    let id: Int
    let position: Int
    let checkIn: Bool
    let checkOut: Bool
    let createTime: UInt64
    let location: Location
}

struct Route: Codable {
    let id: Int
    let name: String
    let createTime: UInt64
    let deleted: Bool
    let description: String?
    let routeLocations: [RouteLocation]
}

struct WorkShift: Codable {
    let days: Int
    let endTime: String
    let id: Int
    let startTime: String
}

struct DaySettings: Codable {
    let routes: [Route]
    let workShifts: [WorkShift?]
    let locations: [Location?]
    
    static func getEmployeeRoutsData() {
        
        let onGetEmployeeRoutsData = Notification.Name("onGetEmployeeRoutsData")
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
        
        let timeStr = dateFormatter.string(from: date)
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api-m.biocheck.net"
        urlComponents.path = "/api/v1/employee/daySettings"
        urlComponents.queryItems = [URLQueryItem(name: "date", value: timeStr)]
        
        var request = URLRequest(url:urlComponents.url!)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        
        let sesion = URLSession.shared.dataTask(with: request) { (responseData: Data?, response: URLResponse?, error: Error?) in
            if let response = response as? HTTPURLResponse{
                if response.statusCode == 200 {
                    if let data = responseData {
                        var daySettings: DaySettings?
                        daySettings = try? JSONDecoder().decode(DaySettings.self, from: data)
                        
                        if let daySettings = daySettings{
                            DispatchQueue.main.async {
                                
                                NotificationCenter.default.post(name: onGetEmployeeRoutsData, object: daySettings)
                                appDelegate?.daySettings = daySettings                                
                            }
                            return
                        }
                    }
                }
                else {
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
                NotificationCenter.default.post(name: onGetEmployeeRoutsData, object: nil)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:nil))
                appDelegate?.window?.rootViewController?.present(alert, animated: true, completion: nil)
            }
        }
        sesion.resume()
    }
    
}
