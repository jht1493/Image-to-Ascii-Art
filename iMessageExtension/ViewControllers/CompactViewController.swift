//
//  CompactViewController.swift
//  iMessageExtension
//
//  Created by Liam Rosenfeld on 11/22/17.
//  Copyright © 2017 Liam Rosenfeld. All rights reserved.
//

import UIKit

protocol CompactDelegate {
    func selectImage(via: String)
}

class CompactViewController: UIViewController {

    // MARK: - Setup
    var delegate:CompactDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    
    // MARK: - Actions
    @IBAction func pickImage(_ sender: Any) {
        delegate?.selectImage(via: "pick")
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        delegate?.selectImage(via: "take")
    }
}
