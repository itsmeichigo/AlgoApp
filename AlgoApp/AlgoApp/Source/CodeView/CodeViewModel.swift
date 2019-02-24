//
//  CodeViewModel.swift
//  AlgoApp
//
//  Created by Huong Do on 2/24/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import Highlightr

enum Language: String {
    case swift
}

final class CodeViewModel {
    var attributedContent: NSAttributedString? {
        return highlighter?.highlight(content, as: language.rawValue, fastRender: true)
    }
    
    private let content: String
    private let language: Language
    
    private let highlighter: Highlightr?
    
    init(content: String, language: Language) {
        self.content = content
        self.language = language
        highlighter = Highlightr()
        highlighter?.setTheme(to: "tomorrow")
    }
}
