//
//  RecordTableViewController.swift
//  BiocheckMovil
//
//  Created by Arturo Avalos on 4/19/18.
//  Copyright © 2018 Arturo Avalos. All rights reserved.
//

import UIKit

class RecordTableViewController: UITableViewController {
    
    var records = [Record]()
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
    
    func setObserver(){
        if token == nil {
            Record.getEmployeeRecords()
            let onGetEmployeeRecords = Notification.Name("onGetEmployeeRecords")
            token = NotificationCenter.default.addObserver(forName: onGetEmployeeRecords, object: nil, queue: nil) { (notification) in
                if let records = notification.object as! [Record]? {
                    self.setEmployeeRecords(records: records)
                }
                if self.token != nil {
                    NotificationCenter.default.removeObserver(self.token!)
                    self.token = nil
                }
            }
        }
    }
    
    func refreshData()
    {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            return
        }
    }
    
    func setEmployeeRecords(records: [Record]){
        self.records = [Record]()
        if records.count > 0 {
            self.records += records
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
        return records.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "RecordTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? RecordTableViewCell  else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        
        let record = records[indexPath.row]
        cell.setRecord(record: record)
        return cell
    }
   
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let mealDetailViewController = segue.destination as? RoutViewController else {
            fatalError("Unexpected destination: \(segue.destination)")
        }

        guard let selectedRecordCell = sender as? RecordTableViewCell else {
            fatalError("Unexpected sender: \(sender)")
        }

        guard let indexPath = tableView.indexPath(for: selectedRecordCell) else {
            fatalError("The selected cell is not being displayed by the table")
        }

        let selectedRecord = records[indexPath.row]
        if let coords = selectedRecord.coordinates?.split(separator: ",") {
            let lat = Double(coords[0])
            let long = Double(coords[1])
            
            if lat != nil && long != nil {
                let location = Location(lat: lat!, long: long!)
                mealDetailViewController.location = location
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        guard let selectedRecordCell = sender as? RecordTableViewCell else {
            fatalError("Unexpected sender: \(sender)")
        }
        
        guard let indexPath = tableView.indexPath(for: selectedRecordCell) else {
            fatalError("The selected cell is not being displayed by the table")
        }
        let selectedRecord = records[indexPath.row]
        
        if selectedRecord.serialNumber != "mobile" || selectedRecord.coordinates == "<nil>" {
            selectedRecordCell.setSelected(false, animated: true)
            return false
        }
        return true
    }
    
}
