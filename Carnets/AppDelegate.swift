//
//  AppDelegate.swift
//  Carnets
//
//  Created by Nicolas Holzschuch on 26/01/2019.
//  Copyright © 2019 AsheKube. All rights reserved.
//

import UIKit
import ios_system
import UserNotifications

let notificationQuitRequested = "AsheKube.Carnets.quit"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    private let jupyterQueue = DispatchQueue(label: "Jupyter-notebook", qos: .userInteractive) // high priority
    var notebookServerRunning: Bool = false
    var shutdownRequest: Bool = false
    var mustRecompilePythonFiles: Bool = false
    var applicationInBackground: Bool = false
    // shutdown tasks:
    var shutdownTimer: Timer!
    var alertShutdownTimer: Timer!
    var urlShutdownRequest: URLRequest!
    var shutdownTaskIdentifier: UIBackgroundTaskIdentifier!
    
    func copyWelcomeFileToiCloud() {
        // Create a "welcome" document in the iCloud folder.
        // This file has instructions and details.
        // It also forces the iCloud folder to become visible.
        // The "welcome" directory in an On-Demand Resource. It will be downloaded *only* if it's needed.
        DispatchQueue.global().async(execute: {
            iCloudDocumentsURL = FileManager().url(forUbiquityContainerIdentifier: nil)
            if (iCloudDocumentsURL != nil) {
                // Create a document in the iCloud folder to make it visible.
                NSLog("iCloudContainer = \(iCloudDocumentsURL)")
                let iCloudDirectory = iCloudDocumentsURL?.appendingPathComponent("Documents")
                let iCloudDirectoryWelcome = iCloudDirectory?.appendingPathComponent("welcome")
                if (!FileManager().fileExists(atPath: iCloudDirectoryWelcome!.path)) {
                    NSLog("Creating iCloud welcome directory")
                    try! FileManager().createDirectory(atPath: iCloudDirectoryWelcome!.path, withIntermediateDirectories: true)
                    // download the resource from the iTunes store:
                    let libraryBundleResource = NSBundleResourceRequest(tags: ["welcome"])
                    NSLog("Begin downloading welcome resources")
                    var completionHandlerCompleted = false
                    libraryBundleResource.beginAccessingResources(completionHandler: { (error) in
                        if let error = error {
                            var message = "Error in downloading welcome resource: "
                            message.append(error.localizedDescription)
                            NSLog(message)
                        } else {
                            NSLog("Welcome resource succesfully downloaded")
                            let welcomeFiles=["welcome/Welcome to Carnets.ipynb",
                                              "welcome/top.png",
                                              "welcome/bottom.png"]
                            for fileName in welcomeFiles {
                                let welcomeFileLocation = libraryBundleResource.bundle.path(forResource: fileName, ofType: nil)
                                if ((welcomeFileLocation) != nil) {
                                    let iCloudFile = iCloudDirectory?.appendingPathComponent(fileName)
                                    if (!FileManager().fileExists(atPath: iCloudFile!.path) && FileManager().fileExists(atPath: welcomeFileLocation!)) {
                                        print("Copying item from \(welcomeFileLocation) to \(iCloudFile)")
                                        try! FileManager().copyItem(atPath: welcomeFileLocation!, toPath: iCloudFile!.path)
                                    }
                                }
                            }
                        }
                        libraryBundleResource.endAccessingResources()
                    })
                }
            }
        })
    }
    
    
    func needToUpdatePythonFiles() -> Bool {
        // do it with UserDefaults, not storing in files
        UserDefaults.standard.register(defaults: ["versionInstalled" : "0.0"])
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        let currentBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
        let libraryURL = try! FileManager().url(for: .libraryDirectory,
                                                in: .userDomainMask,
                                                appropriateFor: nil,
                                                create: true)
        let libLocation = libraryURL.appendingPathComponent("lib")
        let pythonFilesPresent = FileManager().fileExists(atPath: libLocation.path)
        if (!pythonFilesPresent) {
            return true
        }
        let firstFileLocation = libraryURL.appendingPathComponent("lib/python3.7/zipfile.py")
        do {
            let firstFileAttribute = try FileManager().attributesOfItem(atPath: firstFileLocation.path)
            if (!(firstFileAttribute[FileAttributeKey.type] as? String == FileAttributeType.typeSymbolicLink.rawValue)) { return true }
            let destination = try FileManager().destinationOfSymbolicLink(atPath: firstFileLocation.path)
            if (!FileManager().fileExists(atPath: destination)) { return true }
        }
        catch {
            NSLog("lib/python3.7/zipfile.py generated an error: \(error)")
            return true
        }
        // Python files are present. Which version?
        let currentVersionNumbers = currentVersion.split(separator: ".")
        let majorCurrent = Int(currentVersionNumbers[0])!
        let minorCurrent = Int(currentVersionNumbers[1])!
        let installedVersion = UserDefaults.standard.string(forKey: "versionInstalled")
        let buildNumberInstalled = Int(UserDefaults.standard.string(forKey: "buildNumber") ?? "0")!
        let currentBuildInt = Int(currentBuild)!
        let installedVersionNumbers = installedVersion!.split(separator: ".")
        let majorInstalled = Int(installedVersionNumbers[0])!
        let minorInstalled = Int(installedVersionNumbers[1])!
        return (majorInstalled < majorCurrent) ||
            ((majorInstalled == majorCurrent) && (minorInstalled < minorCurrent)) ||
            ((majorInstalled == majorCurrent) && (minorInstalled == minorCurrent) &&
                (buildNumberInstalled < currentBuildInt))
    }
    
    func clearOldDirectories() {
        // packages installed in previous versions. Must remove before anything else or they mess things up.
        let oldPythonDirectories = ["Library/lib/python3.7/site-packages/numpy-1.16.0-py3.7-macosx-12.1-iPad6,7.egg",
                                    "Library/lib/python3.7/site-packages/matplotlib-3.0.2-py3.7.egg",
                                    "Library/lib/python3.7/site-packages/kiwisolver-1.0.1-py3.7-macosx-12.1-iPad6,7.egg"]
        let documentsUrl = try! FileManager().url(for: .documentDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true)
        let homeUrl = documentsUrl.deletingLastPathComponent()
        for directoryName in oldPythonDirectories {
            let homeDirectory = homeUrl.appendingPathComponent(directoryName)
            if (FileManager().fileExists(atPath: homeDirectory.path)) {
                try! FileManager().removeItem(at: homeDirectory)
            }
        }
    }
    
    func queueUpdatingPythonFiles() {
        // This operation (copy the files from the bundle directory to the $HOME/Library)
        // has two benefits:
        // 1- all python files are in a user-writeable directory, so the user can install
        // more modules as needed
        // 2- we remove the .pyc files from the application archive, bringing its size
        // under the 150 MB limit.
        // Possible trouble: the user *can* screw up the directory. We should detect that,
        // and offer (through user preference) the possibility to reset the install.
        // Maybe: major version = erase everything (except site-packages?), minor version = just copy?
        NSLog("Updating python files")
        let moveFilesQueue = DispatchQueue(label: "moveFiles", qos: .utility) // low priority
        let bundleUrl = URL(fileURLWithPath: Bundle.main.resourcePath!)
        // setting up PYTHONPATH (temporary) so Jupyter can start while we copy items:
        let originalPythonpath = getenv("PYTHONPATH")
        let mainPythonUrl = bundleUrl.appendingPathComponent("Library/lib/python3.7")
        var newPythonPath = mainPythonUrl.path
        let pythonDirectories = ["Library/lib/python3.7/site-packages",
                                 "Library/lib/python3.7/site-packages/cffi-1.11.5-py3.7-macosx-12.1-iPad6,7.egg",
                                 "Library/lib/python3.7/site-packages/cycler-0.10.0-py3.7.egg",
                                 "Library/lib/python3.7/site-packages/jupyter_contrib_core-0.3.3-py3.7.egg",
                                 "Library/lib/python3.7/site-packages/jupyter_contrib_nbextensions-0.5.1-py3.7.egg",
                                 "Library/lib/python3.7/site-packages/jupyter_highlight_selected_word-0.2.0-py3.7.egg",
                                 "Library/lib/python3.7/site-packages/jupyter_latex_envs-1.4.6-py3.7.egg",
                                 "Library/lib/python3.7/site-packages/jupyter_nbextensions_configurator-0.4.1-py3.7.egg",
                                 "Library/lib/python3.7/site-packages/kiwisolver-1.0.1-py3.7-macosx-10.9-x86_64.egg",
                                 "Library/lib/python3.7/site-packages/matplotlib-3.0.3-py3.7-macosx-10.9-x86_64.egg",
                                 "Library/lib/python3.7/site-packages/numpy-1.16.0-py3.7-macosx-10.9-x86_64.egg",
                                 "Library/lib/python3.7/site-packages/pandas-0.24.2-py3.7-macosx-10.9-x86_64.egg",
                                 "Library/lib/python3.7/site-packages/pyparsing-2.3.1-py3.7.egg",
                                 "Library/lib/python3.7/site-packages/setuptools-40.8.0-py3.7.egg",
                                 "Library/lib/python3.7/site-packages/tornado-6.0.1-py3.7-macosx-12.1-iPad6,7.egg",
                                 ]
        for otherPythonDirectory in pythonDirectories {
            let secondaryPythonUrl = bundleUrl.appendingPathComponent(otherPythonDirectory)
            newPythonPath = newPythonPath.appending(":").appending(secondaryPythonUrl.path)
        }
        if (originalPythonpath != nil) {
            newPythonPath = newPythonPath.appending(":").appending(String(cString: originalPythonpath!))
        }
        setenv("PYTHONPATH", newPythonPath.toCString(), 1)
        //
        let documentsUrl = try! FileManager().url(for: .documentDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true)
        let homeUrl = documentsUrl.deletingLastPathComponent()
        for fileName in PythonFiles {
            moveFilesQueue.async{
                let bundleFile = bundleUrl.appendingPathComponent(fileName)
                let homeFile = homeUrl.appendingPathComponent(fileName)
                let homeDirectory = homeFile.deletingLastPathComponent()
                try! FileManager().createDirectory(atPath: homeDirectory.path, withIntermediateDirectories: true)
                do {
                    let firstFileAttribute = try FileManager().attributesOfItem(atPath: homeFile.path)
                    if (firstFileAttribute[FileAttributeKey.type] as? String == FileAttributeType.typeSymbolicLink.rawValue) {
                        let destination = try! FileManager().destinationOfSymbolicLink(atPath: homeFile.path)
                        if (!FileManager().fileExists(atPath: destination)) {
                            try! FileManager().removeItem(at: homeFile)
                            try! FileManager().createSymbolicLink(at: homeFile, withDestinationURL: bundleFile)
                        }
                    }
                }
                catch {
                    do {
                        try FileManager().createSymbolicLink(at: homeFile, withDestinationURL: bundleFile)
                    }
                    catch {
                        NSLog("Can't create file: \(homeFile.path): \(error)")
                    }
                }
            }
        }
        // Done, now update the installed version:
        moveFilesQueue.async{
            NSLog("Finished updating python files.")
            if (originalPythonpath != nil) {
                setenv("PYTHONPATH", originalPythonpath, 1)
            } else {
                let returnValue = unsetenv("PYTHONPATH")
                if (returnValue == -1) { NSLog("Could not unsetenv PYTHONPATH") }
            }
            NSLog("Installing extensions.")
            if (numberOfRunningSessions() >= 4) {
                NSLog("Removing one session before installing")
                removeOldestSession()
            }
            var pid:pid_t = ios_fork()
            ios_system("jupyter-contrib nbextension install --user")
            ios_waitpid(pid)
            pid = ios_fork()
            ios_system("jupyter-nbextension install --user --py widgetsnbextension")
            ios_waitpid(pid)
            pid = ios_fork()
            ios_system("jupyter-nbextension enable --user --py widgetsnbextension")
            ios_waitpid(pid)
            pid = ios_fork()
            ios_system("jupyter-nbextension install --user --py ipysheet")
            ios_waitpid(pid)
            pid = ios_fork()
            ios_system("jupyter-nbextension enable --user --py ipysheet")
            ios_waitpid(pid)
            pid = ios_fork()
            ios_system("jupyter-nbextension install --user --py ipysheet.renderer_nbext")
            ios_waitpid(pid)
            pid = ios_fork()
            ios_system("jupyter-nbextension enable --user --py ipysheet.renderer_nbext")
            ios_waitpid(pid)
            NSLog("Done upgrading Python files.")
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
            UserDefaults.standard.set(currentVersion, forKey: "versionInstalled")
            let currentBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
            UserDefaults.standard.set(currentBuild, forKey: "buildNumber")
        }
        // Compiling seems to take a toll on interactivity
        /*
        for fileName in PythonFiles {
            moveFilesQueue.async{
                let homeFile = homeUrl.appendingPathComponent(fileName)
                if (FileManager().fileExists(atPath: homeFile.path)) { // should always be true
                    var compileCommand = "python3 -m compileall "
                    compileCommand.append(homeFile.path)
                    compileCommand.append(" > /dev/null")
                    ios_switchSession(&self.moveFilesQueue);
                    ios_system(compileCommand.cString(using: String.Encoding.utf8))
                }
            }
        }
        moveFilesQueue.async{
            NSLog("Finished compiling python files.")
        }
        */
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // initialize ios_system:
        sideLoading = false
        initializeEnvironment()
        // Should solve a crash when Python calls setlocale()
        // Question: will we need to provide the locale as a user option?
        setenv("LC_CTYPE", "UTF-8", 1);
        setenv("LC_ALL", "UTF-8", 1);
        setenv("CLICOLOR_FORCE", "1", 1)  // color ls
        setlocale(LC_CTYPE, "UTF-8");
        setlocale(LC_ALL, "UTF-8");
        clearOldDirectories()
        // Loading on-demand resources:
        // ODR only work through AppStore (TestFlight or Download), not Xcode
        // Only to be used for non-essential stuff.
        // welcome = welcome message, copied to iCloud folder (can be unloaded)
        // nbextensions = only if it works
        // widgets = 
        if (needToUpdatePythonFiles()) {
            // start copying python files from App bundle to $HOME/Library
            // queue the copy operation so we can continue working.
            queueUpdatingPythonFiles()
        }
        let center = UNUserNotificationCenter.current()
        // Request permission to display alerts and play sounds.
        center.requestAuthorization(options: [.alert, .sound])
        { (granted, error) in
            // Enable or disable features based on authorization.
        }
        // Setup a way for the webview to tell us the user has requested to quit
        NotificationCenter.default.addObserver(self, selector: #selector(self.shutdownRequested), name: NSNotification.Name(rawValue: notificationQuitRequested), object: nil)
        // add our own function "openurl"
        replaceCommand("openurl", "openURL_internal", true)
        // When it quits normally, the Jupyter server removes these files
        // If it crashes, it doesn't. So we do some cleanup before the start.
        ios_system("rm -f $HOME/Library/Jupyter/runtime/*.html")
        ios_system("rm -f $HOME/Library/Jupyter/runtime/*.json")
        ios_system("rm -rf $HOME/tmp/(A*")
        // SSL certificate location:
        let libraryURL = try! FileManager().url(for: .libraryDirectory,
                                                in: .userDomainMask,
                                                appropriateFor: nil,
                                                create: true)
        let sslCertLocation = libraryURL.appendingPathComponent("lib/python3.7/site-packages/certifi/cacert.pem")
        setenv("SSL_CERT_FILE", sslCertLocation.path, 1); // SLL cacert.pem in ~/Library/ib/python3.7/site-packages/certifi/cacert.pem
        // iCloud abilities:
        // We check whether the user has iCloud ability here, and that the container exists
        let currentiCloudToken = FileManager().ubiquityIdentityToken
        if (currentiCloudToken != nil) {
            copyWelcomeFileToiCloud()
        }
        // print("Available fonts: \(UIFont.familyNames)");
        return true
    }

    @objc func shutdownRequested() {
        shutdownRequest = true
    }
    
    func notebookServerTerminated() {
        // the server (jupyter-notebook) has been terminated. Either because the user requested it,
        // or because it crashed down. If it's the former, close the window. The latter, restart.
        notebookServerRunning = false
        if (shutdownRequest) {
            // close the application:
           UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
        } else {
            // restart the server (except if we're in background):
            startNotebookServer()
        }
    }
    
    func startNotebookServer() {
        if (notebookServerRunning) { return }
        if (applicationInBackground) { return }
        // start the server:
        // set working directory (comment to serve from /)
        let documentsURL = try! FileManager().url(for: .documentDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true)
        documentsPath = documentsURL.path
        // NSLog("Documents directory = \(documentsPath)")
        jupyterQueue.async {
            self.notebookServerRunning = true
            // start the Jupyter notebook server:
            // (the server will call openURL with the name of the local file)
            NSLog("Starting jupyter notebook server")
            var shellCommand = "jupyter-notebook --notebook-dir /"
            ios_system(shellCommand)
            DispatchQueue.main.async {
                self.notebookServerTerminated()
            }
        }
    }
    
    
    @objc func terminateServer() {
        let app = UIApplication.shared
        let timeLeft = app.backgroundTimeRemaining
        NSLog("Terminating server. Time left = %f ", timeLeft)
        // shutdown Jupyter server and notebooks (takes about 7s with notebooks open)
        let task = URLSession.shared.dataTask(with: urlShutdownRequest) { data, response, error in
            if let error = error {
                NSLog ("Error on shutdown server: \(error)")
                return
            }
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                    NSLog ("Server error on shutdown")
                    return
            }
            clearAllRunningSessions()
        }
        task.resume()
        // cancel the alert:
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removeDeliveredNotifications(withIdentifiers: ["CarnetsShutdownAlert"])
        shutdownTimer = nil
        app.endBackgroundTask(shutdownTaskIdentifier)
        shutdownTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    }

    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        NSLog("Carnets: applicationWillResignActive")
        // 3 min to close current process. Don't shutdown until 2 mn 45 s
        guard (serverAddress != nil) else { return }
        let app = UIApplication.shared
        shutdownTaskIdentifier = app.beginBackgroundTask(expirationHandler: self.terminateServer)
        let urlPost = serverAddress!.appendingPathComponent("api/shutdown")
        urlShutdownRequest = URLRequest(url: urlPost)
        urlShutdownRequest.httpMethod = "POST"
        // Configure the alert (if needed) at 2:15 mn:
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { (settings) in
            if (settings.authorizationStatus == .authorized) {
                let shutdownAlertContent = UNMutableNotificationContent()
                if settings.alertSetting == .enabled {
                    shutdownAlertContent.title = NSString.localizedUserNotificationString(forKey: "Carnets shutdown alert", arguments: nil)
                    shutdownAlertContent.body = NSString.localizedUserNotificationString(forKey: "Carnets is about to terminate. Click here if you want to continue.", arguments: nil)
                }
                if settings.soundSetting == .enabled {
                    shutdownAlertContent.sound = UNNotificationSound.default
                }
                let localShutdownNotification = UNNotificationRequest(identifier: "CarnetsShutdownAlert",
                                                                      content: shutdownAlertContent,
                                                                      trigger: UNTimeIntervalNotificationTrigger(timeInterval: (135), repeats: false))
                notificationCenter.add(localShutdownNotification, withCompletionHandler: { (error) in
                    if let error = error {
                        var message = "Error in setting up the alert: "
                        message.append(error.localizedDescription)
                        NSLog(message)
                    }
                })
            }
        }
        // Set up a timer to close everything at 2:45 mn
        if (shutdownTimer != nil) {
            shutdownTimer.invalidate()
            shutdownTimer = nil
        }
        // Multiple timers being started???
        DispatchQueue.main.async {
            self.shutdownTimer = Timer.scheduledTimer(timeInterval: 165,
                                                      target: self,
                                                      selector: #selector(self.terminateServer),
                                                      userInfo: nil,
                                                      repeats: false)
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        // TODO: terminate running kernels, *except* if they are opened in a different app (see user preferences)
        NSLog("Carnets: applicationDidEnterBackground")
        applicationInBackground = true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        NSLog("Carnets: applicationWillEnterForeground")
        applicationInBackground = false
        startNotebookServer()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        NSLog("Carnets: applicationDidBecomeActive")
        applicationInBackground = false
        // cancel the alert:
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["CarnetsShutdownAlert"])
        // cancel the termination:
        if ((shutdownTaskIdentifier != nil) && (shutdownTaskIdentifier != UIBackgroundTaskIdentifier.invalid)) {
            let app = UIApplication.shared
            app.endBackgroundTask(shutdownTaskIdentifier)
            shutdownTaskIdentifier = UIBackgroundTaskIdentifier.invalid
        }
        if (shutdownTimer != nil) {
            shutdownTimer.invalidate()
            shutdownTimer = nil
        }
        startNotebookServer()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // NH: is actually almost never called. We cannot assume it will be called.
        NSLog("Carnets: applicationWillTerminate")
    }

    func application(_ app: UIApplication, open inputURL: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Ensure the URL is a file URL
        guard inputURL.isFileURL else { return false }
                
        // Reveal / import the document at the URL
        guard let documentBrowserViewController = window?.rootViewController as? DocumentBrowserViewController else { return false }

        documentBrowserViewController.revealDocument(at: inputURL, importIfNeeded: true) { (revealedDocumentURL, error) in
            if let error = error {
                // Handle the error appropriately
                NSLog("Failed to reveal the document at URL \(inputURL) with error: '\(error)'")
                return
            }
            self.startNotebookServer()
            NSLog("Received document to open: \(revealedDocumentURL)")
            // Present the Document View Controller for the revealed URL
            if (notebookURL == nil) {
                NSLog("calling documentBrowserViewController")
                documentBrowserViewController.presentDocument(at: revealedDocumentURL!)
            } else {
                NSLog("calling appWebView")
                notebookURL = revealedDocumentURL
                kernelURL = urlFromFileURL(fileURL: notebookURL!)
                appWebView.load(URLRequest(url: kernelURL!))
            }
        }
        return true
    }
}

