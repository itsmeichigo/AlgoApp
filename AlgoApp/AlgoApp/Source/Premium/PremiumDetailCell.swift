//
//  PremiumDetailCell.swift
//  AlgoApp
//
//  Created by Huong Do on 3/24/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import Reusable

class PremiumDetailCell: UICollectionViewCell, NibReusable {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.textColor = .subtitleTextColor()
    }
    
    func configureCell(model: PremiumDetailType) {
        imageView.image = model.logoImage
        titleLabel.text = model.description
    }
}
