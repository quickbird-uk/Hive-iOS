//
//  TableViewCellWithTextView.swift
//  Hive
//
//  Created by Animesh. on 02/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit

class TableViewCellWithTextView: UITableViewCell
{
    @IBOutlet weak var textView: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
