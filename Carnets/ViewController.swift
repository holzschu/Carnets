//
//  ViewController.swift
//  Carnets
//
//  Created by Nicolas Holzschuch on 26/01/2019.
//  Copyright © 2019 AsheKube. All rights reserved.
//

import UIKit
import WebKit
import UserNotifications
import ios_system

public var serverAddress: URL!
var appWebView: WKWebView!

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

@_cdecl("openURL_internal")
public func openURL_internal(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    let usage = """
                usage: openurl url

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
    NSLog("%@", "Server address is set to ".appending(args[1]))
    
    serverAddress = url
    var lastPageVisited = UserDefaults.standard.string(forKey: "lastOpenUrl")
    guard (appWebView != nil) else { return 0 }
    if ((lastPageVisited == nil) || (lastPageVisited == "/tree")) {
        appWebView.load(URLRequest(url: url!)) // server page
        return 0
    }
    if (lastPageVisited!.hasPrefix("/")) { lastPageVisited = String(lastPageVisited!.dropFirst()) }
    let lastPageVisitedUrl = serverAddress.appendingPathComponent(lastPageVisited!)
    NSLog("%@", "Re-opening previous page \(lastPageVisitedUrl)")
    appWebView.load(URLRequest(url: lastPageVisitedUrl))
    // TODO: check that file exists (if local). Urls are like:
    // http://localhost:8888/notebooks/Typesetting.ipynb
    // http://localhost:8888/edit/File.txt
    // Then again, suppressed files should raise an alarm. 
    return 0
}

class ViewController: UIViewController, UITextFieldDelegate, WKNavigationDelegate, WKScriptMessageHandler {

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let cmd:String = message.body as! String
        if (cmd == "quit") {
            // Warn the main app that the user has pressed the "quit" button
            runningSessions.removeAll(keepingCapacity: true)
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: notificationQuitRequested)))
        } else if (cmd.hasPrefix("loadingSession:")) {
            runningSessions.updateValue(Date(), forKey: cmd)
            if (runningSessions.count >= 4) { // Maybe "> 4"?
                NSLog("More than 4 notebook running (including this one). Time to cleanup.")
                var oldestSessionTime = Date()
                var oldestSessionID: String!
                for (sessionID, date) in runningSessions {
                    if (date < oldestSessionTime) {
                        oldestSessionTime = date
                        oldestSessionID = sessionID
                    }
                }
                let range = oldestSessionID.startIndex..<oldestSessionID.firstIndex(of: "S")!
                let key = oldestSessionID.replacingCharacters(in: range, with: "loading")
                oldestSessionID.removeFirst("loadingSession:".count)
                if (oldestSessionID!.hasPrefix("/")) {
                    oldestSessionID = String(oldestSessionID!.dropFirst())
                }
                let urlDelete = serverAddress!.appendingPathComponent(oldestSessionID)
                var urlDeleteRequest = URLRequest(url: urlDelete)
                urlDeleteRequest.httpMethod = "DELETE"
                urlDeleteRequest.setValue("json", forHTTPHeaderField: "dataType")
                NSLog("Sending DELETE: \(urlDelete). Notebook last accessed at: \(oldestSessionTime)")
                let task = URLSession.shared.dataTask(with: urlDeleteRequest) { data, response, error in
                    if let error = error {
                        NSLog ("Error on DELETE: \(error)")
                        return
                    }
                    guard let response = response as? HTTPURLResponse,
                        (200...299).contains(response.statusCode) else {
                            NSLog ("Server error on DELETE")
                            return
                    }
                    self.runningSessions.removeValue(forKey: key)
                }
                task.resume()
            }
        } else if (cmd.hasPrefix("killingSession:")) {
            let range = cmd.startIndex..<cmd.firstIndex(of: "S")!
            let key = cmd.replacingCharacters(in: range, with: "loading")
            if (runningSessions.removeValue(forKey: key) == nil) {
                NSLog("Weird, removing notebook that was not started: \(cmd)")
            }
        } else {
            // JS console:
            NSLog("JavaScript message: \(message.body)")
        }
    }
        
    var webView: WKWebView!
    var shutdownTimer: Timer!
    var alertShutdownTimer: Timer!
    var urlShutdownRequest: URLRequest!
    var shutdownTaskIdentifier: UIBackgroundTaskIdentifier!
    var lastPageVisited: String!
    var runningSessions: [String: Date] = [:]
    
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
        appWebView = webView
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.willResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.didBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.allowsBackForwardNavigationGestures = true
        // in case Jupyter has started before the view is active (unlikely):
        guard (serverAddress != nil) else { return }
        var lastPageVisited = UserDefaults.standard.string(forKey: "lastOpenUrl")
        if ((lastPageVisited == nil) || (lastPageVisited == "/tree")) {
            webView.load(URLRequest(url: serverAddress!)) // server page
        }
        if (lastPageVisited!.hasPrefix("/")) { lastPageVisited = String(lastPageVisited!.dropFirst()) }
        let lastPageVisitedUrl = serverAddress.appendingPathComponent(lastPageVisited!)
        webView.load(URLRequest(url: lastPageVisitedUrl))
    }
    
    
    @objc func terminateServer() {
        let app = UIApplication.shared
        let timeLeft = app.backgroundTimeRemaining
        NSLog("Terminating server. Time left = %f ", timeLeft)
        // shutdown Jupyter server and notebooks (takes about 7s with notebooks open)
        webView.load(urlShutdownRequest)
        // also remove list of running sessions:
        runningSessions.removeAll(keepingCapacity: true)
        // cancel the alert:
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removeDeliveredNotifications(withIdentifiers: ["CarnetsShutdownAlert"])
        shutdownTimer = nil
        app.endBackgroundTask(shutdownTaskIdentifier)
        shutdownTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    }
    
    @objc func didBecomeActive()
    {
        // cancel the alert:
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["CarnetsShutdownAlert"])
        // cancel the termination:
        guard (shutdownTaskIdentifier != nil) else { return; }
        guard (shutdownTaskIdentifier != UIBackgroundTaskIdentifier.invalid) else { return; }
        let app = UIApplication.shared
        app.endBackgroundTask(shutdownTaskIdentifier)
        shutdownTaskIdentifier = UIBackgroundTaskIdentifier.invalid
        shutdownTimer.invalidate()
        shutdownTimer = nil
    }
    
    @objc func willResignActive()
    {
        // 3 min to close current process. Don't shutdown until 2 mn 45 s
        let app = UIApplication.shared
        guard (serverAddress != nil) else { return }
        shutdownTaskIdentifier = app.beginBackgroundTask(expirationHandler: self.terminateServer)
        let urlPost = serverAddress!.appendingPathComponent("api/shutdown")
        urlShutdownRequest = URLRequest(url: urlPost)
        urlShutdownRequest.httpMethod = "POST"
        // Configure the alert (if needed) at 2:15 mn:
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { (settings) in
            if (settings.authorizationStatus == .authorized) {
                let shutdownAlertContent = UNMutableNotificationContent()
                if settings.alertSetting == .enabled {
                    shutdownAlertContent.title = NSString.localizedUserNotificationString(forKey: "Carnets shutdown alert", arguments: nil)
                    shutdownAlertContent.body = NSString.localizedUserNotificationString(forKey: "Carnets is about to terminate. Click here if you want to continue.", arguments: nil)
                }
                if settings.soundSetting == .enabled {
                    shutdownAlertContent.sound = UNNotificationSound.default
                }
                let localShutdownNotification = UNNotificationRequest(identifier: "CarnetsShutdownAlert",
                                                                      content: shutdownAlertContent,
                                                                      trigger: UNTimeIntervalNotificationTrigger(timeInterval: (135), repeats: false))
                notificationCenter.add(localShutdownNotification, withCompletionHandler: { (error) in
                    if let error = error {
                        var message = "Error in setting up the alert: "
                        message.append(error.localizedDescription)
                        NSLog(message)
                    }
                })
            }
        }
        // Set up a timer to close everything at 2:45 mn
        if (shutdownTimer != nil) {
            shutdownTimer.invalidate()
            shutdownTimer = nil
        }
        DispatchQueue.main.async {
                self.shutdownTimer = Timer.scheduledTimer(timeInterval: 165,
                                                          target: self,
                                                          selector: #selector(self.terminateServer),
                                                          userInfo: nil,
                                                          repeats: false)
            }
    }

}



// This function is called when the user clicks on a link inside the App
// This is where we should replace webView.load (for internal action)
// with openurl_main to open in external browsers. Also Juno, when it
// has a specific URL scheme. 
extension ViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.stopLoading()
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Method called after a web page has been loaded, included as a result of goBack()
        // or goForward().
        // More accurate to store the latest URL accessed than navigationAction()
        guard (webView.url != nil) else { return }
        if (webView.url!.path.starts(with: "/api/")) { return }  // don't store api requests
        UserDefaults.standard.set(webView.url!.path, forKey: "lastOpenUrl")
    }
    
    
}
