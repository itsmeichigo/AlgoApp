//
//  WebViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 2/17/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import WebKit
import SnapKit

class WebViewController: UIViewController {

    private var webView: WKWebView!
    private var userContentController: WKUserContentController!
    private var activityIndicator: UIActivityIndicatorView!
    
    var url: URL!
    var contentSelector: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userContentController = WKUserContentController()
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.contentInsetAdjustmentBehavior = .always
        webView.navigationDelegate = self
        
        view.addSubview(webView)
        webView.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
        }
        
        activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.centerY.equalToSuperview()
        }
        activityIndicator.startAnimating()
        
        loadPage(url: url, partialContentQuerySelector: contentSelector)
    }
    
    private func loadPage(url: URL, partialContentQuerySelector selector: String?) {
        if let selector = selector {
            userContentController.removeAllUserScripts()
            let userScript = WKUserScript(
                source: scriptWithDOMSelector(selector: selector),
                injectionTime: WKUserScriptInjectionTime.atDocumentEnd,
                forMainFrameOnly: true
            )
            
            userContentController.addUserScript(userScript)
        }
        
        webView.load(URLRequest(url: url))
    }
    
    private func scriptWithDOMSelector(selector: String) -> String {
        let script =
            "var selectedElement = document.querySelector('\(selector)');" +
        "document.body.innerHTML = selectedElement.innerHTML;"
        return script
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
}
