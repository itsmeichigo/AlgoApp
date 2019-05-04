//
//  CodeViewModel.swift
//  AlgoApp
//
//  Created by Huong Do on 2/24/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import Highlightr
import RxCocoa
import RxSwift

final class CodeViewModel {
    
    var attributedContent: NSAttributedString? {
        return highlighter?.highlight(content, as: language.value.rawLanguageName, fastRender: true)
    }
    
    var languageList: [Language] {
        return Language.allCases
    }
    
    let layoutManager = BehaviorRelay<NSLayoutManager?>(value: nil)
    
    let language = BehaviorRelay<Language>(value: .markdown)
    let readOnly: Bool
    
    var content: String
    
    private let highlighter: Highlightr?
    private let disposeBag = DisposeBag()
    
    init(content: String, language: Language, readOnly: Bool) {
        self.content = content
        self.readOnly = readOnly
        
        self.language.accept(language)
        
        highlighter = Highlightr()
        
        let theme = Themer.shared.currentTheme == .light ? "tomorrow" : "tomorrow-dark"
        highlighter?.setTheme(to: theme)
        
        self.language
            .map { [weak self] in self?.setupLayoutManager(for: $0) }
            .bind(to: layoutManager)
            .disposed(by: disposeBag)        
    }
    
    private func setupLayoutManager(for language: Language) -> NSLayoutManager? {
        guard let highlighter = self.highlighter else { return nil }
        
        let textStorage = CodeAttributedString(highlightr: highlighter)
        textStorage.language = language.rawLanguageName
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        return layoutManager
    }
}
