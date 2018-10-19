//
//  RoutsTableViewController.swift
//  BiocheckMovil
//
//  Created by Arturo Avalos on 4/17/18.
//  Copyright © 2018 Arturo Avalos. All rights reserved.
//

import UIKit

class RoutsTableViewController: UITableViewController {

    @IBOutlet weak var lblHeader: UILabel!
    var daySettings: DaySettings?
    var routs = [RouteLocation]()
    var token: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Login.getToken() != nil{
            if token != nil {
                NotificationCenter.default.removeObserver(self.token!)
                token = nil
            }
            setObserver()
        }            
    }
    
    func refreshData()
    {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            return
        }
    }
    
    func setObserver(){
        if token == nil {
            DaySettings.getEmployeeRoutsData()
            let scoreChangedNotif = Notification.Name("onGetEmployeeRoutsData")
            token = NotificationCenter.default.addObserver(forName: scoreChangedNotif, object: nil, queue: nil) { (notification) in
                if let daySettings = notification.object as! DaySettings? {
                    self.setDaySettings(settings: daySettings)
                }
                if self.token != nil {
                    NotificationCenter.default.removeObserver(self.token!)
                    self.token = nil
                }
            }
        }
    }
    
    func setDaySettings(settings: DaySettings){
        daySettings = settings
        routs = [RouteLocation]()
        if let daySettings = daySettings?.routes.first {
            lblHeader.text = daySettings.name
            let routsLocations = daySettings.routeLocations
            if routsLocations.count > 0 {
                routs += routsLocations
            }
            refreshData()
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return routs.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "RoutTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? RoutTableViewCell  else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        
        let location = routs[indexPath.row].location
    
        cell.lblName.text = location.title
        cell.txtViewDir.text = (location.street)! + " " + (location.externalNumber)! + " " + (location.suburb)! + " " + (location.zipcode)! + " " + (location.municipality)!

        return cell
    }
 
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let routViewController = segue.destination as? RoutViewController else {
            fatalError("Unexpected destination: \(segue.destination)")
        }

        guard let selectedRoutCell = sender as? RoutTableViewCell else {
            fatalError("Unexpected sender: \(sender)")
        }
        
        guard let indexPath = tableView.indexPath(for: selectedRoutCell) else {
            fatalError("The selected cell is not being displayed by the table")
        }
        
        let selectedRout = routs[indexPath.row].location
        routViewController.location = selectedRout
    }
}
