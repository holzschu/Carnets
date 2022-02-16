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
    
    var darkMode: Bool {
        if #available(iOS 13, *) {
            // Are we in light mode or dark mode?
            var H_fg: CGFloat = 0
            var S_fg: CGFloat = 0
            var B_fg: CGFloat = 0
            var A_fg: CGFloat = 0
            UIColor.placeholderText.resolvedColor(with: traitCollection).getHue(&H_fg, saturation: &S_fg, brightness: &B_fg, alpha: &A_fg)
            var H_bg: CGFloat = 0
            var S_bg: CGFloat = 0
            var B_bg: CGFloat = 0
            var A_bg: CGFloat = 0
            UIColor.systemBackground.resolvedColor(with: traitCollection).getHue(&H_bg, saturation: &S_bg, brightness: &B_bg, alpha: &A_bg)
            return (B_fg > B_bg)
        } else {
            return false
        }
    }
    
    var fontSize: CGFloat {
        let deviceModel = UIDevice.current.modelName
        if (deviceModel.hasPrefix("iPad")) {
            if #available(iOS 13.0, *) {
                let minFontSize: CGFloat = screenWidth / 70
                // print("Screen width = \(screenWidth), fontSize = \(minFontSize)")
                if (minFontSize > 15) { return 15.0 }
                else { return minFontSize }
            } else {
                let minFontSize: CGFloat = screenWidth / 50
                // print("Screen width = \(screenWidth), fontSize = \(minFontSize)")
                if (minFontSize > 18) { return 18.0 }
                else { return minFontSize }
            }
        } else {
            let minFontSize: CGFloat = screenWidth / 23
            // print("Screen width = \(screenWidth), fontSize = \(minFontSize)")
            if (minFontSize > 15) { return 15.0 }
            else { return minFontSize }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        NSLog("Called traitCollectionDidChange")
        if #available(iOS 13.0, *) {
            guard (kernelURL != nil) else { return } // too soon
            // Change default color of appWebView:
            appWebView.tintColor = UIColor.placeholderText.resolvedColor(with: traitCollection)
            if (darkMode) {
                appWebView.backgroundColor = UIColor(hexString: "#2b303b")
            } else {
                appWebView.backgroundColor = UIColor.systemBackground.resolvedColor(with: traitCollection)
            }
            // Change color of navigation bar:
            navigationController?.navigationBar.tintColor = UIColor.placeholderText.resolvedColor(with: traitCollection)
            if (darkMode) {
                navigationController?.navigationBar.backgroundColor = UIColor(hexString: "#2b303b")
                navigationController?.navigationBar.barTintColor = UIColor(hexString: "#2b303b")
            } else {
                // navigationController?.navigationBar.backgroundColor = UIColor.systemBackground.resolvedColor(with: traitCollection)
                navigationController?.navigationBar.backgroundColor = UIColor(hexString: "#f8f8f8")
                navigationController?.navigationBar.barTintColor = UIColor(hexString: "#f8f8f8")
            }
            // redraw toolbar
            if (UIDevice.current.modelName.hasPrefix("iPad")) {
                if (kernelURL!.path.hasPrefix("/notebooks") || kernelURL!.path.hasPrefix("/tree")) {
                    if ((externalKeyboardPresent ?? false) || !(multiCharLanguageWithSuggestions ?? false)) {
                        var leadingButtons: [UIBarButtonItem] =  [doneButton]
                        if (needTabKey && !(externalKeyboardPresent ?? false)) {
                            // no need for a tab key if there is an external keyboard
                            leadingButtons.append(tabButton)
                        }
                        leadingButtons.append(shiftTabButton)
                        leadingButtons.append(undoButton)
                        leadingButtons.append(redoButton)
                        leadingButtons.append(saveButton)
                        leadingButtons.append(addButton)
                        // leadingButtons.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil))

                        // We need "representativeItem: nil" otherwise iOS compress the buttons into the representative item
                        contentView?.inputAssistantItem.leadingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
                            leadingButtons, representativeItem: nil)]
                        contentView?.inputAssistantItem.trailingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
                            [cutButton, copyButton, pasteButton, upButton, downButton, runButton], representativeItem: nil)]
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
            } else {
                // for iPhones and iPod Touch (14 installs in 8 months)
                // Goal: reproduce keyboard tint and color.
                editorToolbar.backgroundColor = UIColor.systemBackground.resolvedColor(with: traitCollection)
                editorToolbar.isTranslucent = false
                if (darkMode) {
                    editorToolbar.barTintColor = UIColor(hexString: "#25272B")
                    editorToolbar.tintColor = .white
                } else {
                    // Measured on iPhone 8, iOS 13.3.1. Not the same as systemBackground.
                    editorToolbar.barTintColor = UIColor(hexString: "#D1D2D9")
                    editorToolbar.tintColor = .black
                }
            }
        }
    }
    
    var tintColor: UIColor {
        // This works, but does not update while the app is running
        if #available(iOS 13, *) {
            return UIColor.placeholderText.resolvedColor(with: self.traitCollection).nonTransparent();
        } else {
            return UIColor.black
        }
    }
    
    // buttons
    var undoButton: UIBarButtonItem {
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration(pointSize: fontSize, weight: .regular)
            return UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.left")!.withConfiguration(configuration), style: .plain, target: self, action: #selector(undoAction(_:)))
        } else {
        let undoButton = UIBarButtonItem(title: "\u{f0e2}", style: .plain, target: self, action: #selector(undoAction(_:)))
        undoButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : tintColor,], for: .normal)
        return undoButton
        }
    }
    
    var redoButton: UIBarButtonItem {
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration(pointSize: fontSize, weight: .regular)
            return UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.right")!.withConfiguration(configuration), style: .plain, target: self, action: #selector(redoAction(_:)))
        } else {
        let redoButton = UIBarButtonItem(title: "\u{f01e}", style: .plain, target: self, action: #selector(redoAction(_:)))
        redoButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : tintColor,], for: .normal)
        return redoButton
        }
    }
    
    var saveButton: UIBarButtonItem {
        var saveSize = fontSize
        if #available(iOS 13.0, *) {
            saveSize *= 7.0/5.0
            if (saveSize > 18.0) {
                saveSize = 18.0
            }
        }
        let saveButton = UIBarButtonItem(title: "\u{f0c7}", style: .plain, target: self, action: #selector(saveAction(_:)))
        saveButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: saveSize)!,
             NSAttributedString.Key.foregroundColor : tintColor,], for: .normal)
        if #available(iOS 15.0, *) {
            // make the save icon as gray as the rest of the icons, since I can't make them black
            let newTintColor = UIColor.tertiaryLabel.resolvedColor(with: self.traitCollection);
            saveButton.setTitleTextAttributes(
                [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: saveSize)!,
                 NSAttributedString.Key.foregroundColor : newTintColor,], for: .normal)
        }
        return saveButton
    }
    
    var addButton: UIBarButtonItem {
        if #available(iOS 15.0, *) {
            let configuration = UIImage.SymbolConfiguration(hierarchicalColor: .tintColor)
            let addButton = UIBarButtonItem(image: UIImage(systemName: "plus", withConfiguration: configuration)!, style: .plain, target: self, action: #selector(addAction(_:)))
            return addButton
        } else if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration(pointSize: fontSize, weight: .regular)
            return UIBarButtonItem(image: UIImage(systemName: "plus", withConfiguration: configuration)!, style: .plain, target: self, action: #selector(addAction(_:)))
        } else {
            let addButton = UIBarButtonItem(title: "\u{f067}", style: .plain, target: self, action: #selector(addAction(_:)))
            addButton.setTitleTextAttributes(
                [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
                 NSAttributedString.Key.foregroundColor : tintColor,], for: .normal)
            return addButton
        }
    }
    
    var cutButton: UIBarButtonItem {
        if #available(iOS 15.0, *) {
            let configuration = UIImage.SymbolConfiguration(hierarchicalColor: .tintColor)
            return UIBarButtonItem(image: UIImage(systemName: "scissors", withConfiguration: configuration)!, style: .plain, target: self, action: #selector(addAction(_:)))
        } else if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration(pointSize: fontSize, weight: .regular)
            return UIBarButtonItem(image: UIImage(systemName: "scissors")!.withConfiguration(configuration), style: .plain, target: self, action: #selector(cutAction(_:)))
        } else {
        let cutButton = UIBarButtonItem(title: "\u{f0c4}", style: .plain, target: self, action: #selector(cutAction(_:)))
        cutButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : tintColor,], for: .normal)
        return cutButton
        }
    }
    
    var copyButton: UIBarButtonItem {
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration(pointSize: fontSize, weight: .regular)
            return UIBarButtonItem(image: UIImage(systemName: "doc.on.doc")!.withConfiguration(configuration), style: .plain, target: self, action: #selector(copyAction(_:)))
        } else {
            let copyButton = UIBarButtonItem(title: "\u{f0c5}", style: .plain, target: self, action: #selector(copyAction(_:)))
            copyButton.setTitleTextAttributes(
                [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
                 NSAttributedString.Key.foregroundColor : tintColor,], for: .normal)
            return copyButton
        }
    }
    
    var pasteButton: UIBarButtonItem {
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration(pointSize: fontSize, weight: .regular)
            return UIBarButtonItem(image: UIImage(systemName: "doc.on.clipboard")!.withConfiguration(configuration), style: .plain, target: self, action: #selector(pasteAction(_:)))
        } else {
            let pasteButton = UIBarButtonItem(title: "\u{f0ea}", style: .plain, target: self, action: #selector(pasteAction(_:)))
            pasteButton.setTitleTextAttributes(
                [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
                 NSAttributedString.Key.foregroundColor : tintColor,], for: .normal)
            return pasteButton
        }
    }
    
    var upButton: UIBarButtonItem {
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration(pointSize: fontSize, weight: .regular)
            return UIBarButtonItem(image: UIImage(systemName: "arrow.up")!.withConfiguration(configuration), style: .plain, target: self, action: #selector(upAction(_:)))
        } else {
        let upButton = UIBarButtonItem(title: "\u{f062}", style: .plain, target: self, action: #selector(upAction(_:)))
        upButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : tintColor,], for: .normal)
        return upButton
        }
    }
    
    var downButton: UIBarButtonItem {
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration(pointSize: fontSize, weight: .regular)
            return UIBarButtonItem(image: UIImage(systemName: "arrow.down")!.withConfiguration(configuration), style: .plain, target: self, action: #selector(downAction(_:)))
        } else {
        let downButton = UIBarButtonItem(title: "\u{f063}", style: .plain, target: self, action: #selector(downAction(_:)))
        downButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : tintColor,], for: .normal)
        return downButton
        }
    }
    
    var runButton: UIBarButtonItem {
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration(pointSize: fontSize, weight: .regular)
            return UIBarButtonItem(image: UIImage(systemName: "forward.end")!.withConfiguration(configuration), style: .plain, target: self, action: #selector(runAction(_:)))
        } else {
        let runButton = UIBarButtonItem(title: "\u{f051}", style: .plain, target: self, action: #selector(runAction(_:)))
        runButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : tintColor,], for: .normal)
        return runButton
        }
    }
    
    // deprecated
    var stopButton: UIBarButtonItem {
        let stopButton = UIBarButtonItem(title: "\u{f04d}", style: .plain, target: self, action: #selector(stopAction(_:)))
        stopButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : tintColor,], for: .normal)
        return stopButton
    }
    
    var doneButton: UIBarButtonItem {
        // Escape button:
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration(pointSize: fontSize, weight: .regular)
            return UIBarButtonItem(image: UIImage(systemName: "escape")!.withConfiguration(configuration), style: .plain, target: self, action: #selector(escapeKey(_:)))
        } else {
            // "escape" button, using UTF-8
            let doneButton = UIBarButtonItem(title: "␛", style: .plain, target: self, action: #selector(escapeKey(_:)))
            doneButton.setTitleTextAttributes(
                [NSAttributedString.Key.font : UIFont(name: "Apple Symbols", size: 1.8*fontSize)!,
                 NSAttributedString.Key.foregroundColor : tintColor,], for: .normal)
            return doneButton
        }
    }
    
    var pickerDoneButton: UIBarButtonItem {
        // "done" button, localized
        let pickerDoneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: nil, action: #selector(pickerDoneAction(_:)))
        pickerDoneButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "Apple Symbols", size: 1.8*fontSize)!,
             NSAttributedString.Key.foregroundColor : tintColor,], for: .normal)
        return pickerDoneButton
    }
    
    var tabButton: UIBarButtonItem {
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration(pointSize: fontSize, weight: .regular)
            return UIBarButtonItem(image: UIImage(systemName: "arrow.right.to.line.alt")!.withConfiguration(configuration), style: .plain, target: self, action: #selector(autocompleteAction(_:)))
        } else {
        // "tab" button, using UTF-8
        let tabButton = UIBarButtonItem(title: "⇥", style: .plain, target: self, action: #selector(autocompleteAction(_:)))
        // UIFont.systemFont(ofSize: 1.5*fontSize),
        tabButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 1.8*fontSize),
             NSAttributedString.Key.foregroundColor : tintColor], for: .normal)
        return tabButton
        }
    }
    var shiftTabButton: UIBarButtonItem {
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration(pointSize: fontSize, weight: .regular)
            return UIBarButtonItem(image: UIImage(systemName: "arrow.left.to.line.alt")!.withConfiguration(configuration), style: .plain, target: self, action: #selector(shiftTabAction(_:)))
        } else {
        // "shift-tab" button, using UTF-8
        let shiftTabButton = UIBarButtonItem(title: "⇤", style: .plain, target: self, action: #selector(shiftTabAction(_:)))
        shiftTabButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 1.8*fontSize),
             NSAttributedString.Key.foregroundColor : tintColor,], for: .normal)
        return shiftTabButton
        }
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
        if (notebookCellInsertMode) {
            // this is the easy way:
            webView.evaluateJavaScript("var event = new KeyboardEvent('keydown', {which:13, keyCode:13, bubbles:true});  Jupyter.notebook.get_selected_cell().completer.keydown(event);") { (result, error) in
                if error != nil {
                    // print(error)
                }
                if (result != nil) {
                    // print(result)
                }
            }
        } else {
            // This is the hard way, but sometime we can't avoid it
            contentView?.endEditing(false)
        }
    }
    
    @objc func prepareFirstKeyboard() {
        // Must be identical to code in keyboardDidChange()
        // This will only apply to the first keyboard. We have to register a callback for
        // the other keyboards.
        // Notebooks:
        // escape, tab, shift tab, undo, redo, save, add, cut, copy, paste //  up, down, run.
        // Other views (including edit):
        // undo, redo, save // cut, copy, paste.
        
        // When prepareFirstKeyboard, we have presentedItemURL (and not always) but not kernelURL
        let filePath = presentedItemURL?.path
        // Prepare the full extended keyboard for notebooks.
        // If the user is browsing a directory, the first notebook opened will be displayed with this keyboard. We use the full keyboard for this.
        // This function is called early, and the directory may not yet have permission (in which case isDirectory is false, even for a directory)
        // For this, we use .hasSuffix("/"). For the same reason, we don't have kernelURL available yet.
        if (filePath?.hasSuffix(".ipynb") ?? false) || (filePath?.hasSuffix(".py") ?? false) || (presentedItemURL?.isDirectory ?? false) || (filePath?.hasSuffix("/") ?? false){
            if ((externalKeyboardPresent ?? false) || !(multiCharLanguageWithSuggestions ?? false)) {

                var leadingButtons: [UIBarButtonItem] =  [doneButton]
                if (needTabKey && !(externalKeyboardPresent ?? false)) {
                    // no need for a tab key if there is an external keyboard
                    leadingButtons.append(tabButton)
                }
                leadingButtons.append(shiftTabButton)
                leadingButtons.append(undoButton)
                leadingButtons.append(redoButton)
                if #available(iOS 13.0, *) { } else {
                    leadingButtons.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil))
                }
                leadingButtons.append(saveButton)
                leadingButtons.append(addButton)
                
                // We need "representativeItem: nil" otherwise iOS compress the buttons into the representative item
                contentView?.inputAssistantItem.leadingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
                    leadingButtons, representativeItem: nil)]
                contentView?.inputAssistantItem.trailingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
                    [cutButton, copyButton, pasteButton, upButton, downButton, runButton], representativeItem: nil)]
            } else {
                // We writing in Hindi, Chinese or Japanese. The keyboard uses a large place in the center for suggestions.
                // We can only put 3 buttons on each side:
                // TODO: could we keep the full set of buttons on large iPads (11 inch and more)
                contentView?.inputAssistantItem.leadingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
                    [undoButton, redoButton, runButton], representativeItem: nil)]
                contentView?.inputAssistantItem.trailingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
                    [cutButton, copyButton, pasteButton], representativeItem: nil)]
            }
        } else {
            // Directory or edit text files. Only these buttons make sense
            contentView?.inputAssistantItem.leadingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
                [undoButton, redoButton, saveButton], representativeItem: nil)]
            contentView?.inputAssistantItem.trailingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
                [cutButton, copyButton, pasteButton], representativeItem: nil)]
        }

    }
    
    @objc func goBackAction(_ sender: UIBarButtonItem) {
        if self.webView.canGoBack {
            var position = -1
            var backPageItem = self.webView.backForwardList.item(at: position)
            while ((backPageItem != nil) && (backPageItem?.url != nil) && ((backPageItem?.url.sameLocation(url: self.webView.url))! || skippedURLs.contains(backPageItem!.url))) {
                if let index = skippedURLs.firstIndex(of: backPageItem!.url) {
                    skippedURLs.remove(at: index)
                }
                position -= 1
                backPageItem = self.webView.backForwardList.item(at: position)
            }
            if (backPageItem != nil) {
                self.webView.go(to: backPageItem!)
                return
            }
        }
        // Nothing left in history, so we open the file server:
        guard var treeAddress = serverAddress else { return }
        treeAddress = treeAddress.appendingPathComponent("tree")
        self.webView.load(URLRequest(url: treeAddress))
    }
    
    @objc func goForwardAction(_ sender: UIBarButtonItem) {
        if self.webView.canGoForward {
            var position = 1
            var forwardPageItem = self.webView.backForwardList.item(at: position)
            while ((forwardPageItem != nil) && (forwardPageItem?.url != nil) && ((forwardPageItem?.url.sameLocation(url: self.webView.url))!)) {
                position += 1
                forwardPageItem = self.webView.backForwardList.item(at: position)
            }
            if (forwardPageItem != nil) {
                self.webView.go(to: forwardPageItem!)
                return
            }
        }
    }
    
    var backButton: UIBarButtonItem {
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration(pointSize: fontSize, weight: .bold)
            let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left")!.withConfiguration(configuration), style: .plain, target: self, action: #selector(goBackAction(_:)))
            backButton.tintColor = .systemBlue
            return backButton
        } else {
        let backButton = UIBarButtonItem(title: "\u{f053}", style: .plain, target: self, action: #selector(goBackAction(_:)))
        backButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.systemBlue,], for: .normal)
        return backButton
        }
    }

    var forwardButton: UIBarButtonItem {
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration(pointSize: fontSize, weight: .bold)
            let forwardButton = UIBarButtonItem(image: UIImage(systemName: "chevron.right")!.withConfiguration(configuration), style: .plain, target: self, action: #selector(goForwardAction(_:)))
            forwardButton.tintColor = .systemBlue
            return forwardButton
        } else {
        let forwardButton = UIBarButtonItem(title: "\u{f054}", style: .plain, target: self, action: #selector(goForwardAction(_:)))
        forwardButton.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
             NSAttributedString.Key.foregroundColor : UIColor.systemBlue,], for: .normal)
        return forwardButton
        }
    }

    @objc func openWebPage(_ sender: UIBarButtonItem) {
        // User wants to browse the web to look for answers
        // TODO:
        // open alert, get address. If address is not URL, add http://
        // if still not URL, open in search engine. Search engine customizable in preferences.
        let alertController = UIAlertController(title: "Open web page", message: "Enter search term or website:", preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.text = ""
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
        }))
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if let text = alertController.textFields?.first?.text {
                var url = URL(string: text)
                if !UIApplication.shared.canOpenURL(url! as URL) {
                    // No valid schemes.
                    url = URL(string: "https://" + text)
                }
                let host = url!.host
                let address = gethostbyname(host)
                if address != nil {
                    self.webView.load(URLRequest(url: url!))
                } else {
                    let searchEngine = UserDefaults.standard.string(forKey: "search_engine") ?? "https://docs.python.org/3/search.html?q="
                    if let url = URL(string: searchEngine + text) {
                        self.webView.load(URLRequest(url: url))
                    }
                }
            }
        }))
        
        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = self.view
        }
        self.present(alertController, animated: true, completion: nil)
    }

    
    var safariButton: UIBarButtonItem {
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration(pointSize: fontSize, weight: .bold)
            let forwardButton = UIBarButtonItem(image: UIImage(systemName: "safari")!.withConfiguration(configuration), style: .plain, target: self, action: #selector(openWebPage(_:)))
            forwardButton.tintColor = .systemBlue
            return forwardButton
        } else {
            let forwardButton = UIBarButtonItem(title: "\u{f267}", style: .plain, target: self, action: #selector(goForwardAction(_:)))
            forwardButton.setTitleTextAttributes(
                [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
                 NSAttributedString.Key.foregroundColor : UIColor.systemBlue,], for: .normal)
            return forwardButton
        }
    }
    
    var unlockFolderButton: UIBarButtonItem {
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration(pointSize: fontSize, weight: .bold)
            let forwardButton = UIBarButtonItem(image: UIImage(named: "custom.unlock.folder")!.withConfiguration(configuration), style: .plain, target: self, action: #selector(pickFolder(_:)))
            forwardButton.tintColor = .systemBlue
            return forwardButton
        } else {
            let forwardButton = UIBarButtonItem(title: "\u{f07c}", style: .plain, target: self, action: #selector(goForwardAction(_:)))
            forwardButton.setTitleTextAttributes(
                [NSAttributedString.Key.font : UIFont(name: "FontAwesome", size: fontSize)!,
                 NSAttributedString.Key.foregroundColor : UIColor.systemBlue,], for: .normal)
            return forwardButton
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        // Add navigation bar at the top: back, title, forward
        if #available(iOS 13, *) {
            navigationController?.navigationBar.tintColor = UIColor.placeholderText.resolvedColor(with: traitCollection)
            if (darkMode) {
                navigationController?.navigationBar.backgroundColor = UIColor(hexString: "#2b303b")
                navigationController?.navigationBar.barTintColor = UIColor(hexString: "#2b303b")
            } else {
                // navigationController?.navigationBar.backgroundColor = UIColor.systemBackground.resolvedColor(with: traitCollection)
                navigationController?.navigationBar.backgroundColor = UIColor(hexString: "#f8f8f8")
                navigationController?.navigationBar.barTintColor = UIColor(hexString: "#f8f8f8")
            }
        }
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = backButton
        navigationItem.rightBarButtonItems = [forwardButton, unlockFolderButton, safariButton]
        navigationController?.navigationBar.isHidden = false
        navigationController?.hidesBarsOnSwipe = true
        navigationController?.navigationBar.isTranslucent = false // isTranslucent plays with the color, and it doesn't match the rest of the UI
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
        var UrlRequest = URLRequest(url: kernelURL!)
        UrlRequest.setValue(serverAddress.absoluteString, forHTTPHeaderField: "Referer")
        webView.load(UrlRequest)
    }
    
    @objc private func autocompleteAction(_ sender: UIBarButtonItem) {
        // edit mode autocomplete
        // Create a "tab" keydown event. Either autocomplete or indent code
        // TODO: if shift is selected on keyboard, un-indent code (and remove shiftTabAction)
        if (notebookCellInsertMode) {
            webView.evaluateJavaScript("var event = new KeyboardEvent('keydown', {which:9, keyCode:9, bubbles:true}); if (!Jupyter.notebook.get_selected_cell().handle_keyevent(Jupyter.notebook.get_selected_cell().code_mirror, event)) { Jupyter.notebook.get_selected_cell().code_mirror.execCommand('defaultSoftTab');} ") { (result, error) in
                if error != nil {
                    // print(error)
                }
                if (result != nil) {
                    // print(result)
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
                    // print(error)
                }
                if (result != nil) {
                    // print(result)
                }
            }
        }
    }
    
    @objc private func cutAction(_ sender: UIBarButtonItem) {
        // edit mode cut (works)
        webView.evaluateJavaScript("document.execCommand('cut');") { (result, error) in
            if error != nil {
                // print(error)
            }
            if (result != nil) {
                // print(result)
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
                // print(error)
            }
            if (result != nil) {
                // print(result)
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
                    // print(error)
                }
                if (result != nil) {
                    // print(result)
                }
            }
        } else {
            webView.evaluateJavaScript("Jupyter.editor.save();") { (result, error) in
                if error != nil {
                    // print(error)
                }
                if (result != nil) {
                    // print(result)
                }
            }
        }
    }
    
    // For add cell and run cell: we keep the notebook in edit mode, otherwise the keyboard will disappear
    @objc private func addAction(_ sender: UIBarButtonItem) {
        if (notebookCellInsertMode) {
            webView.evaluateJavaScript("Jupyter.notebook.insert_cell_below(); Jupyter.notebook.select_next(true); Jupyter.notebook.focus_cell(); Jupyter.notebook.edit_mode();") { (result, error) in
                if error != nil {
                    // print(error)
                }
                if (result != nil) {
                    // print(result)
                }
            }
        }
    }
    
    @objc func runAction(_ sender: UIBarButtonItem) {
        if (notebookCellInsertMode) {
            webView.evaluateJavaScript("Jupyter.notebook.execute_cell_and_select_below(); Jupyter.notebook.edit_mode();") { (result, error) in
                if error != nil {
                    // print(error)
                }
                if (result != nil) {
                    // print(result)
                }
            }
        }
    }
    
    @objc func runSingleCell(_ sender: UIBarButtonItem) {
        if (notebookCellInsertMode) {
            webView.evaluateJavaScript("Jupyter.notebook.execute_cell(); Jupyter.notebook.edit_mode();") { (result, error) in
                if error != nil {
                    // print(error)
                }
                if (result != nil) {
                    // print(result)
                }
            }
        }
    }

    @objc private func upAction(_ sender: UIBarButtonItem) {
        if (notebookCellInsertMode) {
            webView.evaluateJavaScript("Jupyter.notebook.select_prev(true); Jupyter.notebook.focus_cell(); Jupyter.notebook.edit_mode();") { (result, error) in
                if error != nil {
                    // print(error)
                }
                if (result != nil) {
                    // print(result)
                }
            }
        }
    }
    
    @objc private func downAction(_ sender: UIBarButtonItem) {
        if (notebookCellInsertMode) {
            webView.evaluateJavaScript("Jupyter.notebook.select_next(true); Jupyter.notebook.focus_cell(); Jupyter.notebook.edit_mode();") { (result, error) in
                if error != nil {
                    // print(error)
                }
                if (result != nil) {
                    // print(result)
                }
            }
        }
    }
    
    @objc private func stopAction(_ sender: UIBarButtonItem) {
        // Does not work. Also, not desireable.
        if (notebookCellInsertMode) {
            webView.evaluateJavaScript("Jupyter.notebook.kernel.interrupt();") { (result, error) in
                if error != nil {
                    // print(error)
                }
                if (result != nil) {
                    // print(result)
                }
            }
        }
    }
    
    @objc func undoAction(_ sender: UIBarButtonItem) {
        // works
        if (notebookCellInsertMode) {
            webView.evaluateJavaScript("Jupyter.notebook.get_selected_cell().code_mirror.execCommand('undo');") { (result, error) in
                if error != nil {
                    // print(error)
                }
                if (result != nil) {
                    // print(result)
                }
            }
        } else {
            webView.evaluateJavaScript("Jupyter.editor.codemirror.execCommand('undo');") { (result, error) in
                if error != nil {
                    // print(error)
                }
                if (result != nil) {
                    // print(result)
                }
            }
        }
    }
    
    @objc func redoAction(_ sender: UIBarButtonItem) {
        // works
        if (notebookCellInsertMode) {
            webView.evaluateJavaScript("Jupyter.notebook.get_selected_cell().code_mirror.execCommand('redo');") { (result, error) in
                if error != nil {
                    // print(error)
                }
                if (result != nil) {
                    // print(result)
                }
            }
        } else {
            webView.evaluateJavaScript("Jupyter.editor.codemirror.execCommand('redo');") { (result, error) in
                if error != nil {
                    // print(error)
                }
                if (result != nil) {
                    // print(result)
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
        let keyboardLanguage = contentView?.textInputMode?.primaryLanguage
        if (keyboardLanguage != nil) {
            // TODO: currently, we have no way to distinguish between Hindi and Hindi-Transliteration.
            // We treat them the same until we have a way to separate.
            // Is the keyboard language one of the multi-input language? Chinese, Japanese, Korean and Hindi-Transliteration
            // keyboardLanguage = "hi" -- not enough
            // keyboardLanguage = "zh-": all of them
            // keyboardLanguage = "jp-": all of them
            NSLog("Called keyboardDidChange, language=\(keyboardLanguage)")
            if (keyboardLanguage!.hasPrefix("hi") || keyboardLanguage!.hasPrefix("zh") || keyboardLanguage!.hasPrefix("ja")) {
                multiCharLanguageWithSuggestions = true
                NSLog("Called keyboardDidChange, setting=\(multiCharLanguageWithSuggestions)")
                if (UIDevice.current.systemVersionMajor < 13) {
                    // fix a Javascript issue in iOS versions before 13.
                    webView.evaluateJavaScript("iOS_multiCharLanguage = true;") { (result, error) in
                        if error != nil {
                            // print(error)
                        }
                    }
                }
            } else {
                // otherwise return false:
                multiCharLanguageWithSuggestions = false
                NSLog("Called keyboardDidChange, setting=\(multiCharLanguageWithSuggestions)")
                if (UIDevice.current.systemVersionMajor < 13) {
                    webView.evaluateJavaScript("iOS_multiCharLanguage = false;") { (result, error) in
                        if error != nil {
                            // print(error)
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
                if let keyboardFrame: CGRect = (info![UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
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
            }
            if (selectorActive) {
                // a picker is active: display only one button, with "Done". Only needed on iPhones
                self.editorToolbar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
                                            pickerDoneButton]
            } else if (kernelURL!.path.hasPrefix("/notebooks") || kernelURL!.path.hasPrefix("/tree")) {
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
            if let keyboardFrame: CGRect = (info![UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                externalKeyboardPresent = keyboardFrame.size.height < 60
            }
        }
                
        if (kernelURL!.path.hasPrefix("/notebooks") || kernelURL!.path.hasPrefix("/tree")) {
            if ((externalKeyboardPresent ?? false) || !(multiCharLanguageWithSuggestions ?? false)) {
                var leadingButtons: [UIBarButtonItem] =  [doneButton]
                if (needTabKey && !(externalKeyboardPresent ?? false)) {
                    // no need for a tab key if there is an external keyboard
                    leadingButtons.append(tabButton)
                }
                leadingButtons.append(shiftTabButton)
                leadingButtons.append(undoButton)
                leadingButtons.append(redoButton)
                if #available(iOS 13.0, *) { } else {
                    leadingButtons.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil))
                }
                leadingButtons.append(saveButton)
                leadingButtons.append(addButton)
                addButton.tintColor = .black
                // We need "representativeItem: nil" otherwise iOS compress the buttons into the representative item
                contentView?.inputAssistantItem.leadingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
                    leadingButtons, representativeItem: nil)]
                contentView?.inputAssistantItem.trailingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems:
                    [cutButton, copyButton, pasteButton, upButton, downButton, runButton], representativeItem: nil)]
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
