//
//  RecordTableViewCell.swift
//  BiocheckMovil
//
//  Created by Arturo Avalos on 4/19/18.
//  Copyright © 2018 Arturo Avalos. All rights reserved.
//

import UIKit

class RecordTableViewCell: UITableViewCell {
    @IBOutlet weak var imgCheckDevice: UIImageView!
    @IBOutlet weak var lblCheckTime: UILabel!
    @IBOutlet weak var lblCheckDevice: UILabel!
    @IBOutlet weak var lblCheckDate: UILabel!
    @IBOutlet weak var imgCheckRout: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setRecord(record: Record){
        if record.serialNumber == "mobile"{
            imgCheckDevice.image = #imageLiteral(resourceName: "phone")
            imgCheckRout.image = #imageLiteral(resourceName: "location")
        }
        else {
            imgCheckDevice.image = #imageLiteral(resourceName: "clock")
            imgCheckRout.image = nil
        }
        
        lblCheckDevice.text = record.serialNumber

 
        
        let dateSbs = record.recTime.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: true)
        let dateStr = dateSbs[0].description
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'@'HH:mm:ss"
        dateFormatter.timeZone = NSTimeZone.local
        
        if let date = dateFormatter.date(from: dateStr) {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateStr = dateFormatter.string(from: date)
            dateFormatter.dateFormat = "HH:mm:ss"
            let timeStr = dateFormatter.string(from: date)
            
            lblCheckDate.text = dateStr
            lblCheckTime.text = timeStr
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
