//
//  ViewController+inputAssistantItem.swift
//  Carnets
//
//  Created by Nicolas Holzschuch on 22/05/2019.
//  Copyright © 2019 AsheKube. All rights reserved.
//
// Extension to ViewController to deal with keyboard extension bar on iPad

import Foundation
import UIKit
import WebKit

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

extension ViewController {

    var needTabKey: Bool {
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
    
    var fontSize: CGFloat {
        let minFontSize: CGFloat = screenWidth / 50
        // print("Screen width = \(screenWidth), fontSize = \(minFontSize)")
        if (minFontSize > 18) { return 18.0 }
        else { return minFontSize }
    }
    
    // buttons
    var undoButton: UIBarButtonItem {
        let undoButton = UIBarButtonItem(title: "\u{f0e2}", style: .plain, target: self, action: #selector(undoAction(_:)))
        undoButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        return undoButton
    }
    
    var redoButton: UIBarButtonItem {
        let redoButton = UIBarButtonItem(title: "\u{f01e}", style: .plain, target: self, action: #selector(redoAction(_:)))
        redoButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        return redoButton
    }
    
    var saveButton: UIBarButtonItem {
        let saveButton = UIBarButtonItem(title: "\u{f0c7}", style: .plain, target: self, action: #selector(saveAction(_:)))
        saveButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        return saveButton
    }
    
    var addButton: UIBarButtonItem {
        let addButton = UIBarButtonItem(title: "\u{f067}", style: .plain, target: self, action: #selector(addAction(_:)))
        addButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        return addButton
    }
    
    var cutButton: UIBarButtonItem {
        let cutButton = UIBarButtonItem(title: "\u{f0c4}", style: .plain, target: self, action: #selector(cutAction(_:)))
        cutButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        return cutButton
    }
    
    var copyButton: UIBarButtonItem {
        let copyButton = UIBarButtonItem(title: "\u{f0c5}", style: .plain, target: self, action: #selector(copyAction(_:)))
        copyButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        return copyButton
    }
    
    var pasteButton: UIBarButtonItem {
        let pasteButton = UIBarButtonItem(title: "\u{f0ea}", style: .plain, target: self, action: #selector(pasteAction(_:)))
        pasteButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        return pasteButton
    }
    
    var upButton: UIBarButtonItem {
        let upButton = UIBarButtonItem(title: "\u{f062}", style: .plain, target: self, action: #selector(upAction(_:)))
        upButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        return upButton
    }
    
    var downButton: UIBarButtonItem {
        let downButton = UIBarButtonItem(title: "\u{f063}", style: .plain, target: self, action: #selector(downAction(_:)))
        downButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        return downButton
    }
    
    var runButton: UIBarButtonItem {
        let runButton = UIBarButtonItem(title: "\u{f051}", style: .plain, target: self, action: #selector(runAction(_:)))
        runButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        return runButton
    }
    
    var stopButton: UIBarButtonItem {
        let stopButton = UIBarButtonItem(title: "\u{f04d}", style: .plain, target: self, action: #selector(stopAction(_:)))
        stopButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        return stopButton
    }
    
    var doneButton: UIBarButtonItem {
        // "escape" button, using UTF-8
        let doneButton = UIBarButtonItem(title: "␛", style: .plain, target: self, action: #selector(escapeKey(_:)))
        doneButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "Apple Symbols", size: 1.8*fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        return doneButton
    }
    
    var tabButton: UIBarButtonItem {
        // "tab" button, using UTF-8
        let tabButton = UIBarButtonItem(title: "⇥", style: .plain, target: self, action: #selector(autocompleteAction(_:)))
        // UIFont.systemFont(ofSize: 1.5*fontSize),
        tabButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 1.8*fontSize),
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        return tabButton
    }
    var shiftTabButton: UIBarButtonItem {
        // "shift-tab" button, using UTF-8
        let shiftTabButton = UIBarButtonItem(title: "⇤", style: .plain, target: self, action: #selector(shiftTabAction(_:)))
        shiftTabButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 1.8*fontSize),
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        return shiftTabButton
    }
    
    private var contentView: UIView? {
        for subview in webView.scrollView.subviews {
            if subview.classForCoder.description() == "WKContentView" {
                return subview
            }
        }
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add cell buttons at the bottom of the screen for iPad.
        // From https://stackoverflow.com/questions/48978134/modifying-keyboard-toolbar-accessory-view-with-wkwebview
        webView.allowsBackForwardNavigationGestures = true
        webView.loadHTMLString("<html><body><div contenteditable='true'></div></body></html>", baseURL: nil)
        // Must be identical to code in keyboardDidShow()
        // This will only apply to the first keyboard. We have to register a callback for
        // the other keyboards.
        // undo, redo, save, add, cut, copy, paste //  done, up, down, run, escape.
        var leadingButtons: [UIBarButtonItem] =  [doneButton]
        if (needTabKey) {
            leadingButtons.append(tabButton)
        }
        leadingButtons.append(shiftTabButton)
        leadingButtons.append(undoButton)
        leadingButtons.append(redoButton)
        leadingButtons.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil))
        leadingButtons.append(saveButton)
        leadingButtons.append(addButton)
        leadingButtons.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil))
        leadingButtons.append(cutButton)
        leadingButtons.append(copyButton)
        leadingButtons.append(pasteButton)
        
        inputAssistantItem.leadingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
            leadingButtons, representativeItem: nil)]
        inputAssistantItem.trailingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
            [upButton, downButton,
             UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
             runButton, // stopButton,
            ],
            representativeItem: nil)]
        // Don't prepare the keyboard until this one has disappeared, otherwise the buttons
        // on the first keyboard disappear.
        NotificationCenter.default.addObserver(self, selector: #selector(prepareNextKeyboard), name: UIResponder.keyboardDidHideNotification, object: nil)
        
        // in case Jupyter has started before the view is active (unlikely):
        guard (serverAddress != nil) else {
            NSLog("serverAddress is nil, return from load")
            return
        }
        guard (presentedItemURL != nil) else {
            NSLog("presentedItemURL is nil, return from load")
            return
        }
        kernelURL = urlFromFileURL(fileURL: presentedItemURL!)
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
                print(error as! String)
                print(result as! String)
            }
        }
    }
    
    @objc private func shiftTabAction(_ sender: UIBarButtonItem) {
        // edit mode autocomplete
        // Create a "shift + tab" keydown event. Either print function help or unindent code
        webView.evaluateJavaScript("var event = new KeyboardEvent('keydown', {which:9, keyCode:9, shiftKey:true, bubbles:true}); if (!Jupyter.notebook.get_selected_cell().handle_keyevent(Jupyter.notebook.get_selected_cell().code_mirror, event)) { Jupyter.notebook.get_selected_cell().code_mirror.execCommand('indentLess');} ") { (result, error) in
            if error != nil {
                print(error as! String)
                print(result as! String)
            }
        }
    }
    
    @objc func cutAction(_ sender: UIBarButtonItem) {
        // edit mode cut (works)
        webView.evaluateJavaScript("document.execCommand('cut');") { (result, error) in
            if error != nil {
                print(error as! String)
                print(result as! String)
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
                print(error as! String)
                print(result as! String)
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
    
    @objc func saveAction(_ sender: UIBarButtonItem) {
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
                print(error as! String)
                print(result as! String)
            }
        }
    }
    
    @objc func runAction(_ sender: UIBarButtonItem) {
        webView.evaluateJavaScript("Jupyter.notebook.execute_cell_and_select_below(); Jupyter.notebook.edit_mode();") { (result, error) in
            if error != nil {
                print(error as! String)
                print(result as! String)
            }
        }
    }
    
    @objc private func upAction(_ sender: UIBarButtonItem) {
        webView.evaluateJavaScript("Jupyter.notebook.select_prev(true); Jupyter.notebook.focus_cell(); Jupyter.notebook.edit_mode();") { (result, error) in
            if error != nil {
                print(error as! String)
                print(result as! String)
            }
        }
    }
    
    @objc private func downAction(_ sender: UIBarButtonItem) {
        webView.evaluateJavaScript("Jupyter.notebook.select_next(true); Jupyter.notebook.focus_cell(); Jupyter.notebook.edit_mode();") { (result, error) in
            if error != nil {
                print(error as! String)
                print(result as! String)
            }
        }
    }
    
    @objc private func stopAction(_ sender: UIBarButtonItem) {
        // Does not work. Also, not desireable.
        webView.evaluateJavaScript("Jupyter.notebook.kernel.interrupt();") { (result, error) in
            if error != nil {
                print(error as! String)
                print(result as! String)
            }
        }
    }
    
    @objc func undoAction(_ sender: UIBarButtonItem) {
        // works
        webView.evaluateJavaScript("Jupyter.notebook.get_selected_cell().code_mirror.execCommand('undo');") { (result, error) in
            if error != nil {
                print(error as! String)
                print(result as! String)
            }
        }
    }
    
    @objc func redoAction(_ sender: UIBarButtonItem) {
        // works
        webView.evaluateJavaScript("Jupyter.notebook.get_selected_cell().code_mirror.execCommand('redo');") { (result, error) in
            if error != nil {
                print(error as! String)
                print(result as! String)
            }
        }
    }
    
    @objc private func keyboardDidShow() {
        var leadingButtons: [UIBarButtonItem] =  [doneButton]
        if (needTabKey) {
            leadingButtons.append(tabButton)
        }
        leadingButtons.append(shiftTabButton)
        leadingButtons.append(undoButton)
        leadingButtons.append(redoButton)
        leadingButtons.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil))
        leadingButtons.append(saveButton)
        leadingButtons.append(addButton)
        leadingButtons.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil))
        leadingButtons.append(cutButton)
        leadingButtons.append(copyButton)
        leadingButtons.append(pasteButton)
        
        contentView?.inputAssistantItem.leadingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
            leadingButtons, representativeItem: nil)]
        contentView?.inputAssistantItem.trailingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
            [upButton, downButton,
             UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
             runButton, // stopButton!,
            ],
            representativeItem: nil)]
    }

}
