//
//  runningSessions.swift
//  Carnets
//
//  Created by Nicolas Holzschuch on 12/03/2019.
//  Copyright © 2019 AsheKube. All rights reserved.
//
// Keeping track of the Jupyter sessions running in parallel


import Foundation

// stores the strings "api/sessions/9ba846bc-555c-45ba-bf6c-88a0eb70e3b8" associated with URL loaded
var runningSessions: [URL: String] = [:]
// stores the URL with date of access:
var sessionAccessTime: [URL: Date] = [:]

func clearAllRunningSessions() {
    runningSessions.removeAll(keepingCapacity: true)
    sessionAccessTime.removeAll(keepingCapacity: true)
}

func numberOfRunningSessions() -> Int {
    return runningSessions.count
}

func addRunningSession(session: String, url: URL) {
    var sessionID = session
    sessionID.removeFirst("loadingSession:".count)
    if (sessionID.hasPrefix("/")) {
        sessionID = String(sessionID.dropFirst())
    }
    // print("Storing session url: \(url).")
    runningSessions.updateValue(sessionID, forKey: url)
    sessionAccessTime.updateValue(Date(), forKey: url)
}

func removeRunningSession(url: URL) {
    // print("Removing session url: \(url)")
    if (runningSessions.removeValue(forKey: url) == nil) {
        NSLog("Warning - removing notebook that was not started: \(url)")
    }
    if (sessionAccessTime.removeValue(forKey: url) == nil) {
        NSLog("Warning - removing sessionTime that was not stored: \(url)")
    }
}

func removeRunningSessionWithID(session: String) {
    NSLog("Removing sessionID: \(session)")
    for (url, sessionID) in runningSessions {
        if (sessionID == session) {
            runningSessions.removeValue(forKey: url)
            sessionAccessTime.removeValue(forKey: url)
            return
        }
    }
    NSLog("Could not find a URL associated with session ID: \(session)")
}

func oldestRunningSessionURL() -> URL? {
    var oldestSessionTime = Date()
    var sessionURL: URL?
    for (url, date) in sessionAccessTime {
        if (date < oldestSessionTime) {
            oldestSessionTime = date
            sessionURL = url
        }
    }
    NSLog("Oldest session found: \(sessionURL)")
    return sessionURL
}

func closeSession(session: String, url: URL) {
    let urlDelete = serverAddress!.appendingPathComponent(session)
    var urlDeleteRequest = URLRequest(url: urlDelete)
    urlDeleteRequest.httpMethod = "DELETE"
    urlDeleteRequest.setValue("json", forHTTPHeaderField: "dataType")
    let task = URLSession.shared.dataTask(with: urlDeleteRequest) { data, response, error in
        if let error = error {
            NSLog ("Error on DELETE: \(error)") // Could not delete the session
            return
        }
        guard let response = response as? HTTPURLResponse,
            (200...299).contains(response.statusCode) else {
                removeRunningSession(url: url) // session not found. Probably renamed.
                NSLog ("Server error on DELETE")
                return
        }
        removeRunningSession(url: url)
    }
    task.resume()
}

func closeAllRunningSessions() {
    for (url, sessionID) in runningSessions {
        NSLog("Calling closeSession on \(sessionID)")
        closeSession(session: sessionID, url: url)
    }
}


func removeOldestSession() {
    guard var oldestSessionURL = oldestRunningSessionURL() else { return }
    var oldestSessionID = sessionID(url: oldestSessionURL)
    while (oldestSessionID == nil) {
        NSLog("Oldest session URL was not stored. Taking the next one")
        removeRunningSession(url: oldestSessionURL)
        guard let newUrl = oldestRunningSessionURL() else { return }
        oldestSessionURL = newUrl
        oldestSessionID = sessionID(url: oldestSessionURL)
    }
    closeSession(session: oldestSessionID!, url: oldestSessionURL)
}

func sessionID(url: URL) -> String? {
    NSLog("Retrieving ID for: \(url)")
    return runningSessions[url]
}

func setSessionAccessTime(url: URL) {
    if (runningSessions[url] == nil) { return } // Session not yet stored
    NSLog("Set access time for: \(url).")
    sessionAccessTime.updateValue(Date(), forKey: url)
}
