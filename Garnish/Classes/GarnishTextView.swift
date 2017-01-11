//
//  GarnishTextView.swift
//  Food52
//
//  Created by Michael Simons on 11/23/16.
//  Copyright © 2016 Food52. All rights reserved.
//
import Foundation


extension CATextLayer {
    fileprivate convenience init(frame: CGRect, string: Any?) {
        self.init()
        contentsScale = UIScreen.main.scale
        self.frame = frame
        self.string = string
        
    }
}

extension CGPoint {
    fileprivate func translation() -> CGAffineTransform {
        return CGAffineTransform(translationX: x, y: y)
    }
}


extension CALayer {
    fileprivate static func animateWith(duration: CFTimeInterval, animations: ()->(), completion: (() -> Void)? = nil) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setCompletionBlock(completion)
        
        animations()
        
        CATransaction.commit()
    }
    
    fileprivate static func withoutAnimation(_ action: ()->()) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        action()
        
        CATransaction.commit()
    }
    
    func debug(_ color: UIColor = .red) {
        borderColor = color.cgColor
        borderWidth = 1.0
    }
}


extension CATextLayer {
    
    fileprivate func fadeIn() {
        
        CALayer.withoutAnimation {
            self.opacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            
            CALayer.animateWith(duration: 0.1, animations: {
                
                self.opacity = 1.0
                
            }, completion: {
                
            })
        }
    }
    
}


public class GarnishTextView: UITextView {
    
    public var garnishTextStorage: GarnishTextStorage {
        //swiftlint:disable force_cast
        return textStorage as! GarnishTextStorage
        //swiftlint:enable force_cast
    }
    
    fileprivate var layers = [Int: CATextLayer]()
}


extension GarnishTextView: NSLayoutManagerDelegate /*instantiation*/ {
    
    func bounce(layers: [(Int,CATextLayer)]) {
        guard !layers.isEmpty else { return }
        
        let firstIndex = layers.min(by: { $0.0 < $1.0 })?.0 ?? 0
        
        for (index, layer) in layers {
            
            layer.zPosition = 1.0
            layer.opacity = 1.0
            
            let colorLayer = CALayer()
            colorLayer.backgroundColor = textColor?.cgColor ?? UIColor.black.cgColor
            colorLayer.bounds.size = layer.bounds.size
            colorLayer.anchorPoint = layer.anchorPoint
            colorLayer.position = layer.convert(layer.position, from: layer.superlayer)
            layer.addSublayer(colorLayer)
            
            
            let letterMask = CATextLayer()
            letterMask.contentsScale = UIScreen.main.scale
            letterMask.string = layer.string
            letterMask.anchorPoint = colorLayer.anchorPoint
            letterMask.position = colorLayer.position
            letterMask.bounds.size = colorLayer.bounds.size
            
            colorLayer.mask = letterMask
            
            
            let growAmount = 1.2
            let growDuration = 0.15
            
            let totalAnimationTime: CFTimeInterval = 0.05 * CFTimeInterval(layers.count)
            let timeBetweenAnimations = totalAnimationTime / CFTimeInterval(layers.count)
            let offsetIndex = index - firstIndex
            let orderOffset = timeBetweenAnimations * Double(offsetIndex)
            
            let springBeginTime = CACurrentMediaTime() + growDuration + orderOffset
            
            let growBeginTime = CACurrentMediaTime() + orderOffset
            
            
            let grow = CABasicAnimation()
            grow.keyPath = "transform.scale"
            grow.toValue = growAmount
            grow.duration = growDuration
            grow.beginTime = growBeginTime
            layer.add(grow, forKey: "grow")
            
            
            let spring = CASpringAnimation()
            spring.keyPath = "transform.scale"
            spring.fromValue = growAmount
            spring.toValue = 1.0
            spring.initialVelocity = 10
            spring.stiffness = 500
            spring.duration = 3.0
            spring.beginTime = springBeginTime
            
            layer.add(spring, forKey: "spring")
            
            let colorSpring = CASpringAnimation()
            colorSpring.keyPath = "backgroundColor"
            colorSpring.fromValue = textColor?.cgColor ?? UIColor.black.cgColor
            colorSpring.toValue = layer.foregroundColor
            colorSpring.initialVelocity = 10
            colorSpring.stiffness = 500
            colorSpring.duration = 3.0
            colorSpring.beginTime = growBeginTime
            colorLayer.add(colorSpring, forKey: "colorSpring")
            
            NSLog("\(textColor), \(layer.foregroundColor)")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
                colorLayer.removeFromSuperlayer()
            }
        }
        
    }
    
    func update(layer: CATextLayer, for location: Int) {
        guard location < textStorage.length else { return }
        
        let singleCharacterRange = NSRange(location: location, length: 1)
        
        let glyphRange = layoutManager.glyphRange(forCharacterRange: singleCharacterRange, actualCharacterRange: nil)
        let glyphRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        let lineRect = layoutManager.lineFragmentRect(forGlyphAt: location, effectiveRange: nil)
        
        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        
        let glyphLocation = layoutManager.location(forGlyphAt: characterRange.location)
        
        
        let text = NSMutableAttributedString(attributedString: textStorage.attributedSubstring(from: characterRange))

        if let highlightColor =  garnishTextStorage.highlightColor(at: location) {
             text.addAttribute(NSForegroundColorAttributeName, value: highlightColor, range: NSRange(location: 0, length: text.length))
        }
        
        if let font =  garnishTextStorage.highlightFont(at: location) {
            text.addAttribute(NSFontAttributeName, value: font, range: NSRange(location: 0, length: text.length))
        }
        
        let textBoundingRect =  text.boundingRect(with: glyphRect.size, options: [.usesFontLeading], context: nil)
        
        let locationInContainerCoordinates = glyphLocation.applying(lineRect.origin.translation())
        let locationOfBoundingBox = locationInContainerCoordinates.applying(textBoundingRect.origin.translation().inverted())
        
        let layerLocationInTextContainer  = locationOfBoundingBox.applying(CGAffineTransform(translationX: 0, y: -textBoundingRect.size.height))
        
        let layerLocationInTextView = layerLocationInTextContainer.applying(CGAffineTransform(translationX: textContainerInset.left, y: textContainerInset.top))
        
        let layerRect = CGRect(origin: layerLocationInTextView, size: textBoundingRect.size)
        
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        layer.foregroundColor = garnishTextStorage.highlightColor(at: location)?.cgColor ?? textColor?.cgColor ?? UIColor.black.cgColor
        layer.string = text
        layer.frame = layerRect
        
        CATransaction.commit()
        
    }
    
    public func layout() {
        for (_, layer) in layers {
            layer.removeFromSuperlayer()
        }
        
        layers = [:]
        
        for index in garnishTextStorage.indexesNeedingLayers(in: NSRange(location: 0, length: garnishTextStorage.length)) {
            let layer = newLayer(at: index)
            update(layer: layer, for: index)
        }
    }
    
    private func newLayer(at index: Int) -> CATextLayer {
        let newLayer =  CATextLayer()
        newLayer.contentsScale = UIScreen.main.scale
        newLayer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        self.layer.addSublayer(newLayer)
        layers[index] = newLayer
        
        return newLayer
    }
    
    
    
    private func adjustLayers() {
        var newLayers = [Int:CATextLayer]()
        
        for (location, layer) in layers {
            let newLocation = garnishTextStorage.adjust(location)
            
            newLayers[newLocation] = layer
        }
        
        layers = newLayers
    }
    
    
    private func deleteLayers() {
        let backspacing:Bool  = garnishTextStorage.changeInLength < 0
        
        guard backspacing else { return }
        
        let deletedRange =  garnishTextStorage.editedRange.location..<(garnishTextStorage.editedRange.location + abs(garnishTextStorage.changeInLength))
        
        for index in deletedRange {
            
            guard let layer = layers[index] else {continue}
            
            layer.removeFromSuperlayer()
            layers[index] = nil
        }
        
    }
    
    
    private func removeLayers() {
        
        for (_, index) in garnishTextStorage.removedRanges.enumerated() {
            
            guard let layer = layers[index] else {
                continue
            }
            
            CALayer.animateWith(duration: 1.0, animations: {
                layer.opacity = 0.0
            }, completion: {
                layer.removeFromSuperlayer()
                
                if let foundIndex = self.layers.filter({ $0.value == layer}).first {
                    self.layers[foundIndex.key] = nil
                }
                
            })
        }
    }
    
    
    private func addNewLayers() {
        for (_, index) in garnishTextStorage.addedRanges.enumerated() {
            let newLayer = self.newLayer(at: index)
            newLayer.fadeIn()
        }
    }
    
    
    private func updateLayers() {
        
        for (location, layer) in layers {
            update(layer: layer, for: location)
        }
    }
    
    private func highlightNewLayers() {
        
        let indexes = NSIndexSet(indexSet: garnishTextStorage.addedRanges)
        
        indexes.enumerateRanges({ (addedRange, _) in
            
            for range in garnishTextStorage.animatableRanges(in: addedRange) {
                let layersToAnimate:[(Int,CATextLayer)] = layers.filter({ (key, _) -> Bool in
                    return NSLocationInRange(key, range)
                }).map { ($0.0, $0.1) }
                
                bounce(layers: layersToAnimate)
            }
            
        })
    }
    
    public func layoutManager(_ layoutManager: NSLayoutManager, didCompleteLayoutFor textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) {
        
        guard garnishTextStorage.editedMask.contains(.editedCharacters) else { return }
        
  
        deleteLayers()
        adjustLayers()
        removeLayers()
        addNewLayers()
        updateLayers()
        highlightNewLayers()
        
    }
    
    
    public override func awakeAfter(using aDecoder: NSCoder) -> Any? {
        
        let layoutManager = NSLayoutManager()
        
        let textStorage =  GarnishTextStorage()
        
//        textStorage.font = font ??
        textStorage.textColor = textColor ?? .black
        
        textStorage.addLayoutManager(layoutManager)
        
        let container = NSTextContainer(size: textContainer.size)
        
        layoutManager.addTextContainer(container)
        
        container.lineBreakMode = .byWordWrapping
        container.maximumNumberOfLines = 0
        container.widthTracksTextView = textContainer.widthTracksTextView
        container.heightTracksTextView = textContainer.heightTracksTextView
        
        let replacement = GarnishTextView(frame: frame, textContainer: container)
        
        let newConstraints = constraints.map { replacement.translateConstraint($0, originalItem: self) }
        
        removeConstraints(constraints)
        replacement.addConstraints(newConstraints)
        
        replacement.backgroundColor = self.backgroundColor
        
        replacement.font = self.font
        
        replacement.isSelectable = self.isSelectable
        replacement.isEditable = self.isEditable
        
        replacement.textAlignment = self.textAlignment
        replacement.textColor = self.textColor
        replacement.autocapitalizationType = self.autocapitalizationType
        replacement.autocorrectionType = self.autocorrectionType
        replacement.spellCheckingType = self.spellCheckingType
        replacement.translatesAutoresizingMaskIntoConstraints = translatesAutoresizingMaskIntoConstraints
        replacement.returnKeyType = returnKeyType
        replacement.keyboardAppearance = keyboardAppearance
        replacement.enablesReturnKeyAutomatically = enablesReturnKeyAutomatically
        
        replacement.isScrollEnabled = isScrollEnabled
        replacement.bounces = bounces
        replacement.bouncesZoom = bouncesZoom
        replacement.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
        replacement.showsVerticalScrollIndicator = showsVerticalScrollIndicator
        replacement.alwaysBounceHorizontal = alwaysBounceHorizontal
        replacement.alwaysBounceVertical =  alwaysBounceVertical
        replacement.keyboardDismissMode = keyboardDismissMode
        
        layoutManager.delegate = replacement
        textStorage.delegate = replacement
        
        return replacement
    }
    
    func translateConstraint(_ constraint: NSLayoutConstraint, originalItem: AnyObject) -> NSLayoutConstraint {
        
        
        if constraint.firstItem === originalItem {
            return NSLayoutConstraint(item: self,
                                      attribute: constraint.firstAttribute,
                                      relatedBy: constraint.relation,
                                      toItem: constraint.secondItem,
                                      attribute: constraint.secondAttribute,
                                      multiplier: constraint.multiplier,
                                      constant: constraint.constant)
            
        } else if constraint.secondItem === originalItem {
            return NSLayoutConstraint(item: constraint.firstItem,
                                      attribute: constraint.firstAttribute,
                                      relatedBy: constraint.relation,
                                      toItem: self,
                                      attribute: constraint.secondAttribute,
                                      multiplier: constraint.multiplier,
                                      constant: constraint.constant)
        } else {
            return constraint
        }
        
    }
    
}

extension GarnishTextView: NSTextStorageDelegate {
    public func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {

        let wholeStringRange = NSRange(location: 0, length: garnishTextStorage.length)
        NSLog("\(textColor)")

        for (index, layer) in layers {
            if !NSLocationInRange(index, wholeStringRange) {
                layer.removeFromSuperlayer()
                layers[index] = nil
            }
        }
    }
}

