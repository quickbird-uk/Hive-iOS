//
//  TableViewCellWithSwitch.swift
//  Hive
//
//  Created by Animesh. on 04/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit

class TableViewCellWithSwitch: UITableViewCell
{
    
    @IBOutlet weak var cellSwitch: UISwitch!
    @IBOutlet weak var title: UILabel!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
