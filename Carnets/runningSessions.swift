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
    runningSessions.updateValue(Date(), forKey: session)
}

func removeRunningSession(session: String) {
    if (runningSessions.removeValue(forKey: session) == nil) {
        NSLog("Warning - removing notebook that was not started: \(session)")
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
    NSLog("Oldest session found: %s", oldestSessionID)
    let range = oldestSessionID.startIndex..<oldestSessionID.firstIndex(of: "S")!
    let key = oldestSessionID.replacingCharacters(in: range, with: "loading")
    oldestSessionID.removeFirst("loadingSession:".count)
    if (oldestSessionID!.hasPrefix("/")) {
        oldestSessionID = String(oldestSessionID!.dropFirst())
    }
    return oldestSessionID
}
