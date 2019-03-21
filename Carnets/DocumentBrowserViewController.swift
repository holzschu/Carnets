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
        let lastPageVisited = UserDefaults.standard.url(forKey: "lastOpenUrl")

        if (lastPageVisited != nil) && (lastPageVisited!.path != "/tree") {
            notebookURL = lastPageVisited
            present(documentViewController, animated: true, completion: nil)
        }

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
                                                           appropriateFor: URL(fileURLWithPath: startingPath!),
                                                           create: true)
        var temporaryFileURL = temporaryDirectoryURL
        temporaryFileURL.appendPathComponent("Untitled.ipynb")
        let newFileContent = "{\n\"cells\": [\n{\n\"cell_type\": \"code\",\n\"execution_count\": null,\n\"metadata\": {},\n\"outputs\": [],\n\"source\": []\n}\n],\n\"metadata\": {\n\"kernelspec\": {\n\"display_name\": \"Python 3\",\n\"language\": \"python\",\n\"name\": \"python3\"\n},\n\"language_info\": {\n\"codemirror_mode\": {\n\"name\": \"ipython\",\n\"version\": 3\n},\n\"file_extension\": \".py\",\n\"mimetype\": \"text/x-python\",\n\"name\": \"python\",\n\"nbconvert_exporter\": \"python\",\n\"pygments_lexer\": \"ipython3\",\n\"version\": \"3.7.1\"\n}\n},\n\"nbformat\": 4,\n\"nbformat_minor\": 2\n}"
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
        // This may be causing issues with non-UTF8 systems.
        // if (!documentURL.path.hasSuffix(".ipynb")) { return }
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let documentViewController = storyBoard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        notebookURL = documentURL
        UserDefaults.standard.set(documentURL, forKey: "lastOpenUrl")
        present(documentViewController, animated: true, completion: nil)
    }
}

