//
//  Utility.swift
//  Hive
//
//  Created by Animesh. on 14/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Design

class Design
{
	static let shared = Design()
	private init()
	{
		self.DateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
		self.DateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
	}
	
	func initMessage()
	{
		print("Design stack successfully initialized.")
	}
	
	// MARK: - Navigation Bar
	
	let NavigationBarTitleStyle = [
		NSFontAttributeName: UIFont(name: "AvenirNext-Medium", size: 18.0)!,
		NSForegroundColorAttributeName: UIColor(red: 245.0/255.0, green: 245.0/255.0, blue: 245.0/255.0, alpha: 1.0)
	]

	let NavigationBarButtonStyle = [
		NSFontAttributeName : UIFont(name: "Avenir Next", size: 17.0)!,
		NSForegroundColorAttributeName: UIColor(red: 245.0/255.0, green: 245.0/255.0, blue: 245.0/255.0, alpha: 1.0)
	]
	
	// MARK: - Date & Time
	
	let DateFormatter = NSDateFormatter()
	
	func stringFromDate(date: NSDate?) -> String
	{
		guard let givenDate = date else
		{
			return "never"
		}
		return DateFormatter.stringFromDate(givenDate)
	}
}

// MARK: - Custom Table View Cells

class CustomTableViewCell: UITableViewCell
{
	@IBOutlet private weak var cellImage: UIImageView!
	@IBOutlet private weak var titleLabel: UILabel!
	@IBOutlet private weak var subtitleLabel: UILabel!
	@IBOutlet private weak var button: UIButton!
	
	var icon: UIImage {
		get {
			return cellImage.image ?? UIImage(named: "icon-contact")!
		}
		set {
			cellImage.image = newValue
		}
	}
	
	var title: String {
		get {
			return titleLabel.text ?? ""
		}
		set {
			titleLabel.text = newValue
		}
	}
	
	var subtitle: String {
		get {
			return subtitleLabel.text ?? ""
		}
		set {
			subtitleLabel.text = newValue
		}
	}
	
	var buttonTitle: String {
		get {
			return button.currentTitle ?? ""
		}
		set {
			button.setTitle(newValue, forState: .Normal)
		}
	}
}

class TableViewCellWithTextfield: UITableViewCell
{
	@IBOutlet private weak var titleLabel: UILabel!
	@IBOutlet private weak var textField: UITextField!
	
	var title: String {
		get {
			return titleLabel.text ?? ""
		}
		set {
			titleLabel.text = newValue
		}
	}
	
	var userResponse: String {
		get {
			return textField.text ?? ""
		}
		set {
			textField.placeholder = newValue
		}
	}
	
	var textFieldDelegate: UITextFieldDelegate {
		get {
			return textField.delegate!
		}
		set {
			textField.delegate = newValue
		}
	}
}

class TableViewCellWithTextView: UITableViewCell
{
	@IBOutlet private weak var textView: UITextView!
	
	var styledText: NSAttributedString {
		get {
			return textView.attributedText
		}
		set {
			textView.attributedText = newValue
		}
	}
	
	var plainText: String {
		get {
			return textView.text
		}
		set {
			textView.text = newValue
		}
	}
}

class TableViewCellWithSelection: UITableViewCell
{
	@IBOutlet private weak var titleLabel: UILabel!
	@IBOutlet private weak var selection: UILabel!
	
	var title: String {
		get {
			return titleLabel.text ?? ""
		}
		set {
			titleLabel.text = newValue
		}
	}
	
	var selectedOption: String {
		get {
			return selection.text ?? ""
		}
		set {
			selection.text = newValue
		}
	}
}

class TableViewCellWithButton: UITableViewCell
{
	@IBOutlet private weak var button: UIButton!
	
	var title: String {
		get {
			return button.currentTitle ?? ""
		}
		set {
			button.setTitle(newValue, forState: .Normal)
		}
	}
	
	var buttonTitle: String {
		get {
			return button.currentTitle ?? ""
		}
		set {
			button.setTitle(newValue, forState: .Normal)
		}
	}
	
	var buttonHidden: Bool {
		get {
			return button.hidden
		}
		set {
			button.hidden = newValue
		}
	}
	
	var buttonFaded: Bool {
		get {
			return button.alpha == 0.3 ? true : false
		}
		set {
			if newValue {
				button.alpha = 0.3
			}
			else {
				button.alpha = 1.0
			}
		}
	}
	
	var buttonTouchEnabled: Bool {
		get {
			return button.userInteractionEnabled
		}
		set {
			button.userInteractionEnabled = newValue
		}
	}
}

class TableViewCellWithSwitch: UITableViewCell
{
	@IBOutlet private weak var toggle: UISwitch!
	@IBOutlet private weak var titleLabel: UILabel!
	
	var title: String {
		get {
			return titleLabel.text ?? ""
		}
		set {
			titleLabel.text = newValue
		}
	}
}





