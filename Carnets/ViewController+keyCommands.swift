//
//  ViewController+keyCommands.swift
//  Carnets
//
//  Created by Nicolas Holzschuch on 22/05/2019.
//  Copyright © 2019 AsheKube. All rights reserved.
//

import Foundation
import UIKit
import WebKit

extension ViewController {
    
    
    // This works in text-input mode:
    @objc func escapeKey(_ sender: UIBarButtonItem) {
        webView.evaluateJavaScript("Jupyter.notebook.command_mode();") { (result, error) in
            if error != nil {
                // print(error)
            }
            if (result != nil) {
                // print(result)
            }
        }
    }
    
    @objc private func pasteAction() {
        if (notebookCellInsertMode) {
            // edit mode paste (works)
            if let pastedString = UIPasteboard.general.string {
                webView.paste(pastedString)
            }
        } else {
            // command mode paste (works)
            webView.evaluateJavaScript("Jupyter.notebook.paste_cell_below();") { (result, error) in
                if error != nil {
                    print(error)
                    print(result)
                }
            }
        }
    }

    @objc private func copyAction() {
        if (notebookCellInsertMode) {
            // edit mode copy (works)
            webView.evaluateJavaScript("document.execCommand('copy');") { (result, error) in
                if error != nil {
                    // print(error)
                }
                if (result != nil) {
                    // print(result)
                }
            }
        } else {
            // command mode copy (works)
            // javascript code to copy cell
            webView.evaluateJavaScript("Jupyter.notebook.copy_cell();") { (result, error) in
                if error != nil {
                    print(error)
                    print(result)
                }
            }
        }
    }

    @objc private func cutAction() {
        // edit mode cut (works)
        if (notebookCellInsertMode) {
            webView.evaluateJavaScript("document.execCommand('cut');") { (result, error) in
                if error != nil {
                    print(error)
                }
                if (result != nil) {
                    print(result)
                }
            }
        } else {
            // command mode cut (works)
            webView.evaluateJavaScript("var index = Jupyter.notebook.get_selected_index(); Jupyter.notebook.cut_cell(); Jupyter.notebook.select(index);"){ (result, error) in
                if error != nil {
                    print(error)
                    print(result)
                }
            }
        }
    }

    override var keyCommands: [UIKeyCommand]? {
        var basicKeyCommands = [
            UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(escapeKey), discoverabilityTitle: "Escape Key"),
            // Cmd-Z works on iOS 15b2
            UIKeyCommand(input: "z", modifierFlags: .command, action: #selector(undoAction),  discoverabilityTitle: "Undo"),
            UIKeyCommand(input: "z", modifierFlags: [.command, .shift], action: #selector(redoAction), discoverabilityTitle: "Redo"),
            // control-Z is available
            UIKeyCommand(input: "z", modifierFlags: .control, action: #selector(undoAction), discoverabilityTitle: "Undo"),
            UIKeyCommand(input: "z", modifierFlags: [.control, .shift], action: #selector(redoAction), discoverabilityTitle: "Redo"),
            // Cmd-S is not reserved, so this works:
            UIKeyCommand(input: "s", modifierFlags: .command, action: #selector(saveAction), discoverabilityTitle: "Save"),
            UIKeyCommand(input: "x", modifierFlags: .command, action: #selector(cutAction), discoverabilityTitle: "Cut"),
            UIKeyCommand(input: "c", modifierFlags: .command, action: #selector(copyAction), discoverabilityTitle: "Copy"),
            UIKeyCommand(input: "v", modifierFlags: .command, action: #selector(pasteAction), discoverabilityTitle: "Paste"),
            // Ctrl-Enter: does not work (intercepted/not seen by JS)
            // Alt-Enter: managed by JS
            // Shift-Enter: managed by JS
            // Cmd-Enter: run cell (but not insert below) (run runSingleCell)
            UIKeyCommand(input: "\r", modifierFlags:.command,  action: #selector(runSingleCell), discoverabilityTitle: "Run cell"),
            // Tab key in edit mode: does not work with external keyboard (but alt-tab works). But it should ("\t")
        ]
        /* Caps Lock remapped to escape -- only if in a notebook, in insert mode: */
        if (UserDefaults.standard.bool(forKey: "escape_preference") && notebookCellInsertMode) {
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
            // This one remaps capslock to escape, no discoverabilityTitle
            basicKeyCommands.append(UIKeyCommand(input: "", modifierFlags:.alphaShift,  action: #selector(escapeKey)))
        }
        return basicKeyCommands
    }
    
    // Even if Caps-Lock is activated, send lower case letters.
    @objc func insertKey(_ sender: UIKeyCommand) {
        guard (sender.input != nil) else { return }
        // This function only gets called if we are in a notebook, in edit_mode:
        // Only remap the keys if we are in a notebook, editing cell:
        let commandString = "Jupyter.notebook.get_selected_cell().code_mirror.replaceSelection('\(sender.input!)');"
        self.webView.evaluateJavaScript(commandString) { (result, error) in
            if error != nil {
                print(error)
                print(result)
            }
        }
    }
}
