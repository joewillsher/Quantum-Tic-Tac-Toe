//
//  MenuViewController.swift
//  Quantum Tic-Tac-Toe
//
//  Created by Josef Willsher on 10/08/2015.
//  Copyright © 2015 Josef Willsher. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    

    @IBAction func multi(_ sender: AnyObject) {
        
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GameViewController") as! GameViewController
        vc.AIEnabled = false
        present(vc, animated: true, completion: nil)
        
    }
    
    @IBAction func single(_ sender: AnyObject) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GameViewController") as! GameViewController
        vc.AIEnabled = true
        present(vc, animated: true, completion: nil)
        
    }
    
    @IBAction func instruction(_ sender: AnyObject) {
    }
    
}
