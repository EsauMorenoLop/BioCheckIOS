//
//  RoutTableViewCell.swift
//  BiocheckMovil
//
//  Created by Arturo Avalos on 4/17/18.
//  Copyright © 2018 Arturo Avalos. All rights reserved.
//

import UIKit

class RoutTableViewCell: UITableViewCell {

    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var txtViewDir: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
