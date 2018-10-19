//
//  Location.swift
//  BiocheckMovil
//
//  Created by Arturo Avalos on 4/26/18.
//  Copyright © 2018 Arturo Avalos. All rights reserved.
//

import UIKit

struct Location: Codable {
    var deleted: Bool?
    var distance: Double?
    var externalNumber: String?
    var id: Int?
    var internalNumber: String?
    var latitude : Double?
    var longitude: Double?
    var municipality: String?
    var street: String?
    var suburb: String?
    var title: String?
    var zipcode: String?
    
    init(lat: Double, long: Double){
        self.latitude = lat
        self.longitude = long
        self.deleted = nil
        self.distance = nil
        self.externalNumber = nil
        self.id = nil
        self.internalNumber = nil
        self.municipality = nil
        self.street = nil
        self.suburb = nil
        self.title = nil
        self.zipcode = nil

    }
    
}

