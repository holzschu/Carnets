//
//  DocumentBrowserViewController.swift
//  Carnets
//
//  Created by Nicolas Holzschuch on 11/03/2019.
//  Copyright © 2019 AsheKube. All rights reserved.
//

import UIKit


class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        
        allowsDocumentCreation = true
        allowsPickingMultipleItems = true
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let documentViewController = storyBoard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        documentViewController.modalPresentationStyle = UIModalPresentationStyle.fullScreen;
        
        let lastPageVisited = UserDefaults.standard.url(forKey: "lastOpenUrl")

        // Reopen where we were last time, but only if it is a notebook:
        if (lastPageVisited != nil) && (lastPageVisited!.path != "/tree")
            && lastPageVisited!.isFileURL && lastPageVisited!.path.hasPrefix("/notebooks") {
            documentViewController.presentedItemURL = lastPageVisited
            NSFileCoordinator.addFilePresenter(documentViewController)
            // print("presentedItemURL (DocumentBrowserViewController) = \(documentViewController.presentedItemURL)")
            present(documentViewController, animated: true, completion: nil)
        }

        // let types = [kUTTypeText as String, kUTTypeDirectory as String]
        // Update the style of the UIDocumentBrowserViewController
        // browserUserInterfaceStyle = .dark
        // view.tintColor = .white
        
        // Specify the allowed content types of your application via the Info.plist.
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    
    // MARK: UIDocumentBrowserViewControllerDelegate
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {

        // Set the URL for the new document here. Optionally, you can present a template chooser before calling the importHandler.
        let temporaryDirectoryURL = try! FileManager().url(for: .itemReplacementDirectory,
                                                           in: .userDomainMask,
                                                           appropriateFor: URL(fileURLWithPath: documentsPath!),
                                                           create: true)
        var temporaryFileURL = temporaryDirectoryURL
        temporaryFileURL.appendPathComponent("Untitled.ipynb")
        let newFileContent = """
{
  "cells": [
    {
      "cell_type": "code",
      "execution_count": null,
      "metadata": {},
      "outputs": [],
      "source": []
    }
  ],
  "metadata": {
    "kernelspec": {
      "display_name": "Python 3",
      "language": "python",
      "name": "python3"
    },
    "language_info": {
      "codemirror_mode": {
        "name": "ipython",
        "version": 3
      },
      "file_extension": ".py",
      "mimetype": "text/x-python",
      "name": "python",
      "nbconvert_exporter": "python",
      "pygments_lexer": "ipython3",
      "version": "3.7.1"
    }
  },
  "nbformat": 4,
  "nbformat_minor": 2
}
"""
        let newFileData: Data = newFileContent.data(using: String.Encoding.utf8)!
        // Create an empty document here:
        if (!FileManager().createFile(atPath: temporaryFileURL.path, contents: newFileData, attributes: nil)) {
            // file creation failed:
            importHandler(nil, .none)
        }
        importHandler(temporaryFileURL, .move)
        // Note: we cannot delete the temporary directory, otherwise the file opening fails.
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        // Present the Document View Controller for the first document that was picked.
        // If you support picking multiple items, make sure you handle them all.
        /* for sourceURL in documentURLs {
            print("didPickDocumentsAt, presenting document: \(sourceURL)")
            presentDocument(at: sourceURL)
            // TODO: wait until document is fully loaded. 
        } */
        guard let sourceURL = documentURLs.first else { return }
        presentDocument(at: sourceURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        // Present the Document View Controller for the new newly created document
        presentDocument(at: destinationURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
    }
    
    // MARK: Document Presentation
    
    func presentDocument(at documentURL: URL) {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let documentViewController = storyBoard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        documentViewController.modalPresentationStyle = UIModalPresentationStyle.fullScreen;

        documentViewController.presentedItemURL = documentURL
        NSFileCoordinator.addFilePresenter(documentViewController)
        notebookViewerActive = true
        // print("presentedItemURL (DocumentBrowserViewController presentDocument) = \(documentViewController.presentedItemURL)")
        UserDefaults.standard.set(documentURL, forKey: "lastOpenUrl")
        let navigationController = UINavigationController(rootViewController: documentViewController)
        navigationController.modalPresentationStyle = UIModalPresentationStyle.fullScreen;
        present(navigationController, animated: true, completion: nil)
        // present(documentViewController, animated: true, completion: nil)
    }
}

