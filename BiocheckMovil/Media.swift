//
//  Media.swift
//  BiocheckMovil
//
//  Created by Arturo Avalos on 5/15/18.
//  Copyright © 2018 Arturo Avalos. All rights reserved.
//

import UIKit

struct Media {

    
    let Key: String
    let fileName: String
    let data: Data
    let mimeType: String
    
    init?(withImage image: UIImage, forKey key: String) {
        self.Key = key
        self.mimeType = "image/jpeg"
        self.fileName = "\(arc4random()).jpeg"
        
        guard let data =  UIImageJPEGRepresentation(image, 0.7) else {return nil}
        self.data = data
    }
    
    func generateBoundary() -> String {
        return "Boundary-\(UUID().uuidString)"
    }

}

