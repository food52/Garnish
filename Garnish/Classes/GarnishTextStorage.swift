//
//  GarnishTextStorage.swift
//  Food52
//
//  Created by Michael Simons on 11/18/16.
//  Copyright © 2016 Food52. All rights reserved.
//

import Foundation

public struct GarnishType: RawRepresentable {
    
    public typealias RawValue = String
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(_ value: String) {
        self.init(rawValue: value)
    }
}

public protocol GarnishDetector {
    var highlightColor: UIColor {get}
    var highlightFont: UIFont {get}
    var attachmentType: GarnishType {get}
    var animates: Bool {get}
    func detect(in string: NSString) -> [NSRange]
}


private let GarnishAttributeKey = "GarnishAttributeKey"

private class GarnishItem: NSObject, NSCoding {
    let type: GarnishType
    let animatable: Bool

    init(_ type: GarnishType, animatable: Bool) {
        self.type = type
        self.animatable = animatable
    }
    
    required init?(coder aDecoder: NSCoder) {
          guard let typeString = aDecoder.decodeObject(forKey: "type") as? String else { return nil }

        self.animatable =  aDecoder.decodeBool(forKey: "animatable")
        self.type = GarnishType(rawValue: typeString)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(animatable, forKey: "animatable")
        aCoder.encode(type.rawValue, forKey: "type")
    }
}


final public class GarnishTextStorage : NSTextStorage {
    
    override public var string: String { return store.string }
    
    fileprivate let store: NSMutableAttributedString = NSMutableAttributedString()
    
    private let defaultAttributes: [String:Any]
    public var detectors = [GarnishDetector]()
    
    public private(set) var addedRanges = IndexSet()
    public private(set) var removedRanges = IndexSet()
    private var _preditRanges = IndexSet()

    public init(defaultAttributes: [String:Any]) {
        
        self.defaultAttributes = defaultAttributes
        
        super.init()

    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func indexesNeedingLayers(in range: NSRange) -> IndexSet {
        let foundRanges = NSMutableIndexSet()
        
        store.enumerateAttribute(GarnishAttributeKey, in: range, options: []) { (value, foundRange, _) in
            guard let _ = value as? GarnishItem else { return }

            foundRanges.add(in: foundRange)
        }
        
        return IndexSet(foundRanges)
    }
    
    
    internal func adjust(_ location: Int) -> Int {
        if location >= editedRange.location {
            return max(location + changeInLength, 0)
        } else {
            return location
        }
    }
    
    public func refresh() {
        detectIn(store.string as NSString, range: NSRange(location: 0, length: store.length))
    }
    
    @discardableResult
    private func detectIn(_ string: NSString, range: NSRange) -> IndexSet {
        store.addAttributes(defaultAttributes, range: range)
        store.removeAttribute(GarnishAttributeKey, range: range)
        
        var previouslyDetectedIndexes = IndexSet()
        
        for detector in detectors {
            let detectedRanges = detector.detect(in: string as NSString).map { $0.convertedToRangeSpace(range) }
            
            for range in detectedRanges {
                
                guard let indexRange = range.toRange() else { continue }
                
                let canDetectEntityInRange = !previouslyDetectedIndexes.intersects(integersIn: indexRange)
                
                if canDetectEntityInRange {
                    
                    store.addAttribute(GarnishAttributeKey, value: GarnishItem(detector.attachmentType, animatable: detector.animates), range: range)

                    let highlightAttributes: [String:Any] = [
                        NSForegroundColorAttributeName: detector.highlightColor,
                        NSFontAttributeName: detector.highlightFont
                    ]
                    
                    store.addAttributes(highlightAttributes, range: range)
                    
                    previouslyDetectedIndexes.insert(integersIn: indexRange)
                }
            }
        }
        
        store.fixAttributes(in: range)
        
        return previouslyDetectedIndexes
    }
    
    public func ranges(of type: GarnishType, in range: NSRange ) -> [NSRange] {
        var ranges = [NSRange]()
        
        store.enumerateAttribute(GarnishAttributeKey, in: range, options: []) { (value, range, _) in
            guard let item = value as? GarnishItem,
                item.type == type else {return}
            
            ranges.append(range)
        }
        
        return ranges
    }
    
    public func animatableRanges(in range: NSRange) -> [NSRange] {
        var ranges = [NSRange]()
        
        store.enumerateAttribute(GarnishAttributeKey, in: range, options: []) { (value, range, _) in
            guard let item = value as? GarnishItem,
                item.animatable else {return}
            
            ranges.append(range)
        }
        
        return ranges
    }

   
    override public func processEditing() {
        
        let fullString = (string as NSString)
        
        let paragraphRange = fullString.paragraphRange(for: editedRange)
        
        var indexesOfCheckedSentence = IndexSet()
        var newDetectedIndexes = IndexSet()
        
        fullString.enumerateSubstrings(in: paragraphRange, options: .bySentences) { (sentence, sentenceRange, _, _) in
            
            guard let sentence = sentence else {return}
            
            let editedRangeInSentence:Bool = {
                if self.editedRange.length == 0 {
                    return NSLocationInRange(self.editedRange.location, sentenceRange)
                } else {
                    return NSIntersectionRange(self.editedRange, sentenceRange).length > 0
                }
            }()
            
            
            let isBackspacingAtEnd = self.changeInLength < 0 && NSMaxRange(self.editedRange) == fullString.length
            let shouldCheckSentence = editedRangeInSentence || isBackspacingAtEnd
            
            if shouldCheckSentence {
                
                let detectedIndexes = self.detectIn(sentence as NSString, range: sentenceRange)
                
                indexesOfCheckedSentence.formUnion(IndexSet(integersIn: sentenceRange.countable() ))
                newDetectedIndexes.formUnion(detectedIndexes)
            }
        }
        
        var adjustedIndexes = IndexSet()
        
        for index in  _preditRanges.map(adjust) {
            adjustedIndexes.insert(index)
        }
        
        let oldIndexesWithLayers = adjustedIndexes.intersection(indexesOfCheckedSentence)
        
        addedRanges = newDetectedIndexes.subtracting(oldIndexesWithLayers)
        removedRanges = oldIndexesWithLayers.subtracting(newDetectedIndexes)
        
        super.processEditing()
        
        addedRanges = IndexSet()
        removedRanges = IndexSet()
    }
    
    override public func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [String : Any] {
        return store.attributes(at: location, effectiveRange: range)
    }
    
    override public func replaceCharacters(in range: NSRange, with string: String) {
        _preditRanges = indexesNeedingLayers(in: NSRange(location: 0, length: store.length ))

        beginEditing()
        store.replaceCharacters(in: range, with: string)
        
        let length = (string as NSString).length - range.length
        edited(.editedCharacters, range: range, changeInLength:length)
        
        endEditing()
        
    }
    
    override public func setAttributes(_ attrs: [String : Any]?, range: NSRange) {
        beginEditing()
        store.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }
    
}

extension NSRange {
    fileprivate func countable() -> CountableRange<Int> {
        return location..<NSMaxRange(self)
    }
}

