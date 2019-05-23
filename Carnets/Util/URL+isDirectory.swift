//
//  URL+isDirectory.swift
//  Carnets
//
//  Created by Anders Borum on 22/06/2017.
//  Copyright © 2017 Applied Phasor. All rights reserved.
//

import Foundation

extension URL {
    // shorthand to check if URL is directory
    public var isDirectory: Bool {
        let keys = Set<URLResourceKey>([URLResourceKey.isDirectoryKey])
        let value = try? self.resourceValues(forKeys: keys)
        switch value?.isDirectory {
        case .some(true):
            return true
            
        default:
            return false
        }
    }
}

