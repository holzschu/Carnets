//
//  ViewController.swift
//  Carnets
//
//  Created by Nicolas Holzschuch on 26/01/2019.
//  Copyright © 2019 AsheKube. All rights reserved.
//

import UIKit
import WebKit
import ios_system

public var serverAddress: URL!
var progressView: UIProgressView!

extension String {
    
    func toCString() -> UnsafePointer<Int8>? {
        let nsSelf: NSString = self as NSString
        return nsSelf.cString(using: String.Encoding.utf8.rawValue)
    }
    
    var utf8CString: UnsafeMutablePointer<Int8> {
        return UnsafeMutablePointer(mutating: (self as NSString).utf8String!)
    }
    
}

func convertCArguments(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> [String]? {
    
    var args = [String]()
    
    for i in 0..<Int(argc) {
        
        guard let argC = argv?[i] else {
            return nil
        }
        
        let arg = String(cString: argC)
        
        args.append(arg)
        
    }
    
    return args
}

@_cdecl("openURL")
public func openURL(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    let usage = """
                usage: openURL url

                loads the specified url in the WkWebView of the application
                """

    guard let args = convertCArguments(argc: argc, argv: argv) else {
        fputs(usage, thread_stderr)
        return 1
    }
    var url: URL? = nil
    
    if args.count == 2 {
        url = URL(string: args[1])
    }
    
    guard url != nil else {
        fputs(usage, thread_stderr)
        return 1
    }

    serverAddress = url
    return 0
}

class ViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {


    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // For debugging:
        // print("JavaScript is sending a message.body: \(message.body)") // (quit)
        // print("JavaScript is sending a message.name: \(message.name)") // (Carnets)
        let cmd:NSString = message.body as! NSString
        if (cmd == "quit") {
            UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
        }
    }
    

    var webView: WKWebView!
    
    override func loadView() {
        let contentController = WKUserContentController();
        contentController.add(self, name: "Carnets")
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.preferences.setValue(true, forKey: "shouldAllowUserInstalledFonts")

        webView = WKWebView(frame: .zero, configuration: config)

        webView.navigationDelegate = self
        webView.uiDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Wait until the Jupyter notebook has started
        while (serverAddress == nil) { }
        webView.load(URLRequest(url: serverAddress))
        webView.allowsBackForwardNavigationGestures = true
    }
    
}

extension ViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
