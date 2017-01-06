![Garnish](https://raw.githubusercontent.com/food52/Garnish/master/images/garnish-small.png)
---
[![Version](https://img.shields.io/cocoapods/v/Garnish.svg?style=flat)](http://cocoapods.org/pods/Garnish)
[![License](https://img.shields.io/cocoapods/l/Garnish.svg?style=flat)](http://cocoapods.org/pods/Garnish)
[![Platform](https://img.shields.io/cocoapods/p/Garnish.svg?style=flat)](http://cocoapods.org/pods/Garnish)

## What is Garnish?

Garnish is a UITextView subclass that replicates the text effects of emoji detection in Messages.  This `GarnishTextView` is extensible with custom detectors that define detection behavior and highlight colors/fonts.

![Garnish Example](https://raw.githubusercontent.com/food52/Garnish/master/images/awesome.gif)

## Installation

Garnish is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Garnish"
```

## Example

To run the example project, clone the repo, and open the workspace in the Example directory.

This example detector finds "important" words (words ending with a `!`) in a body of text.

```swift
struct Detector: GarnishDetector {
    var animates: Bool {
        return true
    }

    var highlightFont: UIFont? {
        return UIFont.preferredFont(forTextStyle: .title)
    }

    var highlightColor: UIColor {
        return #colorLiteral(red: 0.9995060563, green: 0.4978743792, blue: 0, alpha: 1)
    }

    var attachmentType: GarnishType {
        return GarnishType("important")
    }

    func detect(in string: NSString) -> [NSRange] {
        let regex = try! NSRegularExpression(pattern: "\\w*!", options: [])

        let matches = regex.matches(in: string as String, options: [], range: NSRange(location: 0, length: string.length)).map {$0.range}

        return matches
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var textView: GarnishTextView!
    override func viewDidLoad() {
        textView.garnishTextStorage.detectors = [Detector()]
    }
}
```

`GarnishType` is a simple wrapper to differentiate different types of detected strings.  This allows for different colors or effects to be applied.  For example, one could create a hashtag detector and an emoji detector in the same text view.  Each detector could provide different colors for each type.


## Author

Mike Simons, mike.simons@food52.com

## License

Garnish is available under the MIT license. See the LICENSE file for more info.
