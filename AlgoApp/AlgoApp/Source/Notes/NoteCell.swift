//
//  NoteCell.swift
//  AlgoApp
//
//  Created by Huong Do on 4/6/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Highlightr
import UIKit
import Reusable
import RxSwift
import RxCocoa
import RxDataSources

struct NoteCellModel: IdentifiableType, Equatable {
    typealias Identity = String
    
    let id: String
    let content: String
    let language: Language
    let lastUpdated: Date
    let questionId: Int
    let questionTitle: String
    
    init(with note: Note) {
        id = note.id
        content = note.content
        language = Language(rawValue: note.language) ?? .markdown
        lastUpdated = note.lastUpdated
        questionId = note.questionId
        questionTitle = note.questionTitle
    }
    
    var identity: String {
        return id
    }
}

class NoteCell: UICollectionViewCell, NibReusable {
    
    @IBOutlet weak var lastUpdatedLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var languageLabel: UILabel!
    
    private var highlighter: Highlightr?
    
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
    
    func configureCell(model: NoteCellModel) {
        updateColors()
        
        titleLabel.text = model.questionTitle
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd YYYY"
        lastUpdatedLabel.text = "Last Updated: " + dateFormatter.string(from: model.lastUpdated)
        
        contentTextView.attributedText = highlighter?.highlight(model.content, as: model.language.rawLanguageName, fastRender: true)
        contentTextView.scrollRangeToVisible(NSRange(location: 0, length: 1))
        
        languageLabel.text = "\(model.language.rawValue) Snippet"
    }
    
    private func updateColors() {
        let theme = Themer.shared.currentTheme == .light ? "tomorrow" : "tomorrow-dark"
        highlighter = Highlightr()
        highlighter?.setTheme(to: theme)
        
        languageLabel.textColor = .subtitleTextColor()
        lastUpdatedLabel.textColor = .subtitleTextColor()
        titleLabel.textColor = .titleTextColor()
        
        deleteButton.tintColor = .appRedColor()
        editButton.tintColor = .appYellowColor()
        
        contentView.backgroundColor = .backgroundColor()
        cardView.backgroundColor = .primaryColor()
        contentTextView.backgroundColor = .primaryColor()
    }
}
