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
// The URL for the notebook: http://localhost:8888/notebooks/private/var/mobile/Containers/Data/Application/B12A5C8D-DA05-4FE5-ABD6-DB12523ABAB7/tmp/(A%20Document%20Being%20Saved%20By%20Carnets)/Exploring%20Graphs%202.ipynb
public var kernelURL: URL?
// $HOME/Documents
public var documentsPath: String?
public var iCloudDocumentsURL: URL?
var lastModificationDate: Date?
var appWebView: WKWebView!

var bookmarks: [URL: Data] = [:]  // bookmarks, indexed by URL. So bookmarks[fileUrl] is a bookmark for the file fileUrl.
var distantFiles: [URL: URL] = [:]  // correspondent between distant file and local file. distantFile = distantFiles[localFile]


// is this file URL inside the App sandbox or not? (do we need to copy it locally?)
func insideSandbox(fileURL: URL) -> Bool {
    let filePath = fileURL.path
    guard (documentsPath != nil) else { return false }
    if (filePath.hasPrefix(documentsPath!)) { return true }
    if (!documentsPath!.hasPrefix("/private")) {
        var secondDocumentsPath = "/private"
        secondDocumentsPath.append(documentsPath!)
        if (filePath.hasPrefix(secondDocumentsPath)) { return true }
    }
    guard (iCloudDocumentsURL != nil) else { return false }
    if (filePath.hasPrefix(iCloudDocumentsURL!.path)) { return true }
    return false
}

func downloadRemoteFile(fileURL: URL) -> Bool {
    if (FileManager().fileExists(atPath: fileURL.path)) {
        return true
    }
    NSLog("Try downloading file from iCloud: \(fileURL)")
    do {
        try FileManager().startDownloadingUbiquitousItem(at: fileURL)
        let startingTime = Date()
        // try downloading the file for 5s, then give up:
        while (!FileManager().fileExists(atPath: fileURL.path) && (Date().timeIntervalSince(startingTime) < 5)) { }
        // TODO: add an alert, ask if user wants to continue
        NSLog("Done downloading, new status: \(FileManager().fileExists(atPath: fileURL.path))")
        if (FileManager().fileExists(atPath: fileURL.path)) {
            return true
        }
    }
    catch {
        NSLog("Could not download file from iCloud")
        print(error)
    }
    return false
}

// load notebook sent by documentBrowser:
func urlFromFileURL(fileURL: URL) -> URL {
    print("Starting urlFromFileURL: \(fileURL)")
    var returnURL = serverAddress
    if (kernelURL != nil) {
        returnURL = kernelURL
    }
    guard (fileURL.isFileURL) else {
        return returnURL!
    }
    var filePath = fileURL.path
    if (!insideSandbox(fileURL: fileURL)) {
        // Non-local file. Copy into ~/tmp/ and open
        // first, is that the last file we opened?
        print("non-local file.")
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
                        print("bookmarked before in notebookBookmark")
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
                print("bookmarked before in bookmarks[fileURL]")
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
        for (localFileUrl, distantFileUrl) in distantFiles {
            if (distantFileUrl == fileURLToOpen) {
                print("Already opened in distantFiles")
                destination = localFileUrl
                break
            }
            if (distantFileUrl.isDirectory) {
                // This distant file is a directory. Is the file we want to open part of this directory?
                // If so, no need to recreate the bookmark.
                if (fileURLToOpen!.path.hasPrefix(distantFileUrl.path)) {
                    print("We found a directory above the file: \(distantFileUrl) for \(fileURLToOpen!)")
                    notebookBookmark = bookmarks[distantFileUrl]
                    var suffix = fileURLToOpen!.path
                    suffix.removeFirst(distantFileUrl.path.count)
                    var newPath = localFileUrl.path
                    newPath.append(suffix)
                    print("Going to write at \(newPath)")
                    destination = URL(fileURLWithPath: newPath)
                }
            } else {
                // Have we worked on a file from the same directory before?
                // If so, we open this file in the same directory. So links between notebooks actually work.
                if (!fileURLToOpen!.isDirectory &&
                    (distantFileUrl.deletingLastPathComponent() == fileURLToOpen?.deletingLastPathComponent())) {
                    print("Parent directory exists in distantFiles: \( distantFileUrl.deletingLastPathComponent() )")
                    destination = localFileUrl.deletingLastPathComponent().appendingPathComponent(fileURLToOpen!.lastPathComponent)
                    break
                }
            }
        }
        if (destination == nil) {
            // do we have a local file storage:
            print("So far, no existing location")
            let temporaryDirectory = try! FileManager().url(for: .itemReplacementDirectory,
                                                            in: .userDomainMask,
                                                            appropriateFor: URL(fileURLWithPath: documentsPath!),
                                                            create: true)
            destination = temporaryDirectory.appendingPathComponent(fileURLToOpen!.lastPathComponent)
            if (fileURLToOpen!.isDirectory) {
                // We need to make sure directories are stored as such
                destination = destination!.appendingPathComponent("/")
            }
            print("Storing \(fileURLToOpen!) for key \(destination!) in distantFiles")
            distantFiles.updateValue(fileURLToOpen!, forKey: destination!)
        }
        let isSecuredURL = fileURLToOpen!.startAccessingSecurityScopedResource() == true
        print("startAccessingSecurityScopedResource")
        if (!downloadRemoteFile(fileURL: fileURL)) {
            fileURLToOpen!.stopAccessingSecurityScopedResource()
            print("stopAccessingSecurityScopedResource")
            return returnURL!
        }
        do {
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
            print("Copy file:")
            try FileManager().copyItem(at: fileURLToOpen!, to: destination!)
        }
        catch {
            print("Failure:")
            print(error)
            if (isSecuredURL) {
                print("stopAccessingSecurityScopedResource")
                fileURLToOpen!.stopAccessingSecurityScopedResource()
            }
            return returnURL!
        }
        if (isSecuredURL) {
            print("stopAccessingSecurityScopedResource")
            fileURLToOpen!.stopAccessingSecurityScopedResource()
        }
        filePath = destination!.path
    }
    // local files.
    if (filePath.hasPrefix("/")) { filePath = String(filePath.dropFirst()) }
    while (serverAddress == nil) {  }
    var fileAddressUrl = serverAddress.appendingPathComponent("notebooks")
    fileAddressUrl = fileAddressUrl.appendingPathComponent(filePath)
    // Set up the date as the time we loaded the file:
    lastModificationDate = Date()
    return fileAddressUrl
}


/*
 override func fileAttributesToWrite(to url: URL, for saveOperation: UIDocumentSaveOperation) throws -> [AnyHashable : Any] {
 let thumbnail = thumbnailForDocument(at: url) return [
 URLResourceKey.hasHiddenExtensionKey: true, URLResourceKey.thumbnailDictionaryKey: [
 URLThumbnailDictionaryItem.NSThumbnail1024x1024SizeKey: thumbnail ]
 ] }
 */

func replaceFileWithBookmark(securedURL: URL?, localFile: URL, localDirectory: URL) {
    guard (securedURL != nil) else { return }
    do {
    // print("We got a bookmark in notebookURL: \(securedURL!)")
    let temporaryDirectory = try! FileManager().url(for: .itemReplacementDirectory,
                                                    in: .userDomainMask,
                                                    appropriateFor: URL(fileURLWithPath: documentsPath!),
                                                    create: true)
    var destination = temporaryDirectory
    destination = destination.appendingPathComponent(localFile.lastPathComponent)
    // print("destination = \(destination)")
    try FileManager().copyItem(at: localFile, to: destination)
    // notebookURL is the *directory* for which we have the writing permission.
    // we reconstruct the path to the *file*
    var suffix = localFile.path
    suffix.removeFirst(localDirectory.path.count) // this is empty if localFile is a file
    let distantFilePath = securedURL?.appendingPathComponent(suffix)
    // print("distant file URL = \(distantFilePath!) = \(securedURL!) + \(suffix)")
    let isSecureURL = securedURL!.startAccessingSecurityScopedResource()
    // print("startAccessingSecurityScopedResource: \(isSecureURL)")
    let distantDirectory = distantFilePath?.deletingLastPathComponent()
    try! FileManager().createDirectory(atPath: (distantDirectory?.path)!, withIntermediateDirectories: true)
    try FileManager().replaceItemAt(distantFilePath!, withItemAt: destination, backupItemName: nil, options: [])
    if (isSecureURL) {
        securedURL!.stopAccessingSecurityScopedResource()
    }
    // print("stopAccessingSecurityScopedResource")
    try FileManager().removeItem(at: temporaryDirectory)
    // NSLog("Saved distant file \(distantFilePath!)")
    }
    catch {
        print(error)
        NSLog("Error in replaceFileWithBookmark: distant dir = \(notebookURL!) local file = \(localFile) local dir = \(localDirectory)")
    }
}

func saveDistantFile() {
    // print("Entering saveDistantFile: \(kernelURL)")
    guard (kernelURL != nil) else { return }
    guard (notebookBookmark != nil) else { return }
    var localFilePath = kernelURL!.path
    localFilePath.removeFirst("/notebooks".count)
    // localFilePath is now
    // /private/var/mobile/Containers/Data/Application/4AA730AE-A7CF-4A6F-BA65-BD2ADA01F8B4/tmp/(A Document Being Saved By Carnets)/00.00-Preface.ipynb
    // To know whether it's a remote file, scan list of remote files:
    let localFileUrl = URL(fileURLWithPath: localFilePath)
    var localDirectory = localFileUrl
    var distantFile = distantFiles[localFileUrl]
    if (distantFile == nil) {
        localDirectory = localDirectory.deletingLastPathComponent()
        distantFile = distantFiles[localDirectory]
        while ((distantFile == nil) && (localDirectory.pathComponents.count > 7)) {
            // "7" corresponds to: /private/var/mobile/Containers/Data/Application/4AA730AE-A7CF-4A6F-BA65-BD2ADA01F8B4/tmp/
            // plus or minus "/private"
            localDirectory = localDirectory.deletingLastPathComponent()
            distantFile = distantFiles[localDirectory]
        }
    }
    guard (distantFile != nil) else { return }
    // it's a distant file.
    do {
        var stale = false
        // notebookURL corresponds to the directory that was opened last, or to the file localFileUrl
        notebookURL = try URL(resolvingBookmarkData: notebookBookmark!, bookmarkDataIsStale: &stale)
        if (notebookURL != nil) {
            // save the actual file to its remote directory:
            replaceFileWithBookmark(securedURL: notebookURL, localFile: localFileUrl, localDirectory: localDirectory)
            // Scanning for changes in local directory (except current file):
            let key = [URLResourceKey.contentModificationDateKey]
            if let dirContents = FileManager.default.enumerator(at: localDirectory.resolvingSymlinksInPath(), includingPropertiesForKeys: key) {
                // the loop will be empty if it's a file, not a directory.
                for case let url as URL in dirContents {
                    if (url == localFileUrl) { continue } // It's the actual file, we did it already.
                    let value = try? url.resourceValues(forKeys: Set<URLResourceKey>(key))
                    // Allow 5 seconds for margin of error (checkpoint files are saved within +/- 1 second)
                    if ((value?.contentModificationDate)! + 5 > lastModificationDate!) {
                        replaceFileWithBookmark(securedURL: notebookURL, localFile: url, localDirectory: localDirectory)
                    }
                }
            }
            // Reset the lastModificationDate
            lastModificationDate = Date()
        }
    }
    catch {
        print(error)
        NSLog("Could not resolve bookmark for \(notebookBookmark!)")
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

// compare 2 URLs and return true if they correspond to the same
// page, excluding parameters and queries. This avoids infinite
// loops with redirections.
// Maybe we need to include parameters, but queries are excluded.
// We had an infinite loop with http://localhost:8888/nbextensions/
// loading http://localhost:8888/nbextensions/?nbextension=zenmode/main
func sameLocation(url1: URL?, url2: URL?) -> Bool {
    if (url1 == nil) && (url2 == nil) { return true }
    if (url1 == nil) { return false }
    if (url2 == nil) { return false }
    if (url1!.host != url2!.host) { return false }
    if (url1!.port != url2!.port) { return false }
    if (url1!.path != url2!.path) { return false }
    return true
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
        } else if (cmd == "back") {
            // avoid infinite loops in back history.
            // Same approach not required for forward history
            // (also it does not work, forward history is cleared)
            if self.webView.canGoBack {
                var position = -1
                var backPageItem = self.webView.backForwardList.item(at: position)
                while ((backPageItem != nil) && (sameLocation(url1: backPageItem?.url, url2: self.webView.url))) {
                    position -= 1
                    backPageItem = self.webView.backForwardList.item(at: position)
                }
                if (backPageItem != nil) {
                    self.webView.go(to: backPageItem!)
                    return
                }
            }
            // Nothing left in history, so we open the file server:
            var treeAddress = serverAddress
            treeAddress = treeAddress?.appendingPathComponent("tree")
            self.webView.load(URLRequest(url: treeAddress!))
        } else if (cmd.hasPrefix("rename:")) {
            var newName = cmd
            newName.removeFirst("rename:".count)
            var oldName = self.webView!.url!.path
            if (!oldName.hasPrefix("/notebooks/")) { return } // Don't try to rename if it's not a notebook
            oldName.removeFirst("/notebooks".count)
            // To know whether it's a remote file, scan list of remote files:
            let oldNameUrl = URL(fileURLWithPath: oldName)
            let distantFile = distantFiles[oldNameUrl]
            if (distantFile != nil) {
                // it's a distant file, update distantFiles dictionary:
                distantFiles.removeValue(forKey: oldNameUrl)
                distantFiles.updateValue(distantFile!, forKey: URL(fileURLWithPath: newName))
            }
            // Also update kernelURL:
            kernelURL = serverAddress.appendingPathComponent("notebooks")
            newName.removeFirst("/".count)
            kernelURL = kernelURL!.appendingPathComponent(newName)
            // and remove the current session (it will be reloaded, with a new ID):
            removeRunningSession(url: self.webView!.url!)
        } else if (cmd.hasPrefix("loadingSession:")) {
            NSLog(cmd)
            addRunningSession(session: cmd, url: self.webView!.url!)
            if (numberOfRunningSessions() >= 4) { // Maybe "> 4"?
                NSLog("More than 4 notebook running (including this one). Time to cleanup.")
                removeOldestSession()
            }
        } else if (cmd.hasPrefix("killingSession:")) {
            NSLog(cmd)
            var key = cmd
            key.removeFirst("killingSession:".count)
            if (key.hasPrefix("/")) {
                key = String(key.dropFirst())
            }
            removeRunningSessionWithID(session: key)
        } else {
            // JS console:
            NSLog("JavaScript message: \(message.body)")
        }
    }
        
    var webView: WKWebView!
    
    var lastPageVisited: String!

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
        
        NotificationCenter.default.addObserver(self, selector: #selector(undoAction), name: .NSUndoManagerWillUndoChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(redoAction), name: .NSUndoManagerWillRedoChange, object: nil)
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
        // Method called after a web page has been loaded, including as a result of goBack()
        // or goForward().
        // More accurate to store the latest URL accessed than navigationAction()
        guard (webView.url != nil) else { return }
        print("Trying to load: \(webView.url)")
        if (webView.url!.path.starts(with: "/api/")) { return }  // don't store api requests
        if (webView.url!.path == "/tree") {
            // We're leaving. Copy edited file back to place and remove directory:
            saveDistantFile()
            UserDefaults.standard.set(nil, forKey: "lastOpenUrl")
            UserDefaults.standard.set(nil, forKey: "lastOpenUrlBookmark")
            notebookURL = nil
            kernelURL = nil
            dismiss(animated: true) // back to documentBrowser
        } else {
            guard(webView.url != nil) else { return }
            var fileLocation = webView.url!.path
            if (!fileLocation.hasPrefix("/notebooks/")) { return } // Don't try to store if it's not a notebook
            kernelURL = webView.url
            fileLocation.removeFirst("/notebooks".count)
            let fileUrl = URL(fileURLWithPath: fileLocation)
            notebookURL = distantFiles[fileUrl] // check wheter it's a distant file
            if (notebookURL == nil) { // it's a local file:
                notebookURL = fileUrl
            }
            UserDefaults.standard.set(notebookURL, forKey: "lastOpenUrl")
            setSessionAccessTime(url: webView.url!)
        }
    }
}
