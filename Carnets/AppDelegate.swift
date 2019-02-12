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
    private let jupyterQueue = DispatchQueue(label: "Jupyter-notebook", qos: .background)
    private let compileQueue = DispatchQueue(label: "Python-compile", qos: .background)
    var notebookServerRunning: Bool = false
    var shutdownRequest: Bool = false
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // initialize ios_system:
        sideLoading = false
        initializeEnvironment()
        let center = UNUserNotificationCenter.current()
        // Request permission to display alerts and play sounds.
        center.requestAuthorization(options: [.alert, .sound])
        { (granted, error) in
            // Enable or disable features based on authorization.
        }
        // First execution time:
        let libraryURL = try! FileManager().url(for: .libraryDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true)
        let libLocation = libraryURL.appendingPathComponent("lib")
        let filesAlreadyCopied = FileManager().fileExists(atPath: libLocation.path)
        if (!filesAlreadyCopied) {
            // first time we start the app:
            // Copy python files to $HOME/Library/
            let mainBundle = Bundle.main
            let bundlePath = mainBundle.bundleURL
            let filesLocation = bundlePath.appendingPathComponent("Library").appendingPathComponent("lib")
            do{
                try FileManager().copyItem(at: filesLocation, to: libLocation)
            }catch let error as NSError {
                print("error occurred, here are the details:\n \(error)")
            }
            // compile them (asynchronous)
            compileQueue.async {
                ios_system("python3 -m compileall $HOME/Library/lib")
            }
            // This operation (copy the files from the bundle directory to the $HOME/Library)
            // has two benefits:
            // 1- all python files are in a user-writeable directory, so the user can install
            // more modules as needed
            // 2- we remove the .pyc files from the application archive, bringing its size
            // under the 150 MB limit.
        }
        // setup a way for the webview to tell us the user has requested to quit
        NotificationCenter.default.addObserver(self, selector: #selector(self.shutdownRequested), name: NSNotification.Name(rawValue: notificationQuitRequested), object: nil)
        // add our own function "openurl"
        replaceCommand("openurl", "openURL", true)
        // set working directory:
        let documentsURL = try! FileManager().url(for: .documentDirectory,
                                                in: .userDomainMask,
                                                appropriateFor: nil,
                                                create: true)
        FileManager().changeCurrentDirectoryPath(documentsURL.path)
        // When it quits normally, the Jupyter server removes these files
        // If it crashes, it doesn't. So we do some cleanup before the start.
        ios_system("rm -f $HOME/Library/Jupyter/runtime/*.html")
        ios_system("rm -f $HOME/Library/Jupyter/runtime/*.json")
        startNotebookServer()
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
            // restart the server:
            startNotebookServer()
        }
    }
    
    func startNotebookServer() {
        if (notebookServerRunning) { return }
        notebookServerRunning = true
        jupyterQueue.async {
            // start the Jupyter notebook server:
            // Final version: with logging (maybe in ~/Library?)
            // ios_system("jupyter-notebook &> notebook.log")
            // Debug version: output to console:
            // (the server will call openURL with the name of the local file)
            ios_system("jupyter-notebook")
            DispatchQueue.main.async {
                self.notebookServerTerminated()
            }
        }
    }
    
    // TODO: write these functions. Background mode is against the rules (for this kind of app)
    // https://developer.apple.com/library/archive/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/TheAppLifeCycle/TheAppLifeCycle.html
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        print("applicationWillResignActive")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        // TODO: save every open notebook (inside each)
        // TODO: save list of open notebooks (inside app preference file)
        // TODO: save front notebook name
        print("applicationDidEnterBackground")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        // TODO: reopen active notebooks
        print("applicationWillEnterForeground")
        jupyterQueue.async {
            // Are there notebook servers running?
            ios_system("jupyter-notebook list")
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("applicationDidBecomeActive")
        startNotebookServer()
    }

    func badgeAppAndPlaySound() {
        let content = UNMutableNotificationContent()
        content.title = "Carnets is about to terminate"
        content.categoryIdentifier = "Terminate_Alert"
        

        // Define the custom actions.
        // Define the notification type
        let appIsAboutToTerminateAlert =
            UNNotificationCategory(identifier: "Terminate_Alert",
                                   actions: [], intentIdentifiers: [],
                                   options: .customDismissAction)
        // Register the notification type.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([appIsAboutToTerminateAlert])
    }
    
    func postAlertIfAuthorized() {
        // Check the authorization status each time:
        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.getNotificationSettings { (settings) in
            // Do not schedule notifications if not authorized.
            guard settings.authorizationStatus == .authorized else {return}
            
            if settings.alertSetting == .enabled {
                self.badgeAppAndPlaySound()
                // Schedule an alert-only notification.
                // self.myScheduleAlertNotification()
            }
            else {
                // Schedule a notification with a badge and sound.
                self.badgeAppAndPlaySound()
            }
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("applicationWillTerminate")
        // We warn the user the app is about to terminate (if they want to know)
        postAlertIfAuthorized()
        if (!shutdownRequest) {
            
            
        }
    }

}

