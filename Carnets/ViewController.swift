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
// $HOME/Documents
public var documentsPath: String?
public var iCloudDocumentsURL: URL?
var lastModificationDate: Date?
var appWebView: WKWebView!  // We need a single appWebView 
var controller: ViewController? // for openURL_internal, bridging between C functions and ViewController class

var bookmarks: [URL: Data] = [:]  // bookmarks, indexed by URL. So bookmarks[fileUrl] is a bookmark for the file fileUrl.
var distantFiles: [URL: URL] = [:]  // correspondent between distant file and local file. distantFile = distantFiles[localFile]

var externalKeyboardPresent: Bool?
var multiCharLanguageWithSuggestions: Bool?
let toolbarHeight: CGFloat = 35

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
    // NSLog("Try downloading file from iCloud: \(fileURL)")
    do {
        // this will work with iCloud, but not Dropbox or Microsoft OneDrive, who have a specific API.
        // TODO: find out how to authorize Carnets for Dropbox, OneDrive, GoogleDrive.
        try FileManager().startDownloadingUbiquitousItem(at: fileURL)
        let startingTime = Date()
        // try downloading the file for 5s, then give up:
        while (!FileManager().fileExists(atPath: fileURL.path) && (Date().timeIntervalSince(startingTime) < 5)) { }
        // TODO: add an alert, ask if user wants to continue
        // NSLog("Done downloading, new status: \(FileManager().fileExists(atPath: fileURL.path))")
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


/*
 override func fileAttributesToWrite(to url: URL, for saveOperation: UIDocumentSaveOperation) throws -> [AnyHashable : Any] {
 let thumbnail = thumbnailForDocument(at: url) return [
 URLResourceKey.hasHiddenExtensionKey: true, URLResourceKey.thumbnailDictionaryKey: [
 URLThumbnailDictionaryItem.NSThumbnail1024x1024SizeKey: thumbnail ]
 ] }
 */


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

    if (controller != nil) { controller!.load(url: nil) }
    return 0
}


class ViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler, NSFilePresenter {
    
    // The URL for the file being accessed (can be distant):
    var presentedItemURL: URL?
    // A bookmark to the file being accessed (in case it changes name):
    var notebookBookmark: Data?
    // The URL for the notebook: http://localhost:8888/notebooks/private/var/mobile/Containers/Data/Application/B12A5C8D-DA05-4FE5-ABD6-DB12523ABAB7/tmp/(A%20Document%20Being%20Saved%20By%20Carnets)/Exploring%20Graphs%202.ipynb
    var kernelURL: URL?
    var notebookCellInsertMode = false // are we editing a notebook, in insert mode?
    var selectorActive = false // if we are inside a picker (roll-up  menu), change the toolbar

    var presentedItemOperationQueue = OperationQueue()

    func load(url: URL?) {
        if ((url != nil) && (url != presentedItemURL)) {
            NSFileCoordinator.removeFilePresenter(self)
            presentedItemURL = url
            NSFileCoordinator.addFilePresenter(self)
        }
        guard (presentedItemURL != nil) else { return }
        kernelURL = urlFromFileURL(fileURL: presentedItemURL!)
        guard (appWebView != nil) else { return }
        appWebView.load(URLRequest(url: kernelURL!))
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let cmd:String = message.body as! String
        if (cmd == "save") {
            // if the file open is from another App, we copy the newly saved file too
            print("We received a command to save the file")
            saveDistantFile()
        } else if (cmd == "commandMode") {
            notebookCellInsertMode = false
        } else if (cmd == "editMode") {
            notebookCellInsertMode = true
        } else if (cmd == "selector active") {
            selectorActive = true
            if (!UIDevice.current.modelName.hasPrefix("iPad")) {
                // System can call "selector active" after the keyboardDidChange event (when the selector is Markdown/Code)
                // We set up the toolbar here.
                self.editorToolbar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
                                            pickerDoneButton]
            }
        } else if (cmd == "selector inactive") {
            selectorActive = false
            if (!UIDevice.current.modelName.hasPrefix("iPad")) {
                // System can call "selector inactive" without triggering a keyboardDidChange Event (by hitting return, for example)
                // We restore the toolbar here.
                if (kernelURL!.path.hasPrefix("/notebooks")) {
                    self.editorToolbar.items = [undoButton, redoButton,
                                                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
                                                tabButton, shiftTabButton,
                                                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
                                                cutButton, copyButton, pasteButton,
                                                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
                                                upButton, downButton, runButton]
                } else {
                    self.editorToolbar.items = [undoButton, redoButton, saveButton,
                                                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
                                                cutButton, copyButton, pasteButton]
                }
            }
        } else if (cmd == "back") {
            // avoid infinite loops in back history.
            // Same approach not required for forward history
            // (also it does not work, forward history is cleared)
            if self.webView.canGoBack {
                var position = -1
                var backPageItem = self.webView.backForwardList.item(at: position)
                while ((backPageItem != nil) && (backPageItem?.url != nil) && ((backPageItem?.url.sameLocation(url: self.webView.url))!)) {
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
            print(cmd)
            var newName = cmd
            newName.removeFirst("rename:".count)
            print("NewName is \(newName)")
            var oldName = self.webView!.url!.path
            let isNotebook = oldName.hasPrefix("/notebooks/")
            let isEdit = oldName.hasPrefix("/edit/")
            if (isNotebook) {
                oldName.removeFirst("/notebooks".count)
            } else if (isEdit) {
                oldName.removeFirst("/edit".count)
            }
            if (isNotebook) {
                // To know whether it's a remote notebook, scan list of remote files:
                let oldNameUrl = URL(fileURLWithPath: oldName)
                let distantFile = distantFiles[oldNameUrl]
                if (distantFile != nil) {
                    // it's a distant notebook, update distantFiles dictionary:
                    distantFiles.removeValue(forKey: oldNameUrl)
                    distantFiles.updateValue(distantFile!, forKey: URL(fileURLWithPath: newName))
                }
                // Also update kernelURL:
                kernelURL = serverAddress.appendingPathComponent("notebooks")
                var kernelName = newName
                kernelName.removeFirst("/".count)
                kernelURL = kernelURL!.appendingPathComponent(kernelName)
                // and remove the current session (it will be reloaded, with a new ID):
                removeRunningSession(url: self.webView!.url!)
            } else if (isEdit) {
                // Also update kernelURL:
                kernelURL = serverAddress.appendingPathComponent("edit")
                var kernelName = newName
                kernelName.removeFirst("/".count)
                kernelURL = kernelURL!.appendingPathComponent(kernelName)
            }
            let oldFileURL = URL(fileURLWithPath: oldName)
            let newFileURL = URL(fileURLWithPath: newName)
            let localDirectory = localDirectoryFrom(localFile: newFileURL)
            if (localDirectory.isDirectory) {
                moveDistantFiles(securedURL: presentedItemURL, localFile: oldFileURL, movedTo: newFileURL, localDirectory: localDirectory)
            }
        } else if (cmd.hasPrefix("create:")) {
            var newFileName = cmd
            newFileName.removeFirst("create:".count)
            let newFileURL = URL(fileURLWithPath: newFileName)
            let localDirectory = localDirectoryFrom(localFile: newFileURL)
            print("localDirectory found: \(localDirectory)")
            let distantFile = distantFiles[localDirectory]
            print("distantFile = \(distantFile)")
            if (distantFile != nil) {
                var stale = false
                // presentedItemURL corresponds to the directory that was opened last, or to the file localFileUrl
                do {
                    let presentedItemURL = try URL(resolvingBookmarkData: notebookBookmark!, bookmarkDataIsStale: &stale)
                    // save the actual file to its remote directory:
                    replaceFileWithBookmark(securedURL: presentedItemURL, localFile: newFileURL, localDirectory: localDirectory)
                }
                catch {
                    NSLog("Unable to create the distant file/directory: \(newFileName)")
                    print(error)
                }
            }
        } else if (cmd.hasPrefix("renameFile:")) {
            var renameCommand = cmd
            print(cmd)
            renameCommand.removeFirst("renameFile:".count)
            let fileNames = renameCommand.split(separator: " ")
            let oldName = String(fileNames[0]).removingPercentEncoding
            let newName = String(fileNames[1]).removingPercentEncoding
            print("Received command: mv \(oldName) \(newName)")
            let oldFileURL = URL(fileURLWithPath: oldName!)
            let newFileURL = URL(fileURLWithPath: newName!)
            let localDirectory = localDirectoryFrom(localFile: newFileURL)
            if (localDirectory.isDirectory) {
                moveDistantFiles(securedURL: presentedItemURL, localFile: oldFileURL, movedTo: newFileURL, localDirectory: localDirectory)
            }
        } else if (cmd.hasPrefix("delete:")) {
            var fileToDelete = cmd
            print(cmd)
            fileToDelete.removeFirst("delete:".count)
            let fileToDeleteURL = URL(fileURLWithPath: fileToDelete)
            let localDirectory = localDirectoryFrom(localFile: fileToDeleteURL)
            if (localDirectory.isDirectory) {
                removeDistantFile(securedURL: presentedItemURL, localFile: fileToDeleteURL, localDirectory: localDirectory)
            }
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
    
    public lazy var editorToolbar: UIToolbar = {
        var toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.webView.bounds.width, height: toolbarHeight))
        toolbar.items = [undoButton, redoButton,
                         UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
                         tabButton, shiftTabButton,
                         UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
                         cutButton, copyButton, pasteButton,
                         UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
                         upButton, downButton, runButton]
        /* toolbar.items = [doneButton, undoButton, redoButton,
                         UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
                         tabButton, shiftTabButton,
                         UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
                         upButton, downButton, runButton] */
        return toolbar
    }()

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
        if (!UIDevice.current.modelName.hasPrefix("iPad")) {
            // toolbar for iPhones and iPod touch
            webView.addInputAccessoryView(toolbar: self.editorToolbar)
        }
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(undoAction), name: .NSUndoManagerWillUndoChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(redoAction), name: .NSUndoManagerWillRedoChange, object: nil)
        controller = self
        NSFileCoordinator.addFilePresenter(self)
    }
    
    // File management:
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
            for (localFileUrlStored, distantFileUrl) in distantFiles {
                if (distantFileUrl == fileURLToOpen) {
                    print("Already opened in distantFiles")
                    destination = localFileUrlStored
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
                        var newPath = localFileUrlStored.path
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
                        destination = localFileUrlStored.deletingLastPathComponent().appendingPathComponent(fileURLToOpen!.lastPathComponent)
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
                    NSFileCoordinator.removeFilePresenter(self)
                    presentedItemURL = fileURLToOpen
                    NSFileCoordinator.addFilePresenter(self)
                }
                distantFiles.updateValue(fileURLToOpen!, forKey: destination!)
            }
            let isSecuredURL = fileURLToOpen!.startAccessingSecurityScopedResource() == true
            print("startAccessingSecurityScopedResource")
            if (!downloadRemoteFile(fileURL: fileURL)) {
                if (isSecuredURL) {
                    fileURLToOpen!.stopAccessingSecurityScopedResource()
                }
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
                NSLog("Failure opening file:")
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
        // change directory to folder enclosing destination:
        var directoryURL = URL(fileURLWithPath: filePath)
        let destinationIsDirectory = directoryURL.isDirectory
        if (!destinationIsDirectory) {
            directoryURL = directoryURL.deletingLastPathComponent()
        }
        print("Changing directory to \(directoryURL.path)")
        FileManager().changeCurrentDirectoryPath(directoryURL.path)
        // local files.
        if (filePath.hasPrefix("/")) { filePath = String(filePath.dropFirst()) }
        while (serverAddress == nil) {  }
        var fileAddressUrl = serverAddress!
        if (filePath.hasSuffix(".ipynb")) {
            fileAddressUrl = fileAddressUrl.appendingPathComponent("notebooks")
        } else if (destinationIsDirectory) {
            fileAddressUrl = fileAddressUrl.appendingPathComponent("tree")
        } else {
            fileAddressUrl = fileAddressUrl.appendingPathComponent("edit")
        }
        // var fileAddressUrl = serverAddress.appendingPathComponent("notebooks")
        fileAddressUrl = fileAddressUrl.appendingPathComponent(filePath)
        // Set up the date as the time we loaded the file:
        lastModificationDate = Date()
        return fileAddressUrl
    }

    func localDirectoryFrom(localFile: URL) -> URL {
        // Extract local directory corresponding to localFile
        // Could also be cached (?)
        print("Entering localDirectoryFrom, localFile = \(localFile)")
        var localDirectory = localFile
        var distantFile = distantFiles[localFile]
        if (distantFile == nil) {
            localDirectory = localDirectory.deletingLastPathComponent()
            distantFile = distantFiles[localDirectory]
            while ((distantFile == nil) && (localDirectory.pathComponents.count > 7)) {
                // "7" corresponds to: /private/var/mobile/Containers/Data/Application/4AA730AE-A7CF-4A6F-BA65-BD2ADA01F8B4/tmp/
                // plus or minus "/private"
                print("Trying with \(localDirectory)")
                localDirectory = localDirectory.deletingLastPathComponent()
                distantFile = distantFiles[localDirectory]
            }
        }
        return localDirectory
    }
    
    var localFileUrl: URL {
        // print("kernelURL = \(kernelURL)")
        var localFilePath = kernelURL!.path
        // If it's a notebook, a file being edited, a tree, remove /prefix:
        if (localFilePath.hasPrefix("/notebooks")) {
            localFilePath.removeFirst("/notebooks".count)
        } else if (localFilePath.hasPrefix("/edit")) {
            localFilePath.removeFirst("/edit".count)
        } else if (localFilePath.hasPrefix("/tree")) {
            localFilePath.removeFirst("/tree".count)
        }
        // If it's a standard text file, don't do anything
        // localFilePath is now
        // /private/var/mobile/Containers/Data/Application/4AA730AE-A7CF-4A6F-BA65-BD2ADA01F8B4/tmp/(A Document Being Saved By Carnets)/00.00-Preface.ipynb
        return URL(fileURLWithPath: localFilePath)
    }
    
    func saveDistantFile() {
        // This function saves the current notebook and all the files that were modified recently in the directory being accessed.
        // This is the best way to ensure that all files created by the notebook are saved.
        print("Entering saveDistantFile: \(kernelURL)")
        guard (kernelURL != nil) else { return }
        guard (notebookBookmark != nil) else { return }
        if (kernelURL!.path.hasPrefix("/tree")) { return } // If we're displaying a directory, disable this function.
        // To know whether it's a remote file, scan list of remote files:
        let localDirectory = localDirectoryFrom(localFile: localFileUrl)
        print("localDirectory found: \(localDirectory)")
        let distantFile = distantFiles[localDirectory]
        print("distantFile = \(distantFile)")
        guard (distantFile != nil) else { return } // if it's a local file, return
        // it's a distant file.
        do {
            var stale = false
            // presentedItemURL corresponds to the directory that was opened last, or to the file localFileUrl
            presentedItemURL = try URL(resolvingBookmarkData: notebookBookmark!, bookmarkDataIsStale: &stale)
            print("presentedItemURL (saveDistantFile) = \(presentedItemURL)")
            if (presentedItemURL != nil) {
                // save the actual file to its remote directory:
                replaceFileWithBookmark(securedURL: presentedItemURL, localFile: localFileUrl, localDirectory: localDirectory)
                // Scanning for changes in local directory (except current file):
                let key = [URLResourceKey.contentModificationDateKey]
                if let dirContents = FileManager.default.enumerator(at: localDirectory.resolvingSymlinksInPath(), includingPropertiesForKeys: key) {
                    // the loop will be empty if it's a file, not a directory.
                    for case let url as URL in dirContents {
                        if (url == localFileUrl) { continue } // It's the actual file, we did it already.
                        // Allow 5 seconds for margin of error (checkpoint files are saved within +/- 1 second)
                        if (url.contentModificationDate + 5 > localFileUrl.contentModificationDate) {
                            replaceFileWithBookmark(securedURL: presentedItemURL, localFile: url, localDirectory: localDirectory)
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

    func removeDistantFile(securedURL: URL?, localFile: URL, localDirectory: URL) {
        guard (securedURL != nil) else { return }
        let distantDirectory = distantFiles[localDirectory]
        guard (distantDirectory != nil) else { return } // local files, nothing to do
        do {
            // we reconstruct the path to the *file*
            var prefixLength = localDirectory.path.count
            // It would be nice if the fileManager could be consistent with /var/mobile vs. /private/var/mobile...
            if (!localFile.path.hasPrefix("/private") && (localDirectory.path.hasPrefix("/private"))) {
                prefixLength -= "/private".count
            }
            if (localFile.path.hasPrefix("/private") && (!localDirectory.path.hasPrefix("/private"))) {
                prefixLength += "/private".count
            }
            var suffix = localFile.path
            suffix.removeFirst(prefixLength)
            print("removed file = \(suffix)")
            let distantFile = distantDirectory!.appendingPathComponent(suffix)
            print("removing distant file = \(distantFile)")
            let isSecureURL = securedURL!.startAccessingSecurityScopedResource()
            try FileManager().removeItem(at: distantFile)
            if (isSecureURL) {
                securedURL!.stopAccessingSecurityScopedResource()
            }
        }
        catch {
            print(error)
            // NSLog("Error in removeDistantFile: distant dir = \(presentedItemURL!) origine file = \(localFile)")
        }
    }
    
    func moveDistantFiles(securedURL: URL?, localFile: URL, movedTo: URL, localDirectory: URL) {
        guard (securedURL != nil) else { return }
        let distantDirectory = distantFiles[localDirectory]
        guard (distantDirectory != nil) else { return } // local files, nothing to do
        do {
            // we reconstruct the path to the *file*
            var prefixLength = localDirectory.path.count
            // It would be nice if the fileManager could be consistent with /var/mobile vs. /private/var/mobile...
            if (!localFile.path.hasPrefix("/private") && (localDirectory.path.hasPrefix("/private"))) {
                prefixLength -= "/private".count
            }
            if (localFile.path.hasPrefix("/private") && (!localDirectory.path.hasPrefix("/private"))) {
                prefixLength += "/private".count
            }
            var suffix = localFile.path
            suffix.removeFirst(prefixLength)
            print("file 1 = \(suffix)")
            let distantFile = distantDirectory!.appendingPathComponent(suffix)
            print("distant file 1 = \(distantFile)")
            prefixLength = localDirectory.path.count
            // It would be nice if the fileManager could be consistent with /var/mobile vs. /private/var/mobile...
            if (!movedTo.path.hasPrefix("/private") && (localDirectory.path.hasPrefix("/private"))) {
                prefixLength -= "/private".count
            }
            if (movedTo.path.hasPrefix("/private") && (!localDirectory.path.hasPrefix("/private"))) {
                prefixLength += "/private".count
            }
            suffix = movedTo.path
            suffix.removeFirst(prefixLength)
            print("file 2 = \(suffix)")
            let movedToDistant = distantDirectory!.appendingPathComponent(suffix)
            print("distant file 2 = \(movedToDistant)")
            let isSecureURL = securedURL!.startAccessingSecurityScopedResource()
                try FileManager().moveItem(at: distantFile, to: movedToDistant)
            if (isSecureURL) {
                securedURL!.stopAccessingSecurityScopedResource()
            }
        }
        catch {
            print(error)
            // NSLog("Error in moveDistantFiles: distant dir = \(presentedItemURL!) origine file = \(localFile) destination = \(movedTo)")
        }
    }
    
    // Given a secured URL (corresponding to a distant file or directory), a file (inside
    // Carnet's sandbox) and a local directory (which is a copy of the distant file pointed
    // by the bookmark), copy the local file into the distant directory.
    func replaceFileWithBookmark(securedURL: URL?, localFile: URL, localDirectory: URL) {
        guard (securedURL != nil) else { return }
        do {
            print("We got a bookmark in presentedItemURL: \(securedURL!)")
            let temporaryDirectory = try! FileManager().url(for: .itemReplacementDirectory,
                                                            in: .userDomainMask,
                                                            appropriateFor: URL(fileURLWithPath: documentsPath!),
                                                            create: true)
            var destination = temporaryDirectory
            destination = destination.appendingPathComponent(localFile.lastPathComponent)
            print("destination = \(destination)")
            try FileManager().copyItem(at: localFile, to: destination)
            // securedURL is the *directory* for which we have the writing permission.
            // we reconstruct the path to the *file*
            var suffix = localFile.path
            suffix.removeFirst(localDirectory.path.count) // this is empty if localFile is a file
            let distantFilePath = securedURL?.appendingPathComponent(suffix)
            print("distant file URL = \(distantFilePath!) = \(securedURL!) + \(suffix)")
            let isSecureURL = securedURL!.startAccessingSecurityScopedResource()
            // print("startAccessingSecurityScopedResource: \(isSecureURL)")
            let distantDirectory = distantFilePath?.deletingLastPathComponent()
            try FileManager().createDirectory(atPath: (distantDirectory?.path)!, withIntermediateDirectories: true)
            if (!FileManager().contentsEqual(atPath: distantFilePath!.path, andPath: destination.path)) {
                // only copy if the files are actually different:
                try FileManager().replaceItemAt(distantFilePath!, withItemAt: destination, backupItemName: nil, options: [])
            } else {
                try FileManager().removeItem(at: destination)
            }
            if (isSecureURL) {
                securedURL!.stopAccessingSecurityScopedResource()
            }
            // print("stopAccessingSecurityScopedResource")
            try FileManager().removeItem(at: temporaryDirectory)
            // NSLog("Saved distant file \(distantFilePath!)")
        }
        catch {
            print(error)
            // NSLog("Error in replaceFileWithBookmark: distant dir = \(presentedItemURL!) local file = \(localFile) local dir = \(localDirectory)")
        }
    }
    
    func replaceLocalFileWithBookmark(securedURL: URL?, distantFile: URL, localDirectory: URL) {
        // The user has changed a file inside the distant directory.
        // We propagate the changes into the local copy of the directory
        // TODO: check that the files are actually different
        guard (securedURL != nil) else { return }
        do {
            // we reconstruct the path to the *file*
            // print("distant file = \(distantFile.path)")
            // print("distant directory = \(securedURL!.path)")
            var prefixLength = securedURL!.path.count
            // It would be nice if the fileManager could be consistent with /var/mobile vs. /private/var/mobile...
            if (!distantFile.path.hasPrefix("/private") && (securedURL!.path.hasPrefix("/private"))) {
                prefixLength -= "/private".count
            }
            if (distantFile.path.hasPrefix("/private") && (!securedURL!.path.hasPrefix("/private"))) {
                prefixLength += "/private".count
            }
            var suffix = distantFile.path
            suffix.removeFirst(prefixLength)
            print("File = \(suffix)")
            let localFile = localDirectory.appendingPathComponent(suffix)
            print("local file = \(localFile)")
            // it seems a bad idea to change the document we are currently editing:
            if (localFile == localFileUrl) { return }
            // Check if local file is more recent than distant file:
            if (FileManager().fileExists(atPath: localFile.path)) {
                if (!FileManager().fileExists(atPath: distantFile.path)) {
                    print("distant File does not exist. Probably deleted")
                    try FileManager().removeItem(at: localFile)
                    return
                } else {
                    // local file is as recent as, or more recent than distantFile. No need to copy.
                    if (localFile.contentModificationDate >= distantFile.contentModificationDate) { return }
                }
            } else {
                if (!FileManager().fileExists(atPath: distantFile.path)) {
                    print("both files don't exist. we give up")
                    return
                }
            }
            let localDirectory = localFile.deletingLastPathComponent()
            // Make sure the directory exists before the copy:
            try FileManager().createDirectory(atPath: (localDirectory.path), withIntermediateDirectories: true)
            let isSecureURL = securedURL!.startAccessingSecurityScopedResource()
            // only copy if the files are actually different:
            if (FileManager().fileExists(atPath: localFile.path)) {
                if (!FileManager().contentsEqual(atPath:localFile.path, andPath:distantFile.path)) {
                    try FileManager().removeItem(at: localFile)
                    try FileManager().copyItem(at: distantFile, to: localFile)
                }
            } else {
                try FileManager().copyItem(at: distantFile, to: localFile)
            }
            if (isSecureURL) {
                securedURL!.stopAccessingSecurityScopedResource()
            }
        }
        catch {
            print(error)
            // NSLog("Error in replaceLocalFileWithBookmark: distant dir = \(presentedItemURL!) distant file = \(distantFile) local dir = \(localDirectory)")
        }
    }
    
    // File Presenter stuff:
    // This function is called when a file changes in the remote directory.
    func presentedSubitemDidChange(at url: URL) {
        print("We received notification of a change at file \(url)") // it works!
        guard (kernelURL != nil) else { return }
        guard (notebookBookmark != nil) else { return }
        var stale = false
        do {
            presentedItemURL = try URL(resolvingBookmarkData: notebookBookmark!, bookmarkDataIsStale: &stale)
            print("presentedItemURL (presentedSubitemDidChange) = \(presentedItemURL)")
            replaceLocalFileWithBookmark(securedURL: presentedItemURL, distantFile: url, localDirectory: localDirectoryFrom(localFile: localFileUrl))
        }
        catch {
            print(error)
            // NSLog("Error in presentedSubitemDidChange: distant dir = \(presentedItemURL!) distant file = \(url)")
        }
        // webView.evaluateJavaScript here creates a crash, so we can't force a refresh.
        // It would be good, though.
    }
    
    // This function is supposed to be called when a file is created. In practice, presentedSubitemDidChange is called.
    func presentedSubitemDidAppear(at url: URL) {
        print("We received notification of a file appearing at \(url)") // it works!
        guard (kernelURL != nil) else { return }
        guard (notebookBookmark != nil) else { return }
        var stale = false
        do {
            presentedItemURL = try URL(resolvingBookmarkData: notebookBookmark!, bookmarkDataIsStale: &stale)
            print("presentedItemURL (presentedSubitemDidAppear) = \(presentedItemURL)")
            replaceLocalFileWithBookmark(securedURL: presentedItemURL, distantFile: url, localDirectory: localDirectoryFrom(localFile: localFileUrl))
        }
        catch {
            print(error)
            // NSLog("Error in presentedSubitemDidAppear: distant dir = \(presentedItemURL!) distant file = \(url)")
        }
        // webView.evaluateJavaScript here creates a crash, so we can't force a refresh
    }
    
    func accommodatePresentedSubitemDeletion(at url: URL, completionHandler: @escaping (Error?) -> Void) {
        print("We received notification of a file deletion: \(url)")
        guard (kernelURL != nil) else { return }
        guard (notebookBookmark != nil) else { return }
        var stale = false
        let localDirectory = localDirectoryFrom(localFile: localFileUrl)
        do {
            presentedItemURL = try URL(resolvingBookmarkData: notebookBookmark!, bookmarkDataIsStale: &stale)
            print("presentedItemURL (accommodatePresentedSubitemDeletion) = \(presentedItemURL)")
            var prefixLength = presentedItemURL!.path.count
            // It would be nice if the fileManager could be consistent with /var/mobile vs. /private/var/mobile...
            if (!url.path.hasPrefix("/private") && (presentedItemURL!.path.hasPrefix("/private"))) {
                prefixLength -= "/private".count
            }
            if (url.path.hasPrefix("/private") && (!presentedItemURL!.path.hasPrefix("/private"))) {
                prefixLength += "/private".count
            }
            var suffix = url.path
            suffix.removeFirst(prefixLength)
            print("deleting file = \(suffix)")
            let localFile = localDirectory.appendingPathComponent(suffix)
            // it seems a bad idea to change the document we are currently editing:
            if (localFile == localFileUrl) { return }
            try FileManager().removeItem(at: localFile)
            print("deleted \(localFile)")
            completionHandler(nil)
        }
        catch {
            print(error)
            // NSLog("Error in accommodatePresentedSubitemDeletion: url = \(url)")
            completionHandler(error)
        }
    }
    
    // Tells the delegate that an item in the presented directory moved to a new location.
    func presentedSubitem(at url: URL, didMoveTo didMoveToURL: URL) {
        print("We received notification of a file url = \(url) moving to = \(didMoveToURL)")
        guard (kernelURL != nil) else { return }
        guard (notebookBookmark != nil) else { return }
        var stale = false
        let localDirectory = localDirectoryFrom(localFile: localFileUrl)
        do {
            presentedItemURL = try URL(resolvingBookmarkData: notebookBookmark!, bookmarkDataIsStale: &stale)
            print("presentedItemURL (presentedSubitem) = \(presentedItemURL)")
            var prefixLength = presentedItemURL!.path.count
            // It would be nice if the fileManager could be consistent with /var/mobile vs. /private/var/mobile...
            if (!url.path.hasPrefix("/private") && (presentedItemURL!.path.hasPrefix("/private"))) {
                prefixLength -= "/private".count
            }
            if (url.path.hasPrefix("/private") && (!presentedItemURL!.path.hasPrefix("/private"))) {
                prefixLength += "/private".count
            }
            var suffix = url.path
            suffix.removeFirst(prefixLength)
            // print("File = \(suffix)")
            let localFileStart = localDirectory.appendingPathComponent(suffix)
            // it seems a bad idea to change the document we are currently editing:
            if (localFileStart == localFileUrl) { return }
            // Somme apps delete files by moving them to $HOME/Documents/.Trash.
            // In that case, we delete the local copy. If the distant copy moves out of .Trash,
            // it will appear as a creation.
            let commonPrefix = url.path.commonPrefix(with: didMoveToURL.path)
            print("Common prefix: \(url.path.commonPrefix(with: didMoveToURL.path))")
            var movingToTrash = didMoveToURL.path
            movingToTrash.removeFirst(commonPrefix.count)
            if (movingToTrash.hasPrefix(".Trash")) {
                print("we're moving to Trash: \(movingToTrash)")
                print("removing file = \(localFileStart)")
                if (FileManager().fileExists(atPath: localFileStart.path)) {
                    try FileManager().removeItem(at: localFileStart)
                }
                // TODO: if a session is running with this file, send a shutdown request.
                return
            }
            prefixLength = presentedItemURL!.path.count
            // It would be nice if the fileManager could be consistent with /var/mobile vs. /private/var/mobile...
            if (!didMoveToURL.path.hasPrefix("/private") && (presentedItemURL!.path.hasPrefix("/private"))) {
                prefixLength -= "/private".count
            }
            if (didMoveToURL.path.hasPrefix("/private") && (!presentedItemURL!.path.hasPrefix("/private"))) {
                prefixLength += "/private".count
            }
            suffix = didMoveToURL.path
            suffix.removeFirst(prefixLength)
            let localFileEnd = localDirectory.appendingPathComponent(suffix)
            if (localFileEnd == localFileUrl) { return }
            print("moving file = \(localFileStart) to \(localFileEnd)")
            try FileManager().moveItem(at: localFileStart, to: localFileEnd)
        }
        catch {
            print(error)
            // NSLog("Error in presentedSubitem(at url: URL, didMoveTo didMoveToURL: URL): url = \(url) did move to = \(didMoveToURL)")
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
        // Method called after a web page has been loaded, including as a result of goBack()
        // or goForward().
        // More accurate to store the latest URL accessed than navigationAction()
        guard (webView.url != nil) else { return }
        guard (webView.url?.scheme != "about") else { return } // about:blank requests, often at start time
        if (webView.url!.path.starts(with: "/api/")) { return }  // don't store api requests
        if (webView.url!.path == "/tree") {
            // We're leaving. Copy edited file back to place and remove directory:
            saveDistantFile()
            UserDefaults.standard.set(nil, forKey: "lastOpenUrl")
            UserDefaults.standard.set(nil, forKey: "lastOpenUrlBookmark")
            presentedItemURL = nil
            kernelURL = nil
            NSFileCoordinator.removeFilePresenter(self)
            dismiss(animated: true) // back to documentBrowser
        } else {
            guard(webView.url != nil) else { return }
            var fileLocation = webView.url!.path
            kernelURL = webView.url 
            if (!fileLocation.hasPrefix("/notebooks/")) { return } // Don't try to store if it's not a notebook
            fileLocation.removeFirst("/notebooks".count)
            let fileUrl = URL(fileURLWithPath: fileLocation)
            presentedItemURL = distantFiles[fileUrl] // check wheter it's a distant file
            if (presentedItemURL == nil) { // it's a local file:
                presentedItemURL = fileUrl
            }
            UserDefaults.standard.set(presentedItemURL, forKey: "lastOpenUrl")
            setSessionAccessTime(url: webView.url!)
        }
    }
    
    // Javascript alert dialog boxes:
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        
        let arguments = message.components(separatedBy: "\n")

        let alertController = UIAlertController(title: arguments[0], message: arguments[1], preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            completionHandler()
        }))
        
        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = self.view
        }
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        
        let arguments = message.components(separatedBy: "\n")
        
        let alertController = UIAlertController(title: arguments[0], message: arguments[1], preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: arguments[2], style: .cancel, handler: { (action) in
            completionHandler(false)
        }))
        
        if (arguments[3].hasPrefix("btn-danger")) {
            var newLabel = arguments[3]
            newLabel.removeFirst("btn-danger".count)
            alertController.addAction(UIAlertAction(title: newLabel, style: .destructive, handler: { (action) in
                completionHandler(true)
            }))
        } else {
            alertController.addAction(UIAlertAction(title: arguments[3], style: .default, handler: { (action) in
                completionHandler(true)
            }))
        }
        
        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = self.view
        }
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        
        let arguments = prompt.components(separatedBy: "\n")
        let alertController = UIAlertController(title: arguments[0], message: arguments[1], preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.text = defaultText
        }

        alertController.addAction(UIAlertAction(title: arguments[2], style: .default, handler: { (action) in
            completionHandler(nil)
        }))
        
        alertController.addAction(UIAlertAction(title: arguments[3], style: .default, handler: { (action) in
            if let text = alertController.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler(defaultText)
            }
        }))
        
        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = self.view
        }
        
        self.present(alertController, animated: true, completion: nil)
    }

    
}
