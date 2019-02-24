//
//  CodeViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 2/24/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit

class CodeViewController: UIViewController {

    @IBOutlet weak var codeTextView: UITextView!
    
    var viewModel: CodeViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let attributedContent = viewModel.attributedContent {
            codeTextView.attributedText = attributedContent
        }
        
    }

}
