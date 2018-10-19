//
//  Login.swift
//  BiocheckMovil
//
//  Created by Arturo Avalos on 4/25/18.
//  Copyright © 2018 Arturo Avalos. All rights reserved.
//

import UIKit
import os.log

class Login: NSObject, NSCoding  {
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("login")
    
    struct PropertyKey {
        static let token = "token"
    }
    
    var token: String?
    
    init?(token: String?) {
        self.token = token
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(token, forKey: PropertyKey.token)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let token = aDecoder.decodeObject(forKey: PropertyKey.token) as? String else {
            os_log("Unable to decode the name for a Meal object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        self.init(token: token)

    }
    
    static func getToken() -> String?  {
        if let loginSession = NSKeyedUnarchiver.unarchiveObject(withFile: Login.ArchiveURL.path) as? Login {
            return loginSession.token
        } else {
            return nil            
        }
    }
    
    static func deleteToken() -> Bool{
        let exists = FileManager.default.fileExists(atPath: Login.ArchiveURL.path)
        if exists {
            do {
                try FileManager.default.removeItem(atPath: Login.ArchiveURL.path)
            }catch let error as NSError {
                print("error: \(error.localizedDescription)")
                return false
            }
        }
        return exists
    }
}



