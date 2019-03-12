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
                                 "Library/lib/python3.7/site-packages/numpy-1.16.0-py3.7-macosx-12.1-iPad6,7.egg/",
                                 "Library/lib/python3.7/site-packages/matplotlib-3.0.2-py3.7.egg",
                                 "Library/lib/python3.7/site-packages/cycler-0.10.0-py3.7.egg/",
                                 "Library/lib/python3.7/site-packages/pyparsing-2.3.1-py3.7.egg"]
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
                if (FileManager().fileExists(atPath: homeFile.path)) {
                    // this is an update: we remove the previous version:
                    try! FileManager().removeItem(at: homeFile)
                }
                try! FileManager().copyItem(at: bundleFile, to: homeFile)
            }
        }
        // Done, now update the installed version:
        moveFilesQueue.async{
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
            UserDefaults.standard.set(currentVersion, forKey: "versionInstalled")
            let currentBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
            UserDefaults.standard.set(currentBuild, forKey: "buildNumber")
            NSLog("Finished updating python files.")
            if (originalPythonpath != nil) {
                setenv("PYTHONPATH", originalPythonpath, 1)
            } else {
                let returnValue = unsetenv("PYTHONPATH")
                if (returnValue == -1) { NSLog("Could not unsetenv PYTHONPATH") }
            }
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
        // set working directory (comment to serve from /)
        let documentsURL = try! FileManager().url(for: .documentDirectory,
                                                in: .userDomainMask,
                                                appropriateFor: nil,
                                                create: true)
        FileManager().changeCurrentDirectoryPath(documentsURL.path)
        // When it quits normally, the Jupyter server removes these files
        // If it crashes, it doesn't. So we do some cleanup before the start.
        ios_system("rm -f $HOME/Library/Jupyter/runtime/*.html")
        ios_system("rm -f $HOME/Library/Jupyter/runtime/*.json")
        // startNotebookServer()
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
        jupyterQueue.async {
            self.notebookServerRunning = true
            // start the Jupyter notebook server:
            // (the server will call openURL with the name of the local file)
            NSLog("Starting jupyter notebook server")
            ios_system("jupyter-notebook")
            DispatchQueue.main.async {
                self.notebookServerTerminated()
            }
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        // TODO: save every open notebook (inside each)
        NSLog("Carnets: applicationWillResignActive")
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
            
            // Present the Document View Controller for the revealed URL
            documentBrowserViewController.presentDocument(at: revealedDocumentURL!)
        }

        return true
    }


}

