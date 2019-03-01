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
    case c = "C"
    case cSharp = "C#"
    case cPP = "C++"
    case go = "Go"
    case java = "Java"
    case javascript = "Javascript"
    case markdown = "Markdown"
    case objc = "Objective-C"
    case php = "PHP"
    case python = "Python"
    case ruby = "Ruby"
    case swift = "Swift"
}

final class CodeViewModel {
    var attributedContent: NSAttributedString? {
        return highlighter?.highlight(content, as: language.rawValue, fastRender: true)
    }
    
    var layoutManager: NSLayoutManager {
        let textStorage = CodeAttributedString(highlightr: highlighter!)
        textStorage.language = language.rawValue
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        return layoutManager
    }
    
    private(set) var readOnly: Bool
    
    private let content: String
    private let language: Language
    
    private let highlighter: Highlightr?
    
    init(content: String, language: Language, readOnly: Bool) {
        self.content = content
        self.language = language
        self.readOnly = readOnly
        
        highlighter = Highlightr()
        highlighter?.setTheme(to: "tomorrow")
    }
}
