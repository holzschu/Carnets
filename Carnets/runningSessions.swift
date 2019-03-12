//
//  runningSessions.swift
//  Carnets
//
//  Created by Nicolas Holzschuch on 12/03/2019.
//  Copyright © 2019 AsheKube. All rights reserved.
//
// Keeping track of the Jupyter sessions running in parallel


import Foundation

var runningSessions: [String: Date] = [:]

func clearAllRunningSessions() {
    runningSessions.removeAll(keepingCapacity: true)
}

func numberOfRunningSessions() -> Int {
    return runningSessions.count
}

func addRunningSession(session: String) {
    var key = session
    key.removeFirst("loadingSession:".count)
    if (key.hasPrefix("/")) {
        key = String(key.dropFirst())
    }
    runningSessions.updateValue(Date(), forKey: key)
}

func removeRunningSession(session: String) {
    var key = session
    if (key.hasPrefix("killingSession:")) {
        key.removeFirst("killingSession:".count)
    }
    if (key.hasPrefix("/")) {
        key = String(key.dropFirst())
    }
    if (runningSessions.removeValue(forKey: key) == nil) {
        NSLog("Warning - removing notebook that was not started: \(key)")
    }
}

func oldestRunningSession() -> String {
    var oldestSessionTime = Date()
    var oldestSessionID: String!
    for (sessionID, date) in runningSessions {
        if (date < oldestSessionTime) {
            oldestSessionTime = date
            oldestSessionID = sessionID
        }
    }
    NSLog("Oldest session found: \(oldestSessionID)")
    return oldestSessionID
}
