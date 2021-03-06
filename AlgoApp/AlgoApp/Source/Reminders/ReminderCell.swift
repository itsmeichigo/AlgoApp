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

class ReminderCell: UICollectionViewCell, NibReusable {

    @IBOutlet weak var enabledSwitch: UISwitch!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var ampmLabel: UILabel!
    @IBOutlet private weak var filterLabel: UILabel!
    @IBOutlet private weak var repeatLabel: UILabel!
    
    private(set) var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        cardView.layer.cornerRadius = 8.0
        cardView.dropCardShadow()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
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
        filterLabel.textColor = enabled ? .subtitleTextColor() : UIColor.subtitleTextColor().withAlphaComponent(0.5)
        repeatLabel.textColor = enabled ? .titleTextColor() : .subtitleTextColor()
        contentView.backgroundColor = .backgroundColor()
        enabledSwitch.onTintColor = .secondaryColor()
        cardView.backgroundColor = .primaryColor()
    }
}
