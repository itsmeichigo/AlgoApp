# StringExtensionHTML

[![CI Status](http://img.shields.io/travis/Adela/StringExtensionHTML.svg?style=flat)](https://travis-ci.org/Adela/StringExtensionHTML)
[![Version](https://img.shields.io/cocoapods/v/StringExtensionHTML.svg?style=flat)](http://cocoapods.org/pods/StringExtensionHTML)
[![License](https://img.shields.io/cocoapods/l/StringExtensionHTML.svg?style=flat)](http://cocoapods.org/pods/StringExtensionHTML)
[![Platform](https://img.shields.io/cocoapods/p/StringExtensionHTML.svg?style=flat)](http://cocoapods.org/pods/StringExtensionHTML)

## Usage

This string extension provides two main methods, stringByDecodingHTMLEntities and stringByStrippingHTMLTags.

```
import StringExtensionHTML

var text = "&quot;some html string with entities&nbsp;&quot;"
let decodedText = text.stringByDecodingHTMLEntities

var text = "<span><p>Some text full of <i>unwanted</i> html tags</p></span>
let decodedText = text.stringByStrippingHTMLTags
```

## Sample Project

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

StringExtensionHTML is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'StringExtensionHTML'
```

The latest pod works with Swift 4. For the Swift 3 version, add the following line:

```ruby
pod 'StringExtensionHTML', '~> 0.2'
```

For the Swift 2 version, add the following line:

```ruby
pod 'StringExtensionHTML', '~> 0.1'
```

Alternatively, copy StringExtensionHTML.swift and add that single file into your Swift project. If you use this method, you can omit the line "import StringExtensionHTML" at the top of your file.

## Credits

Original solution and former adaptations credit to Michael Waterfall and Martin from the Stack Overflow thread [How do I decode HTML entities in swift?](http://stackoverflow.com/questions/25607247/how-do-i-decode-html-entities-in-swift). I upgraded to work with Swift 2.0 and made it available through CocoaPods. 

<sub>Note: there is a Swift 2 version by Santiago in the original thread's comments. However, while that version will compile, it will not handle numeric character entities properly and also has some flaws which will cause it to crash anytime it comes to an entity it doesn't understand.</sub>

## Author

Adela Chang, a.bar.of.soap@gmail.com


## License

StringExtensionHTML is available under the MIT license. See the LICENSE file for more info.
