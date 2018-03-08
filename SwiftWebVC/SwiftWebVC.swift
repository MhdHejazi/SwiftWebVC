//
//  SwiftWebVC.swift
//
//  Created by Myles Ringle on 24/06/2015.
//  Transcribed from code used in SVWebViewController.
//  Copyright (c) 2015 Myles Ringle & Sam Vermette. All rights reserved.
//

import WebKit

public protocol SwiftWebVCDelegate: class {
    func didStartLoading()
    func didFinishLoading(success: Bool)
}

open class SwiftWebVC: UIViewController {
    
    public var overriddenTitle: String? {
        didSet {
            self.title = self.overriddenTitle
        }
    }
    public weak var navigationDelegate: WKNavigationDelegate?
    public var storedStatusColor: UIBarStyle?
    public var buttonColor: UIColor? = nil
    public var titleColor: UIColor? = nil
    public var closing: Bool = false
    public var closingCallback: (() -> Void)? = nil
    
    open lazy var backBarButtonItem: UIBarButtonItem =  {
        var tempBackBarButtonItem = UIBarButtonItem(image: SwiftWebVC.bundledImage(named: "SwiftWebVCBack"),
                                                    style: UIBarButtonItemStyle.plain,
                                                    target: self,
                                                    action: #selector(SwiftWebVC.goBackTapped(_:)))
        tempBackBarButtonItem.width = 18.0
        tempBackBarButtonItem.tintColor = self.buttonColor
        return tempBackBarButtonItem
    }()
    
    open lazy var forwardBarButtonItem: UIBarButtonItem =  {
        var tempForwardBarButtonItem = UIBarButtonItem(image: SwiftWebVC.bundledImage(named: "SwiftWebVCNext"),
                                                       style: UIBarButtonItemStyle.plain,
                                                       target: self,
                                                       action: #selector(SwiftWebVC.goForwardTapped(_:)))
        tempForwardBarButtonItem.width = 18.0
        tempForwardBarButtonItem.tintColor = self.buttonColor
        return tempForwardBarButtonItem
    }()
    
    open lazy var refreshBarButtonItem: UIBarButtonItem = {
        var tempRefreshBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.refresh,
                                                       target: self,
                                                       action: #selector(SwiftWebVC.reloadTapped(_:)))
        tempRefreshBarButtonItem.tintColor = self.buttonColor
        return tempRefreshBarButtonItem
    }()
    
    open lazy var stopBarButtonItem: UIBarButtonItem = {
        var tempStopBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.stop,
                                                    target: self,
                                                    action: #selector(SwiftWebVC.stopTapped(_:)))
        tempStopBarButtonItem.tintColor = self.buttonColor
        return tempStopBarButtonItem
    }()
    
    open lazy var actionBarButtonItem: UIBarButtonItem = {
        var tempActionBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action,
                                                      target: self,
                                                      action: #selector(SwiftWebVC.actionButtonTapped(_:)))
        tempActionBarButtonItem.tintColor = self.buttonColor
        return tempActionBarButtonItem
    }()
    
    open lazy var webViewConfiguration: WKWebViewConfiguration = {
        return WKWebViewConfiguration()
    }()
    
    open lazy var webView: WKWebView = {
        var tempWebView = WKWebView(frame: UIScreen.main.bounds, configuration: self.webViewConfiguration)
        tempWebView.uiDelegate = self
        tempWebView.navigationDelegate = self
        return tempWebView
    }()
    
    open var url: URL! {
        get {
            return self.request.url
        }
        set {
            if self.url != newValue {
                self.request = URLRequest(url: newValue)
            }
        }
    }
    
    var request: URLRequest! {
        didSet {
            self.loadRequest(self.request)
        }
    }
    
    public var buttonOptionSet: SwiftWebVCbuttonOptionSet

    ////////////////////////////////////////////////
    
    deinit {
        webView.stopLoading()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        webView.uiDelegate = nil
        webView.navigationDelegate = nil
    }
    
    public convenience init(urlString: String, buttonOptionSet: SwiftWebVCbuttonOptionSet = .all) {
        var urlString = urlString
        if !urlString.hasPrefix("https://") && !urlString.hasPrefix("http://") {
            urlString = "https://"+urlString
        }
        self.init(pageURL: URL(string: urlString)!, buttonOptionSet: buttonOptionSet)
    }
    
    public convenience init(pageURL: URL, buttonOptionSet: SwiftWebVCbuttonOptionSet = .all) {
        self.init(aRequest: URLRequest(url: pageURL), buttonOptionSet: buttonOptionSet)
    }
    
    public init(aRequest: URLRequest, buttonOptionSet: SwiftWebVCbuttonOptionSet = .all) {
        self.buttonOptionSet = buttonOptionSet
        super.init(nibName: nil, bundle: nil)
        self.request = aRequest
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadRequest(_ request: URLRequest) {
        webView.load(request)
    }
    
    ////////////////////////////////////////////////
    // View Lifecycle
    
    override open func loadView() {
        view = webView
        loadRequest(request)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.updateToolbarItems()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        assert(self.navigationController != nil, "SVWebViewController needs to be contained in a UINavigationController. If you are presenting SVWebViewController modally, use SVModalWebViewController instead.")
        super.viewWillAppear(true)
        
        let showToolbar = UIDevice.current.userInterfaceIdiom == .phone && !buttonOptionSet.isEmpty
        self.navigationController?.setToolbarHidden(!showToolbar, animated: false)
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        if let navigationController = self.navigationController, !navigationController.isToolbarHidden {
            navigationController.setToolbarHidden(true, animated: true)
        }
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    ////////////////////////////////////////////////
    // Toolbar
    
    func updateToolbarItems() {
        guard !buttonOptionSet.isEmpty else {
            return
        }
        
        backBarButtonItem.isEnabled = webView.canGoBack
        forwardBarButtonItem.isEnabled = webView.canGoForward
        
        let refreshStopBarButtonItem: UIBarButtonItem = webView.isLoading ? stopBarButtonItem : refreshBarButtonItem
        let fixedSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            let flexibleSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
            
            var items: [UIBarButtonItem] = []
            
            if self.buttonOptionSet.contains(.course) {
                items.append(backBarButtonItem)
                items.append(forwardBarButtonItem)
            }
            if self.buttonOptionSet.contains(.refresh) {
                items.append(refreshStopBarButtonItem)
            }
            if self.buttonOptionSet.contains(.action) {
                items.append(actionBarButtonItem)
            }
            
            items = items.map({ [$0, flexibleSpace]}).flatMap({ $0 })
            items = Array(items.dropLast())
            items.insert(fixedSpace, at: 0)
            items.append(fixedSpace)
            
            if !closing {
                if let navigationController = self.navigationController {
                    navigationController.toolbar.barTintColor = navigationController.navigationBar.barTintColor
                    navigationController.toolbar.tintColor = navigationController.navigationBar.tintColor
                    navigationController.toolbar.isTranslucent = navigationController.navigationBar.isTranslucent
                }
                self.toolbarItems = items
            }
        } else {
            fixedSpace.width = 35.0
            
            let addSpace: Bool = self.splitViewController == nil
            
            var items: [UIBarButtonItem] = addSpace ? [fixedSpace] : []
            
            if self.buttonOptionSet.contains(.refresh) {
                items.append(refreshStopBarButtonItem)
                if addSpace {
                    items.append(fixedSpace)
                }
            }
            if self.buttonOptionSet.contains(.course) {
                items.append(backBarButtonItem)
                if addSpace {
                    items.append(fixedSpace)
                }
                items.append(forwardBarButtonItem)
                if addSpace {
                    items.append(fixedSpace)
                }            }
            if self.buttonOptionSet.contains(.action) {
                items.append(actionBarButtonItem)
                if addSpace {
                    items.append(fixedSpace)
                }
            }
            self.navigationItem.setRightBarButtonItems(items.reversed(), animated: true)
        }
    }
    
    ////////////////////////////////////////////////
    // Target Actions
    
    @objc func goBackTapped(_ sender: UIBarButtonItem) {
        webView.goBack()
    }
    
    @objc func goForwardTapped(_ sender: UIBarButtonItem) {
        webView.goForward()
    }
    
    @objc func reloadTapped(_ sender: UIBarButtonItem) {
        webView.reload()
    }
    
    @objc func stopTapped(_ sender: UIBarButtonItem) {
        webView.stopLoading()
        updateToolbarItems()
    }
    
    @objc func actionButtonTapped(_ sender: AnyObject) {
        
        if let url: URL = ((webView.url != nil) ? webView.url : request.url) {
            let activities: NSArray = [SwiftWebVCActivitySafari(), SwiftWebVCActivityChrome()]
            
            if url.absoluteString.hasPrefix("file:///") {
                let dc: UIDocumentInteractionController = UIDocumentInteractionController(url: url)
                dc.presentOptionsMenu(from: view.bounds, in: view, animated: true)
            }
            else {
                let activityController: UIActivityViewController = UIActivityViewController(activityItems: [url], applicationActivities: activities as? [UIActivity])
                
                if floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1 && UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                    let ctrl: UIPopoverPresentationController = activityController.popoverPresentationController!
                    ctrl.sourceView = view
                    ctrl.barButtonItem = sender as? UIBarButtonItem
                }
                
                present(activityController, animated: true, completion: nil)
            }
        }
    }
    
    ////////////////////////////////////////////////
    
    @objc public func doneButtonTapped() {
        closing = true
        closingCallback?()
        if let storedStatusColor = self.storedStatusColor {
            UINavigationBar.appearance().barStyle = storedStatusColor
        }
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - Class Methods

    /// Helper function to get image within SwiftWebVCResources bundle
    ///
    /// - parameter named: The name of the image in the SwiftWebVCResources bundle
    public class func bundledImage(named: String) -> UIImage? {
        let image = UIImage(named: named)
        if image == nil {
            return UIImage(named: named, in: Bundle(for: SwiftWebVC.classForCoder()), compatibleWith: nil)
        } // Replace MyBasePodClass with yours
        return image
    }
    
}

extension SwiftWebVC: WKUIDelegate {
    
    // Add any desired WKUIDelegate methods here: https://developer.apple.com/reference/webkit/wkuidelegate
    
}

extension SwiftWebVC: WKNavigationDelegate {
    
    open func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.navigationDelegate?.webView?(webView, didStartProvisionalNavigation: navigation)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        updateToolbarItems()
    }
    
    open func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.navigationDelegate?.webView?(webView, didFinish: navigation)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        webView.evaluateJavaScript("document.title", completionHandler: {(response, error) in
            if let title = response as? String, self.overriddenTitle == nil {
                self.title = title
            }
            self.updateToolbarItems()
        })
        
    }
    
    open func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.navigationDelegate?.webView?(webView, didFail: navigation, withError: error)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        updateToolbarItems()
    }
    
    open func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard self.navigationDelegate?.webView?(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler) == nil else {
            self.updateToolbarItems()
            return
        }
        if let url = navigationAction.request.url, navigationAction.targetFrame == nil || url.host == "itunes.apple.com" || ["tel", "telprompt", "sms", "mailto"].contains(url.scheme ?? "") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
                decisionHandler(.cancel)
                return
            }
        }
        self.updateToolbarItems()
        decisionHandler(.allow)
    }
    
    open func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        self.updateToolbarItems()
        guard self.navigationDelegate?.webView?(webView, decidePolicyFor: navigationResponse, decisionHandler: decisionHandler) == nil else {
            return
        }
        decisionHandler(.allow)
    }
}


public struct SwiftWebVCbuttonOptionSet: OptionSet {
    public let rawValue: Int
    public init(rawValue:Int) {
        self.rawValue = rawValue
    }
    
    public static let course = SwiftWebVCbuttonOptionSet(rawValue: 1 << 0)
    public static let refresh = SwiftWebVCbuttonOptionSet(rawValue: 1 << 1)
    public static let action = SwiftWebVCbuttonOptionSet(rawValue: 1 << 2)
    
    public static let all: SwiftWebVCbuttonOptionSet = [.course, .refresh, .action]
}
