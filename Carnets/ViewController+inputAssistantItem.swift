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
        let deviceModel = UIDevice.current.modelName
        if (deviceModel.hasPrefix("iPad")) {
            let minFontSize: CGFloat = screenWidth / 50
            // print("Screen width = \(screenWidth), fontSize = \(minFontSize)")
            if (minFontSize > 18) { return 18.0 }
            else { return minFontSize }
        } else {
            let minFontSize: CGFloat = screenWidth / 23
            // print("Screen width = \(screenWidth), fontSize = \(minFontSize)")
            if (minFontSize > 15) { return 15.0 }
            else { return minFontSize }
        }
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
    
    var pickerDoneButton: UIBarButtonItem {
        // "done" button, localized
        let pickerDoneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: nil, action: #selector(pickerDoneAction(_:)))
        pickerDoneButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "Apple Symbols", size: 1.8*fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.black,], for: .normal)
        return pickerDoneButton
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
            // on iPhones, adding the toolbar has changed the name of the view:
            if subview.classForCoder.description() == "WKApplicationStateTrackingView_CustomInputAccessoryView" {
                return subview
            }
        }
        return nil
    }
    
    // on iPhone, user selected pop-up menu:
    @objc func pickerDoneAction(_ sender: UIBarButtonItem) {
        // We need to signal that the user has selected the right field.
        // This can only be done with endEditing()
        contentView?.endEditing(false)
    }
    
    @objc func prepareFirstKeyboard() {
        // Must be identical to code in keyboardDidChange()
        // This will only apply to the first keyboard. We have to register a callback for
        // the other keyboards.
        // Notebooks:
        // escape, tab, shift tab, undo, redo, save, add, cut, copy, paste //  up, down, run.
        // Other views (including edit):
        // undo, redo, save // cut, copy, paste.
        
        let filePath = presentedItemURL?.path
        if (filePath?.hasSuffix(".ipynb") ?? false) {
            if ((externalKeyboardPresent ?? false) || !(multiCharLanguageWithSuggestions ?? false)) {

                var leadingButtons: [UIBarButtonItem] =  [doneButton]
                if (needTabKey && !(externalKeyboardPresent ?? false)) {
                    // no need for a tab key if there is an external keyboard
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
                
                // We need "representativeItem: nil" otherwise iOS compress the buttons into the representative item
                contentView?.inputAssistantItem.leadingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
                    leadingButtons, representativeItem: nil)]
                contentView?.inputAssistantItem.trailingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
                    [upButton, downButton,
                     UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
                     runButton, // stopButton,
                    ], representativeItem: nil)]
            } else {
                // We writing in Hindi, Chinese or Japanese. The keyboard uses a large place in the center for suggestions.
                // We can only put 3 buttons on each side:
                inputAssistantItem.leadingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
                    [undoButton, redoButton, runButton], representativeItem: nil)]
                inputAssistantItem.trailingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
                    [cutButton, copyButton, pasteButton], representativeItem: nil)]
            }
        } else {
            // Directory or edit text files. Only these buttons make sense
            inputAssistantItem.leadingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
                [undoButton, redoButton, saveButton], representativeItem: nil)]
            inputAssistantItem.trailingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
                [cutButton, copyButton, pasteButton], representativeItem: nil)]
        }

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add cell buttons at the bottom of the screen for iPad.
        // From https://stackoverflow.com/questions/48978134/modifying-keyboard-toolbar-accessory-view-with-wkwebview
        webView.allowsBackForwardNavigationGestures = true
        webView.loadHTMLString("<html><body><div contenteditable='true'></div></body></html>", baseURL: nil)
        
        if (UIDevice.current.modelName.hasPrefix("iPad")) {
            prepareFirstKeyboard()
            
            // Add a callback to change the buttons every time the user changes the input method:
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidChange), name: UITextInputMode.currentInputModeDidChangeNotification, object: nil)
            // And another to be called each time the keyboard is resized (including when an external KB is connected):
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidChange), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidChange), name: UITextInputMode.currentInputModeDidChangeNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidChange), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
            // NotificationCenter.default.addObserver(self, selector: #selector(iPhoneKeyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
            // NotificationCenter.default.addObserver(self, selector: #selector(iPhoneKeyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
        }

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
    
    @objc private func autocompleteAction(_ sender: UIBarButtonItem) {
        // edit mode autocomplete
        // Create a "tab" keydown event. Either autocomplete or indent code
        // TODO: if shift is selected on keyboard, un-indent code (and remove shiftTabAction)
        if (notebookCellInsertMode) {
            webView.evaluateJavaScript("var event = new KeyboardEvent('keydown', {which:9, keyCode:9, bubbles:true}); if (!Jupyter.notebook.get_selected_cell().handle_keyevent(Jupyter.notebook.get_selected_cell().code_mirror, event)) { Jupyter.notebook.get_selected_cell().code_mirror.execCommand('defaultSoftTab');} ") { (result, error) in
                if error != nil {
                    print(error)
                }
                if (result != nil) {
                    print(result)
                }
            }
        }
    }
    
    // shift-tab in Edit mode = crash
    @objc private func shiftTabAction(_ sender: UIBarButtonItem) {
        // edit mode autocomplete
        // Create a "shift + tab" keydown event. Either print function help or unindent code
        if (notebookCellInsertMode) {
            webView.evaluateJavaScript("var event = new KeyboardEvent('keydown', {which:9, keyCode:9, shiftKey:true, bubbles:true}); if (!Jupyter.notebook.get_selected_cell().handle_keyevent(Jupyter.notebook.get_selected_cell().code_mirror, event)) { Jupyter.notebook.get_selected_cell().code_mirror.execCommand('indentLess');} ") { (result, error) in
                if error != nil {
                    print(error)
                }
                if (result != nil) {
                    print(result)
                }
            }
        }
    }
    
    @objc func cutAction(_ sender: UIBarButtonItem) {
        // edit mode cut (works)
        webView.evaluateJavaScript("document.execCommand('cut');") { (result, error) in
            if error != nil {
                print(error)
            }
            if (result != nil) {
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
            }
            if (result != nil) {
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
    
    @objc func saveAction(_ sender: UIBarButtonItem) {
        guard (kernelURL != nil) else { return }
        if (kernelURL!.path.hasPrefix("/notebooks")) {
            webView.evaluateJavaScript("Jupyter.notebook.save_notebook();") { (result, error) in
                if error != nil {
                    print(error)
                }
                if (result != nil) {
                    print(result)
                }
            }
        } else {
            webView.evaluateJavaScript("Jupyter.editor.save();") { (result, error) in
                if error != nil {
                    print(error)
                }
                if (result != nil) {
                    print(result)
                }
            }
        }
    }
    
    // For add cell and run cell: we keep the notebook in edit mode, otherwise the keyboard will disappear
    @objc private func addAction(_ sender: UIBarButtonItem) {
        if (notebookCellInsertMode) {
            webView.evaluateJavaScript("Jupyter.notebook.insert_cell_below(); Jupyter.notebook.select_next(true); Jupyter.notebook.focus_cell(); Jupyter.notebook.edit_mode();") { (result, error) in
                if error != nil {
                    print(error)
                }
                if (result != nil) {
                    print(result)
                }
            }
        }
    }
    
    @objc func runAction(_ sender: UIBarButtonItem) {
        if (notebookCellInsertMode) {
            webView.evaluateJavaScript("Jupyter.notebook.execute_cell_and_select_below(); Jupyter.notebook.edit_mode();") { (result, error) in
                if error != nil {
                    print(error)
                }
                if (result != nil) {
                    print(result)
                }
            }
        }
    }
    
    @objc private func upAction(_ sender: UIBarButtonItem) {
        if (notebookCellInsertMode) {
            webView.evaluateJavaScript("Jupyter.notebook.select_prev(true); Jupyter.notebook.focus_cell(); Jupyter.notebook.edit_mode();") { (result, error) in
                if error != nil {
                    print(error)
                }
                if (result != nil) {
                    print(result)
                }
            }
        }
    }
    
    @objc private func downAction(_ sender: UIBarButtonItem) {
        if (notebookCellInsertMode) {
            webView.evaluateJavaScript("Jupyter.notebook.select_next(true); Jupyter.notebook.focus_cell(); Jupyter.notebook.edit_mode();") { (result, error) in
                if error != nil {
                    print(error)
                }
                if (result != nil) {
                    print(result)
                }
            }
        }
    }
    
    @objc private func stopAction(_ sender: UIBarButtonItem) {
        // Does not work. Also, not desireable.
        if (notebookCellInsertMode) {
            webView.evaluateJavaScript("Jupyter.notebook.kernel.interrupt();") { (result, error) in
                if error != nil {
                    print(error)
                }
                if (result != nil) {
                    print(result)
                }
            }
        }
    }
    
    @objc func undoAction(_ sender: UIBarButtonItem) {
        // works
        if (notebookCellInsertMode) {
            webView.evaluateJavaScript("Jupyter.notebook.get_selected_cell().code_mirror.execCommand('undo');") { (result, error) in
                if error != nil {
                    print(error)
                }
                if (result != nil) {
                    print(result)
                }
            }
        } else {
            webView.evaluateJavaScript("Jupyter.editor.codemirror.execCommand('undo');") { (result, error) in
                if error != nil {
                    print(error)
                }
                if (result != nil) {
                    print(result)
                }
            }
        }
    }
    
    @objc func redoAction(_ sender: UIBarButtonItem) {
        // works
        if (notebookCellInsertMode) {
            webView.evaluateJavaScript("Jupyter.notebook.get_selected_cell().code_mirror.execCommand('redo');") { (result, error) in
                if error != nil {
                    print(error)
                }
                if (result != nil) {
                    print(result)
                }
            }
        } else {
            webView.evaluateJavaScript("Jupyter.editor.codemirror.execCommand('redo');") { (result, error) in
                if error != nil {
                    print(error)
                }
                if (result != nil) {
                    print(result)
                }
            }
        }
    }

    
    @objc private func keyboardDidChange(notification: NSNotification) {
        // Notebooks:
        // escape, tab, shift tab, undo, redo, save, add, cut, copy, paste //  up, down, run.
        // Other views (including edit):
        // undo, redo, save // cut, copy, paste.
        // If it's a notebook, a file being edited, a tree, remove /prefix:
        // Only use "representativeItem" if keyboard has suggestion bar. Otherwise use "nil".
        // First update multiCharLanguageWithSuggestions:
        // First update multiCharLanguageWithSuggestions:
        let keyboardLanguage = contentView?.textInputMode?.primaryLanguage
        if (keyboardLanguage != nil) {
            // TODO: currently, we have no way to distinguish between Hindi and Hindi-Transliteration.
            // We treat them the same until we have a way to separate.
            // Is the keyboard language one of the multi-input language? Chinese, Japanese and Hindi-Transliteration
            // keyboardLanguage = "hi" -- not enough
            // keyboardLanguage = "zh-": all of them
            // keyboardLanguage = "jp-": all of them
            if (keyboardLanguage!.hasPrefix("hi") || keyboardLanguage!.hasPrefix("zh") || keyboardLanguage!.hasPrefix("ja")) {
                multiCharLanguageWithSuggestions = true
                if (UIDevice.current.systemVersionMajor < 13) {
                    // fix a Javascript issue in iOS versions before 13.
                    webView.evaluateJavaScript("iOS_multiCharLanguage = true;") { (result, error) in
                        if error != nil {
                            print(error)
                        }
                    }
                }
            } else {
                // otherwise return false:
                multiCharLanguageWithSuggestions = false
                if (UIDevice.current.systemVersionMajor < 13) {
                    webView.evaluateJavaScript("iOS_multiCharLanguage = false;") { (result, error) in
                        if error != nil {
                            print(error)
                        }
                    }
                }
            }
        }

        guard(kernelURL != nil) else { return }
        let info = notification.userInfo

        if (!UIDevice.current.modelName.hasPrefix("iPad")) {
            // iPhones and iPod touch (3)
            if (info != nil) {
                let keyboardFrame: CGRect = (info![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
                // iPhones or iPads: there is a toolbar at the bottom:
                if (keyboardFrame.size.height <= toolbarHeight) {
                    // Only the toolbar is left, hide it:
                    self.editorToolbar.isHidden = true
                    self.editorToolbar.isUserInteractionEnabled = false
                } else {
                    self.editorToolbar.isHidden = false
                    self.editorToolbar.isUserInteractionEnabled = true
                }
            }
            if (selectorActive) {
                // a picker is active: display only one button, with "Done". Only needed on iPhones
                self.editorToolbar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
                                            pickerDoneButton]
            } else if (kernelURL!.path.hasPrefix("/notebooks")) {
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
            return
        }

        // iPads:
        // Is there an external keyboard connected?
        if (info != nil) {
            // "keyboardFrameEnd" is a CGRect corresponding to the size of the keyboard plus the button bar.
            // It's 55 when there is an external keyboard connected, 300+ without.
            // Actual values may vary depending on device, but 60 seems a good threshold.
            let keyboardFrame: CGRect = (info![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            externalKeyboardPresent = keyboardFrame.size.height < 60
        }
        
        if (kernelURL!.path.hasPrefix("/notebooks")) {
            if ((externalKeyboardPresent ?? false) || !(multiCharLanguageWithSuggestions ?? false)) {
                var leadingButtons: [UIBarButtonItem] =  [doneButton]
                if (needTabKey && !(externalKeyboardPresent ?? false)) {
                    // no need for a tab key if there is an external keyboard
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
             
                // We need "representativeItem: nil" otherwise iOS compress the buttons into the representative item
                contentView?.inputAssistantItem.leadingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
                    leadingButtons, representativeItem: nil)]
                contentView?.inputAssistantItem.trailingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
                    [upButton, downButton,
                     UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
                     runButton, // stopButton,
                    ], representativeItem: nil)]
            } else {
                // We writing in Hindi, Chinese or Japanese. The keyboard uses a large place in the center for suggestions.
                // We can only put 3 buttons on each side:
                contentView?.inputAssistantItem.leadingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
                    [undoButton, redoButton, runButton], representativeItem: nil)]
                contentView?.inputAssistantItem.trailingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
                    [cutButton, copyButton, pasteButton], representativeItem: nil)]
            }
        } else {
            // Edit text files. Only these buttons make sense
            contentView?.inputAssistantItem.leadingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
                [undoButton, redoButton, saveButton], representativeItem: nil)]
            contentView?.inputAssistantItem.trailingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
                [cutButton, copyButton, pasteButton], representativeItem: nil)]
        }
    }
}
