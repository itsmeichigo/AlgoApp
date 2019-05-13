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
    @IBOutlet weak var solvedLabel: UILabel!
    @IBOutlet weak var bookmarkedImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cardView.layer.cornerRadius = 8.0
        cardView.dropCardShadow()
        
        solvedLabel.layer.cornerRadius = 3.0
        
        selectionStyle = .none
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        cardView.backgroundColor = highlighted ? .selectedBackgroundColor() : .primaryColor()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        cardView.backgroundColor = selected ? .selectedBackgroundColor() : .primaryColor()
        
        if !AppHelper.isIpad, selected {
            setSelected(false, animated: true)
        }
    } 


    func configureCell(with model: QuestionCellModel) {
        updateColors()
        
        emojiLabel.text = model.emoji
        titleLabel.text = model.title
        tagsLabel.text = model.tags.joined(separator: "・")
        markLabel.text = model.remark
        difficultyLabel.text = model.difficulty
        solvedLabel.isHidden = !model.solved
        bookmarkedImageView.isHidden = !model.saved
    }
    
    func updateColors() {
        titleLabel.textColor = .titleTextColor()
        tagsLabel.textColor = .subtitleTextColor()
        markLabel.textColor = .subtitleTextColor()
        cardView.backgroundColor = isSelected ? .selectedBackgroundColor() : .primaryColor()
        contentView.backgroundColor = .backgroundColor()
        solvedLabel.backgroundColor = .secondaryColor()
        solvedLabel.textColor = .primaryColor()
        bookmarkedImageView.tintColor = .appBlueColor()
    }
}
