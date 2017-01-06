//
//  ViewController.swift
//  Garnish
//
//  Created by Mike Simons on 01/06/2017.
//  Copyright (c) 2017 Mike Simons. All rights reserved.
//

import UIKit
import Garnish

struct Detector: GarnishDetector {
    
    var animates: Bool {
        return true
    }
  
    var highlightFont: UIFont {
        return UIFont.preferredFont(forTextStyle: .title1)
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
        super.viewDidLoad()

        textView.garnishTextStorage.detectors = [Detector()]
        
        textView.becomeFirstResponder()
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

