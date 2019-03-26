//
//  Document.swift
//  Carnets
//
//  Created by Nicolas Holzschuch on 11/03/2019.
//  Copyright © 2019 AsheKube. All rights reserved.
//

import UIKit
import WebKit

class Document: UIDocument {
    
    /* override func contents(forType typeName: String) throws -> Any {
        // Encode your document with an instance of NSData or NSFileWrapper
        return Data()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load your document from contents
    } */
    
    override func fileAttributesToWrite(to url: URL, for saveOperation: UIDocument.SaveOperation) throws -> [AnyHashable : Any] {
        // let thumbnailSize = CGSize(width: 1024, height: 1024)
        NSLog("Called fileAttributesToWrite")
        // save WkWebView to image:
        let configuration = WKSnapshotConfiguration()
        configuration.rect = CGRect(origin: .zero, size: appWebView.scrollView.contentSize)
        configuration.snapshotWidth = 1024
        var myImage: UIImage?
        appWebView.takeSnapshot(with: configuration, completionHandler: { image, error in
            if let image = image {
                myImage = image
                print("Got snapshot")
            } else {
                print("Failed taking snapshot: \(error?.localizedDescription ?? "--")")
            }
        })

        guard (myImage != nil) else {return [:]}
        return [URLResourceKey.hasHiddenExtensionKey : true,
                URLResourceKey.thumbnailDictionaryKey : [URLThumbnailDictionaryItem.NSThumbnail1024x1024SizeKey : myImage]]
    }
}

