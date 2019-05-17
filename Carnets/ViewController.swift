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
import ExternalAccessory
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
var appWebView: WKWebView!

var bookmarks: [URL: Data] = [:]  // bookmarks, indexed by URL. So bookmarks[fileUrl] is a bookmark for the file fileUrl.
var distantFiles: [URL: URL] = [:]  // correspondent between distant file and local file. distantFile = distantFiles[localFile]


var screenWidth: CGFloat {
    if screenOrientation.isPortrait {
        return UIScreen.main.bounds.size.width
    } else {
        return UIScreen.main.bounds.size.height
    }
}
var screenHeight: CGFloat {
    if screenOrientation.isPortrait {
        return UIScreen.main.bounds.size.height
    } else {
        return UIScreen.main.bounds.size.width
    }
}
var screenOrientation: UIInterfaceOrientation {
    return UIApplication.shared.statusBarOrientation
}

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
        // destination = localFiles[fileURL]
        for (localFileUrl, distantFileUrl) in distantFiles {
            if (distantFileUrl == fileURLToOpen) {
                destination = localFileUrl
                break
            }
        }
        if (destination == nil) {
            // do we have a local file storage:
            let temporaryDirectory = try! FileManager().url(for: .itemReplacementDirectory,
                                                            in: .userDomainMask,
                                                            appropriateFor: URL(fileURLWithPath: documentsPath!),
                                                            create: true)
            destination = temporaryDirectory.appendingPathComponent(fileURLToOpen!.lastPathComponent)
            distantFiles.updateValue(fileURLToOpen!, forKey: destination!)
            // localFiles.updateValue(destination!, forKey:fileURLToOpen!)
        }
        let isSecuredURL = fileURLToOpen!.startAccessingSecurityScopedResource() == true
        if (!downloadRemoteFile(fileURL: fileURL)) {
            fileURLToOpen!.stopAccessingSecurityScopedResource()
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
    }
    // local files.
    if (filePath.hasPrefix("/")) { filePath = String(filePath.dropFirst()) }
    while (serverAddress == nil) {  }
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
    guard (kernelURL != nil) else { return }
    guard (notebookBookmark != nil) else { return }
    var localFilePath = kernelURL!.path
    localFilePath.removeFirst("/notebooks".count)
    // localFilePath is now
    // /private/var/mobile/Containers/Data/Application/4AA730AE-A7CF-4A6F-BA65-BD2ADA01F8B4/tmp/(A Document Being Saved By Carnets)/00.00-Preface.ipynb
    // To know whether it's a remote file, scan list of remote files:
    let localFileUrl = URL(fileURLWithPath: localFilePath)
    let distantFile = distantFiles[localFileUrl]
    if (distantFile != nil) {
        // it's a distant file.
        do {
            var stale = false
            notebookURL = try URL(resolvingBookmarkData: notebookBookmark!, bookmarkDataIsStale: &stale)
            if (notebookURL != nil) {
                let temporaryDirectory = try! FileManager().url(for: .itemReplacementDirectory,
                                                                in: .userDomainMask,
                                                                appropriateFor: URL(fileURLWithPath: documentsPath!),
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
                // it's a distant file
                distantFiles.removeValue(forKey: oldNameUrl)
                distantFiles.updateValue(distantFile!, forKey: URL(fileURLWithPath: newName))
            }
            /*
            for (notebookURLStored, kernelURLStored) in localFiles {
                if (kernelURLStored.path == oldName) {
                    localFiles.updateValue(URL(fileURLWithPath: newName), forKey:notebookURLStored)
                    break
                }
            } */
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
        
    private var webView: WKWebView!
    private var contentView: UIView?
    
    var lastPageVisited: String!
    // buttons
    var undoButton: UIBarButtonItem?
    var redoButton: UIBarButtonItem?
    var saveButton: UIBarButtonItem?
    var addButton: UIBarButtonItem?
    var cutButton: UIBarButtonItem?
    var copyButton: UIBarButtonItem?
    var pasteButton: UIBarButtonItem?
    var upButton: UIBarButtonItem?
    var downButton: UIBarButtonItem?
    var runButton: UIBarButtonItem?
    var stopButton: UIBarButtonItem?
    var doneButton: UIBarButtonItem?
    var tabButton: UIBarButtonItem?
    var shiftTabButton: UIBarButtonItem?
    var leadingButtons: [UIBarButtonItem]?

    func initializeButtons() {
        // initializee button:
        var fontSize: CGFloat = screenWidth / 50
        print("Screen width = \(screenWidth), fontSize = \(fontSize)")
        if (fontSize > 18) { fontSize = 18.0 }
        cutButton = UIBarButtonItem(title: "\u{f0c4}", style: .plain, target: self, action: #selector(cutAction(_:)))
        cutButton!.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        copyButton = UIBarButtonItem(title: "\u{f0c5}", style: .plain, target: self, action: #selector(copyAction(_:)))
        copyButton!.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        pasteButton = UIBarButtonItem(title: "\u{f0ea}", style: .plain, target: self, action: #selector(pasteAction(_:)))
        pasteButton!.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        saveButton = UIBarButtonItem(title: "\u{f0c7}", style: .plain, target: self, action: #selector(saveAction(_:)))
        saveButton!.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        addButton = UIBarButtonItem(title: "\u{f067}", style: .plain, target: self, action: #selector(addAction(_:)))
        addButton!.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        undoButton = UIBarButtonItem(title: "\u{f0e2}", style: .plain, target: self, action: #selector(undoAction(_:)))
        undoButton!.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        redoButton = UIBarButtonItem(title: "\u{f01e}", style: .plain, target: self, action: #selector(redoAction(_:)))
        redoButton!.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        upButton = UIBarButtonItem(title: "\u{f062}", style: .plain, target: self, action: #selector(upAction(_:)))
        upButton!.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        downButton = UIBarButtonItem(title: "\u{f063}", style: .plain, target: self, action: #selector(downAction(_:)))
        downButton!.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        runButton = UIBarButtonItem(title: "\u{f051}", style: .plain, target: self, action: #selector(runAction(_:)))
        runButton!.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        stopButton = UIBarButtonItem(title: "\u{f04d}", style: .plain, target: self, action: #selector(stopAction(_:)))
        stopButton!.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        // "escape" button, using UTF-8
        doneButton = UIBarButtonItem(title: "␛", style: .plain, target: self, action: #selector(escapeKey(_:)))
        doneButton!.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "Apple Symbols", size: 1.8*fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        // "tab" button, using UTF-8
        tabButton = UIBarButtonItem(title: "⇥", style: .plain, target: self, action: #selector(autocompleteAction(_:)))
        // UIFont.systemFont(ofSize: 1.5*fontSize),
        tabButton!.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 1.8*fontSize),
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        // "shift-tab" button, using UTF-8
        shiftTabButton = UIBarButtonItem(title: "⇤", style: .plain, target: self, action: #selector(shiftTabAction(_:)))
        shiftTabButton!.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 1.8*fontSize),
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
    }

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
    
    // This works in text-input mode:
    @objc func escapeKey(_ sender: UIBarButtonItem) {
        webView.evaluateJavaScript("Jupyter.notebook.command_mode();") { (result, error) in
            if error != nil {
                print(error)
                print(result)
            }
        }
    }
    
    override var keyCommands: [UIKeyCommand]? {
        var basicKeyCommands = [
            UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(escapeKey), discoverabilityTitle: "Escape Key"),
            // Cmd-Z is reserved by Apple. We can register it, but it won't work
            // Removed discoverabilityTitle until it works.
            UIKeyCommand(input: "z", modifierFlags: .command, action: #selector(undoAction)),  // discoverabilityTitle: "Undo"),
            UIKeyCommand(input: "z", modifierFlags: [.command, .shift], action: #selector(redoAction)), // discoverabilityTitle: "Redo"),
            // control-Z is available
            UIKeyCommand(input: "z", modifierFlags: .control, action: #selector(undoAction), discoverabilityTitle: "Undo"),
            UIKeyCommand(input: "z", modifierFlags: [.control, .shift], action: #selector(redoAction), discoverabilityTitle: "Redo"),
            // Cmd-S is not reserved, so this works:
            UIKeyCommand(input: "s", modifierFlags: .command, action: #selector(saveAction), discoverabilityTitle: "Save"),
            // Ctrl-Enter: does not work (intercepted/not seen by JS)
            // Alt-Enter: managed by JS
            // Cmd-Enter: run cell, insert below (run Action)
            UIKeyCommand(input: "\r", modifierFlags:.command,  action: #selector(runAction), discoverabilityTitle: "Run cell, select next"),
            // Tab key in edit mode: does not work with external keyboard (but alt-tab works). But it should ("\t")
        ]
        /* Caps Lock remapped to escape -- only if required */
        if (UserDefaults.standard.bool(forKey: "escape_preference")) {
            // If we remapped caps-lock to escape, we need to disable caps-lock, at least with certain keyboards.
            // This loop remaps all lowercase characters without a modifier to themselves, thus disabling caps-lock
            // It doesn't work for characters produced with alt-key, though.
            for key in 0x061...0x2AF { // all lowercase unicode letters
                let K = Unicode.Scalar(key)!
                if CharacterSet.lowercaseLetters.contains(Unicode.Scalar(key)!) {
                    // no discoverabilityTitle
                    basicKeyCommands.append(UIKeyCommand(input: "\(K)", modifierFlags: [],  action: #selector(insertKey)))
                }
            }
            // no discoverabilityTitle
            basicKeyCommands.append(UIKeyCommand(input: "", modifierFlags:.alphaShift,  action: #selector(escapeKey)))
        }
        return basicKeyCommands
    }
    
    // Even if Caps-Lock is activated, send lower case letters.
    @objc func insertKey(_ sender: UIKeyCommand) {
        guard (sender.input != nil) else { return }
        let commandString = "if (Jupyter.notebook.get_selected_cell().mode === 'edit') { Jupyter.notebook.get_selected_cell().code_mirror.replaceSelection('\(sender.input!)'); }"
        webView.evaluateJavaScript(commandString) { (result, error) in
            if error != nil {
                print(error)
                print(result)
            }
        }
    }

    
    func needTabKey() -> Bool {
        // Is a tab key already present? If yes, don't show one.
        // connectedAccessories is empty even if there is a connected keyboard.
        // let accessoryManager: EAAccessoryManager = EAAccessoryManager.shared()
        // let connectedAccessories = accessoryManager.connectedAccessories
        let deviceModel = UIDevice.current.modelName
        if (!deviceModel.hasPrefix("iPad")) { return true } // iPhone, iPod: minimalist keyboard.
        if (deviceModel.hasPrefix("iPad6")) {
            if ((deviceModel == "iPad6,7") || (deviceModel == "iPad6,8")) {
                return false // iPad Pro 12.9" 1st gen
            } else {
                return true
            }
        }
        if (deviceModel.hasPrefix("iPad7")) {
            if ((deviceModel == "iPad7,1") || (deviceModel == "iPad7,2")) {
                return false // iPad Pro 12.9" 2nd gen
            } else {
                return true
            }
        }
        if (deviceModel.hasPrefix("iPad8")) {
            return false // iPad Pro 11" or iPad Pro 12.9" 3rd gen
        }
        return true // All other iPad models.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add cell buttons at the bottom of the screen for iPad.
        // From https://stackoverflow.com/questions/48978134/modifying-keyboard-toolbar-accessory-view-with-wkwebview
        webView.allowsBackForwardNavigationGestures = true
        webView.loadHTMLString("<html><body><div contenteditable='true'></div></body></html>", baseURL: nil)
        for subview in webView.scrollView.subviews {
            if subview.classForCoder.description() == "WKContentView" {
                contentView = subview
            }
        }
        if (cutButton == nil) { initializeButtons() }
        // Must be identical to code in keyboardDidShow()
        // This will only apply to the first keyboard. We have to register a callback for
        // the other keyboards.
        // undo, redo, save, add, cut, copy, paste //  done, up, down, run, escape.
        var leadingButtons: [UIBarButtonItem] =  [doneButton!]
        if (needTabKey()) {
            leadingButtons.append(tabButton!)
        }
        leadingButtons.append(shiftTabButton!)
        leadingButtons.append(undoButton!)
        leadingButtons.append(redoButton!)
        leadingButtons.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil))
        leadingButtons.append(saveButton!)
        leadingButtons.append(addButton!)
        leadingButtons.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil))
        leadingButtons.append(cutButton!)
        leadingButtons.append(copyButton!)
        leadingButtons.append(pasteButton!)
        
        inputAssistantItem.leadingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
            leadingButtons, representativeItem: nil)]
        inputAssistantItem.trailingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
            [upButton!, downButton!,
             UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
             runButton!, // stopButton!,
             ],
            representativeItem: nil)]
        // Don't prepare the keyboard until this one has disappeared, otherwise the buttons
        // on the first keyboard disappear.
        NotificationCenter.default.addObserver(self, selector: #selector(prepareNextKeyboard), name: UIResponder.keyboardDidHideNotification, object: nil)

        // in case Jupyter has started before the view is active (unlikely):
        guard (serverAddress != nil) else { return }
        guard (notebookURL != nil) else { return }
        kernelURL = urlFromFileURL(fileURL: notebookURL!)
        webView.load(URLRequest(url: kernelURL!))
    }
    
    // As soon as the first keyboard has been released, prepare a callback for the next one:
    @objc private func prepareNextKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
    }
    
    @objc private func autocompleteAction(_ sender: UIBarButtonItem) {
        // edit mode autocomplete
        // Create a "tab" keydown event. Either autocomplete or indent code
        // TODO: if shift is selected on keyboard, un-indent code (and remove shiftTabAction)
        webView.evaluateJavaScript("var event = new KeyboardEvent('keydown', {which:9, keyCode:9, bubbles:true}); if (!Jupyter.notebook.get_selected_cell().handle_keyevent(Jupyter.notebook.get_selected_cell().code_mirror, event)) { Jupyter.notebook.get_selected_cell().code_mirror.execCommand('defaultSoftTab');} ") { (result, error) in
            if error != nil {
                print(error)
                print(result)
            }
        }
    }
    
    @objc private func shiftTabAction(_ sender: UIBarButtonItem) {
        // edit mode autocomplete
        // Create a "shift + tab" keydown event. Either print function help or unindent code
        webView.evaluateJavaScript("var event = new KeyboardEvent('keydown', {which:9, keyCode:9, shiftKey:true, bubbles:true}); if (!Jupyter.notebook.get_selected_cell().handle_keyevent(Jupyter.notebook.get_selected_cell().code_mirror, event)) { Jupyter.notebook.get_selected_cell().code_mirror.execCommand('indentLess');} ") { (result, error) in
            if error != nil {
                print(error)
                print(result)
            }
        }
    }

    @objc private func cutAction(_ sender: UIBarButtonItem) {
        // edit mode cut (works)
        webView.evaluateJavaScript("document.execCommand('cut');") { (result, error) in
            if error != nil {
                print(error)
                print(result)
            }
        }
    // command mode cut (works)
        /* webView.evaluateJavaScript("var index = Jupyter.notebook.get_selected_index(); Jupyter.notebook.cut_cell(); Jupyter.notebook.select(index);"){ (result, error) in
            if error != nil {
                print(error)
                print(result)
            }
        } */
    }
    @objc private func copyAction(_ sender: UIBarButtonItem) {
        // edit mode copy (works)
        webView.evaluateJavaScript("document.execCommand('copy');") { (result, error) in
            if error != nil {
                print(error)
                print(result)
            }
        }
        // command mode copy (works)
        // javascript code to copy cell
        /* webView.evaluateJavaScript("Jupyter.notebook.copy_cell();") { (result, error) in
            if error != nil {
                print(error)
                print(result)
            }
        } */
    }
    
    @objc private func pasteAction(_ sender: UIBarButtonItem) {
        // edit mode paste (works)
        let pastedString = UIPasteboard.general.string
        if (pastedString != nil) { webView.paste(pastedString) }
        // command mode paste (works)
        /*
        webView.evaluateJavaScript("Jupyter.notebook.paste_cell_below();") { (result, error) in
            if error != nil {
                print(error)
                print(result)
            }
        }*/
    }

    @objc private func saveAction(_ sender: UIBarButtonItem) {
        webView.evaluateJavaScript("Jupyter.notebook.save_notebook();") { (result, error) in
            if error != nil {
                // print(error)
                // print(result)
            }
        }
    }

    // For add cell and run cell: we keep the notebook in edit mode, otherwise the keyboard will disappear
    @objc private func addAction(_ sender: UIBarButtonItem) {
        webView.evaluateJavaScript("Jupyter.notebook.insert_cell_below(); Jupyter.notebook.select_next(true); Jupyter.notebook.focus_cell(); Jupyter.notebook.edit_mode();") { (result, error) in
            if error != nil {
                print(error)
                print(result)
            }
        }
    }

    @objc private func runAction(_ sender: UIBarButtonItem) {
        webView.evaluateJavaScript("Jupyter.notebook.execute_cell_and_select_below(); Jupyter.notebook.edit_mode();") { (result, error) in
            if error != nil {
                print(error)
                print(result)
            }
        }
    }
    
    @objc private func upAction(_ sender: UIBarButtonItem) {
        webView.evaluateJavaScript("Jupyter.notebook.select_prev(true); Jupyter.notebook.focus_cell(); Jupyter.notebook.edit_mode();") { (result, error) in
            if error != nil {
                print(error)
                print(result)
            }
        }
    }

    @objc private func downAction(_ sender: UIBarButtonItem) {
        webView.evaluateJavaScript("Jupyter.notebook.select_next(true); Jupyter.notebook.focus_cell(); Jupyter.notebook.edit_mode();") { (result, error) in
            if error != nil {
                print(error)
                print(result)
            }
        }
    }

    @objc private func stopAction(_ sender: UIBarButtonItem) {
        // Does not work. Also, not desireable.
        webView.evaluateJavaScript("Jupyter.notebook.kernel.interrupt();") { (result, error) in
            if error != nil {
                print(error)
                print(result)
            }
        }
    }

    @objc private func undoAction(_ sender: UIBarButtonItem) {
        // works
        webView.evaluateJavaScript("Jupyter.notebook.get_selected_cell().code_mirror.execCommand('undo');") { (result, error) in
            if error != nil {
                print(error)
                print(result)
            }
        }
    }
    
    @objc private func redoAction(_ sender: UIBarButtonItem) {
        // works
        webView.evaluateJavaScript("Jupyter.notebook.get_selected_cell().code_mirror.execCommand('redo');") { (result, error) in
            if error != nil {
                print(error)
                print(result)
            }
        }
    }
    
    @objc private func keyboardDidShow() {
        if (cutButton == nil) { initializeButtons() }
        
        var leadingButtons: [UIBarButtonItem] =  [doneButton!]
        if (needTabKey()) {
            leadingButtons.append(tabButton!)
        }
        leadingButtons.append(shiftTabButton!)
        leadingButtons.append(undoButton!)
        leadingButtons.append(redoButton!)
        leadingButtons.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil))
        leadingButtons.append(saveButton!)
        leadingButtons.append(addButton!)
        leadingButtons.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil))
        leadingButtons.append(cutButton!)
        leadingButtons.append(copyButton!)
        leadingButtons.append(pasteButton!)
        
        contentView?.inputAssistantItem.leadingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
            leadingButtons, representativeItem: nil)]
        contentView?.inputAssistantItem.trailingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
            [upButton!, downButton!,
             UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
             runButton!, // stopButton!,
             ],
            representativeItem: nil)]
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
        NSLog("Trying to load: \(webView.url)")
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
            // To know whether it's a remote file, scan list of remote files:
            /* for (notebookURLStored, kernelURLStored) in localFiles {
                if (kernelURLStored.path == fileLocation) {
                    notebookURL = notebookURLStored
                    break
                }
            } */
            UserDefaults.standard.set(notebookURL, forKey: "lastOpenUrl")
            setSessionAccessTime(url: webView.url!)
        }
    }
}
