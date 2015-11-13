//
//  TableViewCellWithButton.swift
//  Hive
//
//  Created by Animesh. on 04/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit

class TableViewCellWithButton: UITableViewCell
{
    @IBOutlet weak var button: UIButton!

    func changeButtonTitleTo(newTitle newTitle: String)
    {
        self.button.setTitle(newTitle, forState: .Normal)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
