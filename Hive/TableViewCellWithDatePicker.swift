//
//  TableViewCellWithDatePicker.swift
//  Hive
//
//  Created by Animesh. on 02/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit

class TableViewCellWithDatePicker: UITableViewCell
{
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var date: UIDatePicker!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
