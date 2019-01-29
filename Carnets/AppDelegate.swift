//
//  AppDelegate.swift
//  Carnets
//
//  Created by Nicolas Holzschuch on 26/01/2019.
//  Copyright © 2019 AsheKube. All rights reserved.
//

import UIKit
import ios_system

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let jupyterQueue = DispatchQueue(label: "Jupyter-notebook", qos: .background)
    var notebookServerRunning: Bool = false

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // initialize ios_system:
        sideLoading = false
        initializeEnvironment()
        // add our own function "openurl"
        replaceCommand("openurl", "openURL", true)
        // having multiple file managers makes the app unstable, so use ios_system calls:
        ios_system("cd $HOME/Documents/")
        // When it quits normally, the Jupyter server removes these files
        // If it crashes, it doesn't. So we do some cleanup before the start.
        ios_system("rm $HOME/Library/Jupyter/runtime/*.html")
        ios_system("rm $HOME/Library/Jupyter/runtime/*.json")
        startNotebookServer()
        return true
    }

    func notebookServerTerminated() {
        notebookServerRunning = false
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

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("applicationWillTerminate")
        notebookServerTerminated()
    }

}

