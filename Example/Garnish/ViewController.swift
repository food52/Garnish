//
//  ViewController.swift
//  Garnish
//
//  Created by Mike Simons on 01/06/2017.
//  Copyright (c) 2017 Mike Simons. All rights reserved.
//

import UIKit
import Garnish


extension GarnishType {
    static let important = GarnishType("important")
    static let question = GarnishType("question")
}


struct Detector: GarnishDetector {
    
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
        return .important
    }
    
    func detect(in string: NSString) -> [NSRange] {
        
        let regex = try! NSRegularExpression(pattern: "\\w*!", options: [])
        
        let matches = regex.matches(in: string as String, options: [], range: NSRange(location: 0, length: string.length)).map {$0.range}

        return matches
    }
}

struct QuestionDetector: GarnishDetector {
    
    var animates: Bool {
        return false
    }
    
    var highlightFont: UIFont? {
        return UIFont.preferredFont(forTextStyle: .title1)
    }
    
    var highlightColor: UIColor {
        return #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)
    }
    
    var attachmentType: GarnishType {
        return .question
    }
    
    func detect(in string: NSString) -> [NSRange] {
        
        let regex = try! NSRegularExpression(pattern: "\\w*\\?", options: [])
        
        let matches = regex.matches(in: string as String, options: [], range: NSRange(location: 0, length: string.length)).map {$0.range}
        
        return matches
    }
}



class ViewController: UIViewController {

    @IBOutlet weak var textView: GarnishTextView!
    
    override func loadView() {
        super.loadView()
        
//        let textView = GarnishTextView(frame: view.bounds.insetBy(dx: 8, dy: 50))
//        textView.font = UIFont.preferredFont(forTextStyle: .title1)
//        textView.textColor = .black
//        
//        view.addSubview(textView)
//        
//        self.textView = textView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        textView.garnishTextStorage.detectors = [Detector(), QuestionDetector()]
        
        textView.becomeFirstResponder()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

