//
//  ReminderCell.swift
//  AlgoApp
//
//  Created by Huong Do on 3/11/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import Reusable

class ReminderCell: UITableViewCell, NibReusable {

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var ampmLabel: UILabel!
    @IBOutlet weak var enabledSwitch: UISwitch!
    @IBOutlet weak var filterLabel: UILabel!
    @IBOutlet weak var repeatLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        timeLabel.textColor = .titleTextColor()
        ampmLabel.textColor = .titleTextColor()
        filterLabel.textColor = .subtitleTextColor()
        repeatLabel.textColor = .titleTextColor()
        contentView.backgroundColor = .backgroundColor()
        enabledSwitch.onTintColor = .secondaryYellowColor()
    }

    func configureCell(model: ReminderDetail) {
        timeLabel.text = model.formattedTime
        ampmLabel.text = model.ampm
        repeatLabel.text = model.repeatDaysString
        filterLabel.text = model.filterString
        enabledSwitch.isOn = model.enabled
    }
}
