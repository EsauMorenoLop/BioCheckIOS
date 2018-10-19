//
//  RoutViewController.swift
//  BiocheckMovil
//
//  Created by Arturo Avalos on 4/18/18.
//  Copyright © 2018 Arturo Avalos. All rights reserved.
//

import UIKit
import MapKit

class RoutViewController: UIViewController {

    @IBOutlet weak var mapViewRout: MKMapView!
    @IBOutlet weak var txtViewDir: UITextView!
    
    var location: Location?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let locCord = CLLocationCoordinate2DMake((location?.latitude)!, (location?.longitude)!)
        
        let span = MKCoordinateSpanMake(0.007,0.007)
        let region = MKCoordinateRegion(center: locCord, span: span)
        mapViewRout.setRegion(region, animated: true)
        
        let dropPin = MKPointAnnotation()
        dropPin.coordinate = locCord
        dropPin.title = location?.title
        mapViewRout.addAnnotation(dropPin)
        
        navigationItem.title = location?.title
        
        
        let str = location?.street  ?? ""
        let ext = location?.externalNumber  ?? ""
        let sub = location?.suburb  ?? ""
        let zip = location?.zipcode  ?? ""
        let mun = location?.municipality  ?? ""
        
        var dir = str + " " + ext  + " "
        dir = dir +  sub + " " + zip + " " + mun
        txtViewDir.text = dir
        
        if dir.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty {
            txtViewDir.constraints.first?.constant = 0
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
