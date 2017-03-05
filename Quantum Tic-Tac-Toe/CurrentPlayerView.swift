//
//  swift
//  Quantum Tic-Tac-Toe
//
//  Created by Josef Willsher on 10/08/2015.
//  Copyright © 2015 Josef Willsher. All rights reserved.
//

import UIKit
import Model

class CurrentPlayerView: UIView {
    
    func setup() {
        layer.cornerRadius = frame.width/2
        backgroundColor = UIColor.myRed()
        let tv = UITextView(frame: CGRect(origin: CGPoint(x: 10, y: 5), size: CGSize(width: frame.size.width - 20, height: frame.size.height - 15)))
        tv.textAlignment = .center
        tv.backgroundColor = .clear
        tv.isUserInteractionEnabled = false
        tv.textColor = .white
        self.tv = tv
        addSubview(tv)
        spinner.frame = CGRect(origin: CGPoint.zero, size: frame.size)
        spinner.hidesWhenStopped = true
    }
    
    fileprivate let animationScale: CGFloat = 1.2
    fileprivate let initialScale: CGFloat = 0.6
    fileprivate let animationDuration: Double = 0.2
    fileprivate let initialAnimationDuration: Double = 0.1
    
    var tv: UITextView!
    var spinner = UIActivityIndicatorView()

    func displayAddQuantum(for player: QuantumPlayer) {
        
        UIView.animate(withDuration: animationDuration/2, animations: {
            self.tv.alpha = 0
            self.transform = CGAffineTransform(scaleX: self.animationScale, y: self.animationScale)
            
            }, completion: { _ in
                let attString = NSMutableAttributedString(string: (player.0 == .x ? "X" : "O") + "\(player.1)" )
                
                attString.addAttributes([
                    NSFontAttributeName as String: UIFont.systemFont(ofSize: (self.tv.frame.height)/1.7, weight: 4),
                    NSForegroundColorAttributeName: UIColor.white
                    ], range: NSRange(location: 0, length: "\(player.1)".characters.count+1))
                
                attString.addAttributes([
                    NSBaselineOffsetAttributeName as String: NSNumber(value: -6 as Float),
                    NSFontAttributeName as String: UIFont.systemFont(ofSize: self.tv.frame.height/3.4, weight: 2)
                    ], range: NSRange(location: 1, length: "\(player.1)".characters.count))
                
                self.tv.attributedText = attString
                self.tv.textAlignment = .center
                
                UIView.animate(withDuration: self.animationDuration/2, animations: {
                    self.tv.alpha = 1
                    self.transform = CGAffineTransform(scaleX: 1, y: 1)
                }) 
        })
        
        UIView.animate(withDuration: animationDuration, animations: {
            self.backgroundColor = player.0 == .x ? UIColor.black : UIColor.myRed()
        }) 
    }
    
    
    func displaySelectTile(for player: Player) {
        
        self.tv.font = UIFont.systemFont(ofSize: tv.frame.height/1.4, weight: 9)
        
        UIView.animate(withDuration: animationDuration/2, animations: {
            self.tv.alpha = 0
            }, completion: { _ in
                
                self.tv.text = player == .o ? "X" : "O"
                
                UIView.animate(withDuration: self.animationDuration/2, animations: {
                    self.tv.alpha = 1
                }) 
        })
        
        UIView.animate(withDuration: animationDuration, animations: {
            self.tv.textColor = player == .o ? UIColor.black : UIColor.myRed()
            self.backgroundColor = UIColor.white
        }) 
    }
    
    func displayAICalculating(for player: Player) {
        
        self.spinner.startAnimating()
        
        UIView.animate(withDuration: animationDuration/2, animations: {
            self.transform = CGAffineTransform(scaleX: self.animationScale, y: self.animationScale)
            
            }, completion: { _ in
                
                self.tv.text = ""
                self.addSubview(self.spinner)
                
                UIView.animate(withDuration: self.animationDuration/2, animations: {
                    self.transform = CGAffineTransform(scaleX: 1, y: 1)
                }) 
        })
        
        UIView.animate(withDuration: animationDuration, animations: {
            self.backgroundColor = player == .o ? UIColor.myRed() : UIColor.black
        }) 
        
    }
    
    func endAICalculating() {
        self.spinner.stopAnimating()
    }
    
    
}
