//
//  ReminderCell.swift
//  AlgoApp
//
//  Created by Huong Do on 3/11/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import Reusable
import RxCocoa
import RxSwift

class ReminderCell: UITableViewCell, NibReusable {

    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var ampmLabel: UILabel!
    @IBOutlet weak var enabledSwitch: UISwitch!
    @IBOutlet private weak var filterLabel: UILabel!
    @IBOutlet private weak var repeatLabel: UILabel!
    @IBOutlet private weak var cardView: UIView!
    
    private(set) var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        cardView.layer.cornerRadius = 8.0
        cardView.layer.shadowColor = UIColor(rgb: 0x333333).cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 3)
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowRadius = 3.0
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            setSelected(false, animated: true)
        }
    }

    func configureCell(model: ReminderDetail) {
        timeLabel.text = model.formattedTime
        ampmLabel.text = model.ampm
        repeatLabel.text = model.repeatDaysString
        filterLabel.text = model.filterString
        enabledSwitch.isOn = model.enabled
        
        updateColors(enabled: enabledSwitch.isOn)
    }
    
    private func updateColors(enabled: Bool) {
        timeLabel.textColor = enabled ? .titleTextColor() : .subtitleTextColor()
        ampmLabel.textColor = enabled ? .titleTextColor() : .subtitleTextColor()
        filterLabel.textColor = .subtitleTextColor()
        repeatLabel.textColor = enabled ? .titleTextColor() : .subtitleTextColor()
        contentView.backgroundColor = .backgroundColor()
        enabledSwitch.onTintColor = .secondaryYellowColor()
        cardView.backgroundColor = .primaryColor()
    }
}
