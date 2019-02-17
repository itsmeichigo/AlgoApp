//
//  WebViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 2/17/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    
    var url: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.load(URLRequest(url: url))
    }
}
