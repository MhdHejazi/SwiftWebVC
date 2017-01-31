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

public class SwiftWebVC: UIViewController {
    
    public weak var delegate: SwiftWebVCDelegate?
    var storedStatusColor: UIBarStyle?
    var buttonColor: UIColor? = nil
    var titleColor: UIColor? = nil
    var closing: Bool! = false
    
    lazy var backBarButtonItem: UIBarButtonItem =  {
        var tempBackBarButtonItem = UIBarButtonItem(image: SwiftWebVC.bundledImage(named: "SwiftWebVCBack"),
                                                    style: UIBarButtonItemStyle.plain,
                                                    target: self,
                                                    action: #selector(SwiftWebVC.goBackTapped(_:)))
        tempBackBarButtonItem.width = 18.0
        tempBackBarButtonItem.tintColor = self.buttonColor
        return tempBackBarButtonItem
    }()
    
    lazy var forwardBarButtonItem: UIBarButtonItem =  {
        var tempForwardBarButtonItem = UIBarButtonItem(image: SwiftWebVC.bundledImage(named: "SwiftWebVCNext"),
                                                       style: UIBarButtonItemStyle.plain,
                                                       target: self,
                                                       action: #selector(SwiftWebVC.goForwardTapped(_:)))
        tempForwardBarButtonItem.width = 18.0
        tempForwardBarButtonItem.tintColor = self.buttonColor
        return tempForwardBarButtonItem
    }()
    
    lazy var refreshBarButtonItem: UIBarButtonItem = {
        var tempRefreshBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.refresh,
                                                       target: self,
                                                       action: #selector(SwiftWebVC.reloadTapped(_:)))
        tempRefreshBarButtonItem.tintColor = self.buttonColor
        return tempRefreshBarButtonItem
    }()
    
    lazy var stopBarButtonItem: UIBarButtonItem = {
        var tempStopBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.stop,
                                                    target: self,
                                                    action: #selector(SwiftWebVC.stopTapped(_:)))
        tempStopBarButtonItem.tintColor = self.buttonColor
        return tempStopBarButtonItem
    }()
    
    lazy var actionBarButtonItem: UIBarButtonItem = {
        var tempActionBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action,
                                                      target: self,
                                                      action: #selector(SwiftWebVC.actionButtonTapped(_:)))
        tempActionBarButtonItem.tintColor = self.buttonColor
        return tempActionBarButtonItem
    }()
    
    
    lazy var webView: WKWebView = {
        var tempWebView = WKWebView(frame: UIScreen.main.bounds)
        tempWebView.uiDelegate = self
        tempWebView.navigationDelegate = self
        return tempWebView;
    }()
    
    var request: URLRequest!
    
    var navBarTitle: UILabel!
    
    var buttonOptionset: SwiftWebVCButtonOptionSet = .all
    
    ////////////////////////////////////////////////
    
    deinit {
        webView.stopLoading()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        webView.uiDelegate = nil;
        webView.navigationDelegate = nil;
    }
    
    public convenience init(urlString: String, buttonOptionset: SwiftWebVCButtonOptionSet = .all) {
        self.init(pageURL: URL(string: urlString)!, buttonOptionset: buttonOptionset)
    }
    
    public convenience init(pageURL: URL, buttonOptionset: SwiftWebVCButtonOptionSet = .all) {
        self.init(aRequest: URLRequest(url: pageURL), buttonOptionset: buttonOptionset)
    }
    
    public convenience init(aRequest: URLRequest, buttonOptionset: SwiftWebVCButtonOptionSet = .all) {
        self.init()
        self.request = aRequest
        self.buttonOptionset = buttonOptionset
    }
    
    func loadRequest(_ request: URLRequest) {
        webView.load(request)
    }
    
    ////////////////////////////////////////////////
    // View Lifecycle
    
    override public func loadView() {
        view = webView
        loadRequest(request)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        updateToolbarItems()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        assert(self.navigationController != nil, "SVWebViewController needs to be contained in a UINavigationController. If you are presenting SVWebViewController modally, use SVModalWebViewController instead.")
        
        navBarTitle = UILabel()
        navBarTitle.backgroundColor = UIColor.clear
        if presentingViewController == nil {
            if let titleAttributes = navigationController?.navigationBar.titleTextAttributes {
                navBarTitle.textColor = titleAttributes["NSColor"] as! UIColor
            }
        }
        else {
            navBarTitle.textColor = self.titleColor
        }
        navBarTitle.shadowOffset = CGSize(width: 0, height: 1);
        navBarTitle.font = UIFont(name: "HelveticaNeue-Medium", size: 17.0)
        
        navigationItem.titleView = navBarTitle;
        
        super.viewWillAppear(true)
        
        let showToolbar = UIDevice.current.userInterfaceIdiom == .phone && !buttonOptionset.isEmpty
        self.navigationController?.setToolbarHidden(!showToolbar, animated: false)
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        if let navigationController = self.navigationController, !navigationController.isToolbarHidden {
            navigationController.setToolbarHidden(true, animated: true)

        }
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    ////////////////////////////////////////////////
    // Toolbar
    
    func updateToolbarItems() {
        guard !buttonOptionset.isEmpty else {
            return
        }
        
        backBarButtonItem.isEnabled = webView.canGoBack
        forwardBarButtonItem.isEnabled = webView.canGoForward
        
        let refreshStopBarButtonItem: UIBarButtonItem = webView.isLoading ? stopBarButtonItem : refreshBarButtonItem
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            let flexibleSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
            
            var items: [UIBarButtonItem] = [flexibleSpace]
            
            if self.buttonOptionset.contains(.course) {
                items.append(backBarButtonItem)
                items.append(flexibleSpace)
                items.append(forwardBarButtonItem)
                items.append(flexibleSpace)
            }
            if self.buttonOptionset.contains(.refresh) {
                items.append(refreshStopBarButtonItem)
                items.append(flexibleSpace)
            }
            if self.buttonOptionset.contains(.action) {
                items.append(actionBarButtonItem)
                items.append(flexibleSpace)
            }
            
            if !closing {
                if let navigationController = self.navigationController {
                    if presentingViewController == nil {
                        navigationController.toolbar.barTintColor = navigationController.navigationBar.barTintColor
                    }
                    else {
                        navigationController.toolbar.barStyle = navigationController.navigationBar.barStyle
                    }
                    navigationController.toolbar.tintColor = navigationController.navigationBar.tintColor
                }
                toolbarItems = items
            }
        } else {
            let fixedSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
            fixedSpace.width = 35.0
            
            var items: [UIBarButtonItem] = [fixedSpace]
            
            if self.buttonOptionset.contains(.refresh) {
                items.append(refreshStopBarButtonItem)
                items.append(fixedSpace)
            }
            if self.buttonOptionset.contains(.course) {
                items.append(backBarButtonItem)
                items.append(fixedSpace)
                items.append(forwardBarButtonItem)
                items.append(fixedSpace)
            }
            if self.buttonOptionset.contains(.action) {
                items.append(actionBarButtonItem)
                items.append(fixedSpace)
            }

            navigationItem.setRightBarButtonItems(items.reversed(), animated: true)
        }
    }
    
    ////////////////////////////////////////////////
    // Target Actions
    
    func goBackTapped(_ sender: UIBarButtonItem) {
        webView.goBack()
    }
    
    func goForwardTapped(_ sender: UIBarButtonItem) {
        webView.goForward()
    }
    
    func reloadTapped(_ sender: UIBarButtonItem) {
        webView.reload()
    }
    
    func stopTapped(_ sender: UIBarButtonItem) {
        webView.stopLoading()
        updateToolbarItems()
    }
    
    func actionButtonTapped(_ sender: AnyObject) {
        
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
    
    func doneButtonTapped() {
        closing = true
        UINavigationBar.appearance().barStyle = storedStatusColor!
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - Class Methods

    /// Helper function to get image within SwiftWebVCResources bundle
    ///
    /// - parameter named: The name of the image in the SwiftWebVCResources bundle
    class func bundledImage(named: String) -> UIImage? {
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
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.delegate?.didStartLoading()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        updateToolbarItems()
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.delegate?.didFinishLoading(success: true)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        webView.evaluateJavaScript("document.title", completionHandler: {(response, error) in
            self.navBarTitle.text = response as! String?
            self.navBarTitle.sizeToFit()
            self.updateToolbarItems()
        })
        
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.delegate?.didFinishLoading(success: false)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        updateToolbarItems()
    }
}


public struct SwiftWebVCButtonOptionSet: OptionSet {
    public let rawValue: Int
    public init(rawValue:Int) {
        self.rawValue = rawValue
    }
    
    public static let course      = SwiftWebVCButtonOptionSet(rawValue: 1 << 0)
    public static let refresh         = SwiftWebVCButtonOptionSet(rawValue: 1 << 1)
    public static let action      = SwiftWebVCButtonOptionSet(rawValue: 1 << 2)
    
    public static let all: SwiftWebVCButtonOptionSet = [.course, .refresh, .action]
}
