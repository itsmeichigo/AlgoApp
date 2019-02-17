//
//  HomeTableViewCell.swift
//  AlgoApp
//
//  Created by Huong Do on 2/4/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import Reusable

final class HomeTableViewCell: UITableViewCell, Reusable {

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var emojiLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tagsLabel: UILabel!
    @IBOutlet weak var markLabel: UILabel!
    @IBOutlet weak var difficultyLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cardView.layer.cornerRadius = 8.0
        cardView.layer.shadowColor = UIColor(rgb: 0x333333).cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 3)
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowRadius = 3.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            setSelected(false, animated: true)
        }
    }

    func configureCell(with model: QuestionDetailModel) {
        emojiLabel.text = model.emoji
        titleLabel.text = model.title
        tagsLabel.text = model.tags.joined(separator: "・")
        markLabel.text = model.remark
        difficultyLabel.text = model.difficulty
    }
}
