import UIKit
import XCTest
@testable import Garnish

extension GarnishType {
    static var test = GarnishType("test")
}

struct TestDetector: GarnishDetector {
    var animates: Bool {
        return true
    }
    
    var highlightFont: UIFont? {
        return UIFont.preferredFont(forTextStyle: .title1)
    }
    
    var highlightColor: UIColor {
        return #colorLiteral(red: 0.9995060563, green: 0.4978743792, blue: 0, alpha: 1)
    }
    
    var attachmentType: GarnishType {
        return .test
    }
    
    func detect(in string: NSString) -> [NSRange] {
        
        let regex = try! NSRegularExpression(pattern: "\\w*!", options: [])
        
        let matches = regex.matches(in: string as String, options: [], range: NSRange(location: 0, length: string.length)).map {$0.range}
        
        return matches
    }
}

class GarnishTextStorageTests: XCTestCase {
    
    var storage: GarnishTextStorage!
    
    override func setUp() {
        super.setUp()
        storage = GarnishTextStorage()
        storage.detectors = [TestDetector()]
    }
    
    override func tearDown() {
        super.tearDown()
        storage =  nil
    }
    
    
    func typeThisText(string: String) {
        for character in string.characters {
            let endOfString = NSRange(location: (storage.string as NSString).length, length:0)
            storage.replaceCharacters(in: endOfString, with: String(character))
        }
    }
    
    func backspace(by count: Int) {
        for _ in 0..<count {
            
            let string = storage.string as NSString
            let endOfString = NSRange(location: string.length - 1, length:1)
            storage.replaceCharacters(in: endOfString, with: "")
        }
    }
    
    func test_typing() {
        storage.replaceCharacters(in: NSRange(location: 0, length:0), with: "12345")
        
        typeThisText(string: " 67890")
        
        XCTAssertEqual("12345 67890", storage.string)
    }
    
    func test_backspace() {
        storage.replaceCharacters(in: NSRange(location: 0, length:0), with: "12345")
        
        backspace(by: 2)
        
        XCTAssertEqual("123", storage.string)
    }
    
    
    func test_undetect_after_backspace() {
        let initialText = "This framework is great!"
        
        typeThisText(string: initialText)
    
        let preDeleteRanges = storage.ranges(of: .test, in: initialText.wholeStringRange)
        
        XCTAssertEqual(preDeleteRanges.count, 1, "Should have returned 1 detected item")
        
        backspace(by: 1)
        
        let postDeleteRanges = storage.ranges(of: .test, in: storage.string.wholeStringRange)

        XCTAssertEqual(postDeleteRanges.count, 0, "Should have returned no detected items")
    }
    
    func test_delete_in_middle_keeps_correct_ingredient_location() {
        
        let initialText = "I made some cheese! and kale and cheese! and onion!"
        
        typeThisText(string: initialText)
        
        var expected = TestDetector().detect(in: (initialText as NSString)).flatMap { $0.toRange() }
        var actual = storage.ranges(of: .test, in: initialText.wholeStringRange).flatMap { $0.toRange() }
        
        XCTAssertEqual(expected, actual)
        
        let deletionText = "some cheese! and"
        let deletionRange = (initialText as NSString).range(of: deletionText)
        
        storage.replaceCharacters(in: deletionRange, with: "")
        
        
        expected = TestDetector().detect(in: (storage.string as NSString)).flatMap { $0.toRange() }
        actual = storage.ranges(of: .test, in: NSRange(location: 0, length: storage.length)).flatMap { $0.toRange() }
        
        XCTAssertEqual(expected, actual)
        
        
    }
    
    
    func test_happy_path() {
        
        let initialText = "I made some cheese potato with onion and kale and quinoa. delicious!"

        storage.replaceCharacters(in: NSRange(location: 0, length: 0), with: initialText)
        
        let expectedRanges = [(initialText as NSString).range(of: "delicious!")]
        
        let actualRanges = storage.ranges(of: .test, in: initialText.wholeStringRange)
        
        XCTAssertEqual(expectedRanges.flatMap { $0.toRange() }, actualRanges.flatMap { $0.toRange() })
        
        for range in actualRanges {
            guard let color = storage.attribute(NSForegroundColorAttributeName, at: range.location, longestEffectiveRange: nil, in: range) as? UIColor else {
                XCTFail("not a color")
                continue
            }
            
            XCTAssertEqual(color, UIColor.clear)
        }
        
    }
    
    
}


extension String {
    var wholeStringRange: NSRange {
        return  NSRange(location: 0, length: (self as NSString).length)
    }
}
