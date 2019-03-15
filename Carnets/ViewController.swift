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

var serverAddress: URL!
// The URL for the file being accessed (can be distant):
public var notebookURL: URL?
// A bookmark to the file being accessed (in case it changes name):
var notebookBookmark: Data?
// The URL for the notebook: http://localhost:8888/notebooks/Documents/file if local file
// http://localhost:8888/notebooks/tmp/(A Document Being Saved by YourApp 5)/file if distant
public var kernelURL: URL?
public var startingPath: String?
var appWebView: WKWebView!

var bookmarks: [URL: Data] = [:]
var localFiles: [URL: URL] = [:]


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

// load notebook sent by documentBrowser:
func urlFromFileURL(fileURL: URL) -> URL {
    var returnURL = serverAddress
    if (kernelURL != nil) {
        returnURL = kernelURL
    }
    guard (fileURL.isFileURL) else {
        return returnURL!
    }
    var filePath = fileURL.path
    if (!filePath.hasSuffix(".ipynb")) {
        // Don't open files that are not notebooks
        return returnURL!
    }
    if (filePath.hasPrefix("/private") && (!startingPath!.hasPrefix("/private"))) {
        filePath = String(filePath.dropFirst("/private".count))
    }
    if (filePath.hasPrefix(startingPath!)) {
        if (!FileManager().fileExists(atPath: filePath)) {
        // Don't try to open files that don't exist
            return returnURL!
        }
    } else {
        // Non-local file. Copy into ~/tmp/ and open
        // first, is that the last file we opened?
        var fileURLToOpen:URL?
        var destination:URL?
        if (notebookBookmark == nil) {
            notebookBookmark = UserDefaults.standard.data(forKey: "lastOpenUrlBookmark")
            if (notebookBookmark != nil) {
                var stale = false
                do {
                    let previousURL = try URL(resolvingBookmarkData: notebookBookmark!, bookmarkDataIsStale: &stale)
                    if (!stale && (previousURL.path == fileURL.path)) {
                            // They are the same, but the one from the bookmark still has the authorization
                            fileURLToOpen = previousURL
                            bookmarks.updateValue(notebookBookmark!, forKey:fileURLToOpen!)
                    }
                } catch {
                    NSLog("Could not resolve the bookmark to previous URL")
                    print(error)
                }
            }
        }
        if (fileURLToOpen == nil) {
            // Not the bookmark stored in UserDefaults, maybe in the dictionary?
            if (bookmarks[fileURL] != nil) {
                // We've met this one before
                var stale = false
                do {
                    let previousURL = try URL(resolvingBookmarkData: bookmarks[fileURL]!, bookmarkDataIsStale: &stale)
                    if (!stale && (previousURL.path == fileURL.path)) {
                        // We did this URL before, and still have the bookmark for it
                        fileURLToOpen = previousURL
                        notebookBookmark = bookmarks[fileURL]
                    }
                } catch {
                    NSLog("Could not resolve the bookmark to previous URL")
                    print(error)
                }
            }
        }
        // no existing bookmarks, so we take the URL given:
        if (fileURLToOpen == nil) {
            fileURLToOpen = fileURL
            notebookBookmark = nil  // if we're there, we don't have a bookmark
        }
        destination = localFiles[fileURL]
        if (destination == nil) {
            // do we have a local file storage:
            let temporaryDirectory = try! FileManager().url(for: .itemReplacementDirectory,
                                                            in: .userDomainMask,
                                                            appropriateFor: URL(fileURLWithPath: startingPath!),
                                                            create: true)
            destination = temporaryDirectory.appendingPathComponent(fileURLToOpen!.lastPathComponent)
            print(destination)
            localFiles.updateValue(destination!, forKey:fileURLToOpen!)
        }
        let isSecuredURL = fileURLToOpen!.startAccessingSecurityScopedResource() == true
        do {
            // Specific treatment for files on iCloud that are not downloaded:
            if (!FileManager().fileExists(atPath: fileURLToOpen!.path)) {
                NSLog("Downloading file from iCloud: \(fileURLToOpen)")
                try FileManager().startDownloadingUbiquitousItem(at: fileURLToOpen!)
                let startingTime = Date()
                // try downloading the file for 5s, then give up:
                while (!FileManager().fileExists(atPath: fileURLToOpen!.path) && (Date().timeIntervalSince(startingTime) < 5)) { }
                // TODO: add an alert, ask if user wants to continue
                NSLog("Done downloading, new status: \(FileManager().fileExists(atPath: fileURLToOpen!.path))")
            }
            if (notebookBookmark == nil) {
                notebookBookmark = try fileURLToOpen!.bookmarkData(options: [],
                                                                   includingResourceValuesForKeys: nil,
                                                                   relativeTo: nil)
                bookmarks.updateValue(notebookBookmark!, forKey:fileURLToOpen!)
            }
            UserDefaults.standard.set(notebookBookmark, forKey: "lastOpenUrlBookmark")
            if (FileManager().fileExists(atPath: destination!.path)) {
                try FileManager().removeItem(atPath: destination!.path)
            }
            try FileManager().copyItem(at: fileURLToOpen!, to: destination!)
        }
        catch {
            print(error)
            if (isSecuredURL) {
                fileURLToOpen!.stopAccessingSecurityScopedResource()
            }
            return returnURL!
        }
        if (isSecuredURL) {
            fileURLToOpen!.stopAccessingSecurityScopedResource()
        }
        filePath = destination!.path
        if (filePath.hasPrefix("/private") && (!startingPath!.hasPrefix("/private"))) {
            filePath = String(filePath.dropFirst("/private".count))
        }
    }
    // local files.
    filePath = String(filePath.dropFirst(startingPath!.count))
    if (filePath.hasPrefix("/")) { filePath = String(filePath.dropFirst()) }
    var fileAddressUrl = serverAddress.appendingPathComponent("notebooks")
    fileAddressUrl = fileAddressUrl.appendingPathComponent(filePath)
    return fileAddressUrl
}


/*
 override func fileAttributesToWrite(to url: URL, for saveOperation: UIDocumentSaveOperation) throws -> [AnyHashable : Any] {
 let thumbnail = thumbnailForDocument(at: url) return [
 URLResourceKey.hasHiddenExtensionKey: true, URLResourceKey.thumbnailDictionaryKey: [
 URLThumbnailDictionaryItem.NSThumbnail1024x1024SizeKey: thumbnail ]
 ] }
 */


func saveDistantFile() {
    var localFilePath = kernelURL!.path
    localFilePath = String(localFilePath.dropFirst("/notebooks".count))
    if (localFilePath.hasPrefix("/tmp")) {
        guard (notebookBookmark != nil) else { return }
        localFilePath = startingPath!.appending(localFilePath)
        do {
            var stale = false
            notebookURL = try URL(resolvingBookmarkData: notebookBookmark!, bookmarkDataIsStale: &stale)
            if (notebookURL != nil) {
                let temporaryDirectory = try! FileManager().url(for: .itemReplacementDirectory,
                                                                in: .userDomainMask,
                                                                appropriateFor: URL(fileURLWithPath: startingPath!),
                                                                create: true)
                var destination = temporaryDirectory
                destination = destination.appendingPathComponent(kernelURL!.lastPathComponent)
                try FileManager().copyItem(at: URL(fileURLWithPath: localFilePath), to: destination)
                notebookURL!.startAccessingSecurityScopedResource()
                try FileManager().replaceItemAt(notebookURL!, withItemAt: destination, backupItemName: nil, options: [])
                notebookURL!.stopAccessingSecurityScopedResource()
                try FileManager().removeItem(at: temporaryDirectory)
                NSLog("Saved distant file \(notebookURL!)")
            }
        }
        catch {
            print(error)
            NSLog("Could not save distant file \(notebookURL!)")
        }
    }
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
    guard (notebookURL != nil) else { return 0 }

    kernelURL = urlFromFileURL(fileURL: notebookURL!)
    appWebView.load(URLRequest(url: kernelURL!))
    return 0
}

class ViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let cmd:String = message.body as! String
        if (cmd == "quit") {
            // Warn the main app that the user has pressed the "quit" button
            clearAllRunningSessions()
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: notificationQuitRequested)))
        } else if (cmd == "save") {
            // if the file open is from another App, we copy the newly saved file too
            saveDistantFile()
        } else if (cmd.hasPrefix("loadingSession:")) {
            addRunningSession(session: cmd)
            if (numberOfRunningSessions() >= 4) { // Maybe "> 4"?
                NSLog("More than 4 notebook running (including this one). Time to cleanup.")
                let oldestSession = oldestRunningSession()
                let urlDelete = serverAddress!.appendingPathComponent(oldestSession)
                var urlDeleteRequest = URLRequest(url: urlDelete)
                urlDeleteRequest.httpMethod = "DELETE"
                urlDeleteRequest.setValue("json", forHTTPHeaderField: "dataType")
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
                    removeRunningSession(session: oldestSession)
                }
                task.resume()
            }
        } else if (cmd.hasPrefix("killingSession:")) {
            let range = cmd.startIndex..<cmd.firstIndex(of: "S")!
            let key = cmd.replacingCharacters(in: range, with: "loading")
            removeRunningSession(session: key)
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
    // document information

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
        guard (notebookURL != nil) else { return }
        kernelURL = urlFromFileURL(fileURL: notebookURL!)
        webView.load(URLRequest(url: kernelURL!))
    }
    
    @objc func terminateServer() {
        let app = UIApplication.shared
        let timeLeft = app.backgroundTimeRemaining
        NSLog("Terminating server. Time left = %f ", timeLeft)
        // shutdown Jupyter server and notebooks (takes about 7s with notebooks open)
        webView.load(urlShutdownRequest)
        // also remove list of running sessions:
        clearAllRunningSessions()
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
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        // Method called after a web page has been loaded, included as a result of goBack()
        // or goForward().
        // More accurate to store the latest URL accessed than navigationAction()
        guard (webView.url != nil) else { return }
        if (webView.url!.path.starts(with: "/api/")) { return }  // don't store api requests
        if (webView.url!.path == "/tree") {
            // We're leaving. Copy edited file back to place and remove directory:
            saveDistantFile()
            UserDefaults.standard.set(nil, forKey: "lastOpenUrl")
            UserDefaults.standard.set(nil, forKey: "lastOpenUrlBookmark")
            notebookURL = nil
            kernelURL = nil
            dismiss(animated: true)
        } // back to documentBrowser
    }
}
