//
//  String+FormattedDescription.swift
//  AlgoApp
//
//  Created by Huong Do on 4/9/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit

extension String {
    var formattedDescription: NSAttributedString {
        let preferredTextStyle: UIFont.TextStyle = AppHelper.isIpad ? .body : .callout
        let boldFont = UIFont.systemFont(ofSize: 17, weight: .medium)
        let regularFont = UIFont.preferredFont(forTextStyle: preferredTextStyle)
        let fontMetrics = UIFontMetrics(forTextStyle: preferredTextStyle)
        
        let attributedString = NSMutableAttributedString(string: self, attributes: [
            .foregroundColor: UIColor.titleTextColor(),
            .font: regularFont
            ])
        
        guard let monospacefont = UIFont(name: "Courier", size: 15) else { return attributedString }
        
        var isExample = false
        self.enumerateSubstrings(in: self.startIndex..<self.endIndex, options: .byParagraphs, { (substring, range, _, _) in

            guard let substring = substring else { return }
            let endsWithPunctuations = [".", ":", ";", "?", ")", "\""].contains(String(substring.trimmingCharacters(in: .whitespaces).suffix(1)))
            let isCommentBlock = substring.contains("//")

            let nsrange = NSRange(range, in: self)
            if substring.starts(with: "Example") == true || isCommentBlock {
                isExample = true
            } else if substring.starts(with: "Clarification:") == true ||
                substring.starts(with: "Note:") == true ||
                substring.starts(with: "Follow up:") == true ||
                substring.starts(with: "Explanation") == true {
                isExample = false
            }
            
            if isExample || !endsWithPunctuations || isCommentBlock {
                attributedString.addAttribute(.font, value: fontMetrics.scaledFont(for: monospacefont), range: nsrange)
            } else if substring.isEmpty {
                attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 12), range: nsrange)
            } else {
                attributedString.addAttribute(.font, value: regularFont, range: nsrange)
            }
        })
        
        let range = NSRange(self.startIndex..., in: self)
        
        let codePatterns = [
            "\\b([b-z]|[A-Z]|[0-9]){1}\\b", // eg: x, y
            "\\b\\w{1,20}\\d\\b", // eg: num1, a2
            "(\\w){1,10}\\((.){0,20}\\)", // eg: sqrt(x)
            "\\[(.){1,30}\\]", // eg: [2]
            "\\{(.){1,30}\\}", // eg: {1, 2}
            "\\bnums\\b",
            "\\bval\\b",
            "\\blog\\b"
        ]
        codePatterns.forEach { code in
            if let regex = try? NSRegularExpression(pattern: code, options: []) {
                let matches = regex.matches(in: self, options: [], range: range)
                for match in matches {
                    attributedString.addAttribute(.font, value: fontMetrics.scaledFont(for: monospacefont), range: match.range)
                }
            }
        }
        
        let titles = ["Input:", "Output:", "Explanation:", "Clarification:", "Note:", "Notes:", "Follow up:", "For example:", "Example((\\s){0,1}\\d){0,1}:", "Examples:", "Example :"]
        titles.forEach { title in
            if let regex = try? NSRegularExpression(pattern: title, options: []) {
                let matches = regex.matches(in: self, options: [], range: range)
                for match in matches {
                    attributedString.addAttribute(.font, value: fontMetrics.scaledFont(for: boldFont), range: match.range)
                }
            }
        }
        
        return attributedString
    }
}
