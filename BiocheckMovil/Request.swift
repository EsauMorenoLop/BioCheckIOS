//
//  Request.swift
//  BiocheckMovil
//
//  Created by Arturo Avalos on 5/16/18.
//  Copyright © 2018 Arturo Avalos. All rights reserved.
//

import UIKit

struct Request {
    
//    static func sendRequest(params: [String: String]) {
//        var r  = URLRequest(url: URL(string: "https://prospero.uatproxy.cdlis.co.uk/prospero/DocumentUpload.ajax")!)
//        r.httpMethod = "POST"
//        let boundary = "Boundary-\(UUID().uuidString)"
//        r.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//
//
//        r.httpBody = createBody(params: params,
//                                boundary: boundary,
//                                data: UIImageJPEGRepresentation(chosenImage, 0.7)!,
//                                mimeType: "image/jpg",
//                                filename: "hello.jpg")
//    }
//
//    private func createBody(params: [String: String], boundary: String) -> Data{
//        let body = Data();
//
//        for (key, value) in params {
//            body.appendString(string: "--\(boundary)--\r\n")
//            body.appendString(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
//            body.appendString(string: "\(value)\r\n")
//        }
//
//        return body
//    }
//
    static func createBodyWithImage( filePathKey: String?, imageDataKey: NSData, boundary: String) -> Data {
        var body = Data();

        let filename = "user-profile.jpg"
        let mimetype = "image/*"

        body.appendString(string: "--\(boundary)\r\n")
        body.appendString(string: "Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n")
        body.appendString(string: "Content-Type: \(mimetype)\r\n\r\n")
        body.append(imageDataKey as Data)
        body.appendString(string: "\r\n")



        body.appendString(string: "--\(boundary)--\r\n")

        return body
    }


    static func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
}

extension Data {

    mutating func appendString(string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
}

