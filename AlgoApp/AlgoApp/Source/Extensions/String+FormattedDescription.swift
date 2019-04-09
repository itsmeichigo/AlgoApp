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
        let boldFont = UIFont.systemFont(ofSize: 15, weight: .medium)
        let regularFont = UIFont.systemFont(ofSize: 15)
        
        let attributedString = NSMutableAttributedString(string: self, attributes: [
            .foregroundColor: UIColor.titleTextColor(),
            .font: regularFont
            ])
        
        guard let monospacefont = UIFont(name: "Courier", size: 15) else { return attributedString }
        
        var isExample = false
        self.enumerateSubstrings(in: self.startIndex..<self.endIndex, options: .byParagraphs, { (substring, range, _, _) in
            
            guard let substring = substring else { return }
            let punctuations = [".", ":", "?", ")", "\""]
            
            let nsrange = NSRange(range, in: self)
            if substring.starts(with: "Example") == true {
                attributedString.addAttribute(.font, value: boldFont, range: nsrange)
                isExample = true
            } else if substring.starts(with: "Clarification:") == true ||
                substring.starts(with: "Note:") == true ||
                substring.starts(with: "Follow up:") == true {
                isExample = false
            } else if substring.starts(with: "//") {
                attributedString.addAttribute(.font, value: monospacefont, range: nsrange)
                isExample = true
            } else if isExample {
                attributedString.addAttribute(.font, value: monospacefont, range: nsrange)
            } else if !punctuations.contains(String(substring.trimmingCharacters(in: .whitespaces).suffix(1))) {
                attributedString.addAttribute(.font, value: monospacefont, range: nsrange)
            } else if !isExample {
                attributedString.addAttribute(.font, value: regularFont, range: nsrange)
            }
        })
        
        self.enumerateSubstrings(in: self.startIndex..<self.endIndex, options: .byWords, { (substring, range, _, _) in
            let nsrange = NSRange(range, in: self)
            guard let substring = substring else { return }
            
            if substring == "Input" ||
                substring == "Output" ||
                substring == "Explanation" ||
                substring == "Clarification" {
                attributedString.addAttribute(.font, value: boldFont, range: nsrange)
            } else if substring.count == 1 && substring.lowercased() != "a" && !substring.isNumeric {
                attributedString.addAttribute(.font, value: monospacefont, range: nsrange)
            } else if substring.count > 1 && !substring.isNumeric && substring.first(where: { $0.isNumber }) != nil {
                attributedString.addAttribute(.font, value: monospacefont, range: nsrange)
            }
            
            // TODO: add regex to check for O(...), num1, functions like sqrt(int x), array
        })
        
        if let range = self.range(of: "Follow up") {
            attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 15, weight: .medium), range: NSRange(range, in: self))
        }
        
        for range in allRanges(of: "Note:") {
            attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 15, weight: .medium), range: NSRange(range, in: self))
        }
        
        return attributedString
    }
}

extension String {
    var isNumeric: Bool {
        return Int(self) != nil
    }
    
    func allRanges(of aString: String,
                   options: String.CompareOptions = [],
                   range: Range<String.Index>? = nil,
                   locale: Locale? = nil) -> [Range<String.Index>] {
        
        //the slice within which to search
        var slice = self
        if let range = range {
            slice = self.substring(with: range)
        }
        
        var previousEnd: String.Index? = slice.startIndex
        var ranges = [Range<String.Index>]()
        
        
        while let r = slice.range(of: aString, options: options,
                                  range: previousEnd! ..< slice.endIndex,
                                  locale: locale) {
                                    if previousEnd != self.endIndex { //don't increment past the end
                                        previousEnd = self.index(after: r.lowerBound)
                                    }
                                    ranges.append(r)
        }
        
        return ranges
    }
}
