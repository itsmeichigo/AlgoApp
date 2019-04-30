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
import RxSwift

class WebViewController: UIViewController {

    private var webView: WKWebView!
    private var userContentController: WKUserContentController!
    private var activityIndicator: UIActivityIndicatorView!
    
    var url: URL!
    var contentSelector: String?
    
    private let disposeBag = DisposeBag()
    
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
        
        let dismissButton = UIBarButtonItem(image: UIImage(named: "cancel-button"), style: .plain, target: self, action: #selector(dismissView))
        dismissButton.tintColor = .subtitleTextColor()
        navigationItem.leftBarButtonItem = dismissButton
        
        loadPage(url: url, partialContentQuerySelector: contentSelector)
        
        Themer.shared.currentThemeDriver
            .drive(onNext: { [weak self] theme in
                self?.updateColors()
            })
            .disposed(by: disposeBag)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Themer.shared.currentTheme == .light ? .default : .lightContent
    }
    
    private func updateColors() {
        navigationController?.navigationBar.tintColor = .titleTextColor()
        navigationController?.navigationBar.barTintColor = Themer.shared.currentTheme == .light ? .backgroundColor() : .primaryColor()
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.titleTextColor()]
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
    
    @objc private func dismissView() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
}
