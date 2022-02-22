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
import BackgroundTasks

var jupyterServerPid: pid_t = 0
let jupyterServerSession = "jupyterServerSession"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private let jupyterQueue = DispatchQueue(label: "Jupyter-notebook", qos: .userInteractive) // high priority
    private let extensionsQueue = DispatchQueue(label: "nbextensions", qos: .utility) // high priority
    var notebookServerRunning: Bool = false
    var shutdownRequest: Bool = false
    var mustRecompilePythonFiles: Bool = false
    var applicationInBackground: Bool = false
    // shutdown tasks:
    var urlShutdownRequest: URLRequest!
    var shutdownTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    // on-demand resources, barrier booleans for synchronization:
    var updateExtensionsRunning = false
    var terminateServerRunning = false
    // Which version of the app are we running? Carnets, Carnets mini, Carnets Pro, Carnets Julia...?
    var appVersion: String? {
        // Bundle.main.infoDictionary?["CFBundleDisplayName"] = Carnets
        // Bundle.main.infoDictionary?["CFBundleIdentifier"] = AsheKube.Carnets
        // Bundle.main.infoDictionary?["CFBundleName"] = Carnets
        return Bundle.main.infoDictionary?["CFBundleName"] as? String
    }
    
    func copyWelcomeFileToiCloud() {
        // Create a "welcome" document in the iCloud folder.
        // This file has instructions and details.
        // It also forces the iCloud folder to become visible.
        // The "welcome" directory in an On-Demand Resource. It will be downloaded *only* if it's needed.
        DispatchQueue.global().async(execute: {
            iCloudDocumentsURL = FileManager().url(forUbiquityContainerIdentifier: nil)
            if (iCloudDocumentsURL != nil) {
                // Create a document in the iCloud folder to make it visible.
                // print("iCloudContainer = \(iCloudDocumentsURL)")
                let iCloudDirectory = iCloudDocumentsURL?.appendingPathComponent("Documents")
                guard let iCloudDirectoryWelcome = iCloudDirectory?.appendingPathComponent("welcome") else { return }
                if (!FileManager().fileExists(atPath: iCloudDirectoryWelcome.path)) {
                    NSLog("Creating iCloud welcome directory")
                    do {
                        try FileManager().createDirectory(atPath: iCloudDirectoryWelcome.path, withIntermediateDirectories: true)
                        // download the resource from the iTunes store:
                        let welcomeBundleResource = NSBundleResourceRequest(tags: ["welcome"])
                        NSLog("Begin downloading welcome resources")
                        welcomeBundleResource.beginAccessingResources(completionHandler: { (error) in
                            if let error = error {
                                var message = "Error in downloading welcome resource: "
                                message.append(error.localizedDescription)
                                NSLog(message)
                            } else {
                                NSLog("Welcome resource succesfully downloaded")
                                let welcomeFiles=["welcome/Welcome to Carnets.ipynb",
                                                  "welcome/top.png",
                                                  "welcome/bottom_iphone.png",
                                                  "welcome/bottom.png"]
                                for fileName in welcomeFiles {
                                    guard let welcomeFileLocation = welcomeBundleResource.bundle.path(forResource: fileName, ofType: nil) else { continue }
                                    guard let iCloudFile = iCloudDirectory?.appendingPathComponent(fileName) else { continue }
                                    if (!FileManager().fileExists(atPath: iCloudFile.path) && FileManager().fileExists(atPath: welcomeFileLocation)) {
                                        // print("Copying item from \(welcomeFileLocation) to \(iCloudFile)")
                                        do {
                                            try FileManager().copyItem(atPath: welcomeFileLocation, toPath: iCloudFile.path)
                                        } catch {
                                            NSLog("There was an error copying file \(welcomeFileLocation) to iCloud path \(iCloudFile.path)")
                                        }
                                    }
                                }
                            }
                            welcomeBundleResource.endAccessingResources()
                        })
                    } catch {
                        NSLog("There was an error creating the iCloud/welcome directory")
                    }
                }
            }
        })
    }
    
    func versionNumberIncreased() -> Bool {
        // do it with UserDefaults, not storing in files
        UserDefaults.standard.register(defaults: ["versionInstalled" : "0.0"])
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        let currentBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
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

    func needToRemovePython37Files() -> Bool {
            // Check that the old python files are present:
            let libraryURL = try! FileManager().url(for: .libraryDirectory,
                                                    in: .userDomainMask,
                                                    appropriateFor: nil,
                                                    create: true)
        let fileLocation = libraryURL.appendingPathComponent(PythonFiles[0])
        // fileExists(atPath:) will answer false, because the linked file does not exist.
        do {
            let fileAttribute = try FileManager().attributesOfItem(atPath: fileLocation.path)
            return true
        }
        catch {
            // The file does not exist, we already cleaned up Python3.7
            return false
        }
    }
    
    func removePython37Files() {
        // This operation removes the copy of the Python 3.7 directory that was kept in $HOME/Library.
        NSLog("Removing python 3.7 files")
        let documentsUrl = try! FileManager().url(for: .documentDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true)
        let homeUrl = documentsUrl.deletingLastPathComponent().appendingPathComponent("Library")
        let fileList = PythonFiles
        for fileName in fileList {
            let homeFile = homeUrl.appendingPathComponent(fileName)
            do {
                try FileManager().removeItem(at: homeFile)
            }
            catch {
                NSLog("Can't remove file: \(homeFile.path): \(error)")
            }
        }
    }

    func updateExtensionsIfNeeded() {
        if (updateExtensionsRunning) { return } // Don't run this more than once
        updateExtensionsRunning = true
        extensionsQueue.async {
            NSLog("Installing extensions.")
            // TODO: switch session back to install session before each command.
            // TODO: do I need to remove everything to reinstall?
            var pid:pid_t = ios_fork()
            ios_system("jupyter-contrib nbextension install --user")
            ios_waitpid(pid)
            NSLog("Installing widgets.")
            pid = ios_fork()
            ios_system("jupyter-nbextension install --user --py ipysheet")
            ios_waitpid(pid)
            pid = ios_fork()
            ios_system("jupyter-nbextension enable --user --py ipysheet")
            ios_waitpid(pid)
            pid = ios_fork()
            ios_system("jupyter-nbextension install --user --py widgetsnbextension")
            ios_waitpid(pid)
            pid = ios_fork()
            ios_system("jupyter-nbextension enable --user --py widgetsnbextension")
            ios_waitpid(pid)
            UserDefaults.standard.set(true, forKey: "widgetsEnabled")
            NSLog("Done upgrading extensions and widgets.")
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
            UserDefaults.standard.set(currentVersion, forKey: "versionInstalled")
            let currentBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
            UserDefaults.standard.set(currentBuild, forKey: "buildNumber")
            self.updateExtensionsRunning = false
        }
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
        setenv("TZ", TimeZone.current.identifier, 1) // TimeZone information, since "systemsetup -gettimezone" won't work.
        setenv("OPENBLAS_NUM_THREADS", "1", 1) // disable multi-threading OpenBLAS (also set at compile time).
        setenv("PYFFTW_NUM_THREADS", "1", 1) // disable multi-threading with PyFFTW.
        setenv("OMP_NUM_THREADS", "1", 1) // disable multi-threading with OpenMP
        setenv("JOBLIB_MULTIPROCESSING", "0", 1) // deactivate multiprocessing in joblib:
        setenv("QUTIP_NUM_PROCESSES", "1", 1) // number of processors in qutip
        // for debugging, or since the number of frameworks appears to be limited:
        numPythonInterpreters = 4
        // TODO: have more languages
        // Current options are: fr_FR, zh_CN or zh_TW (or english as default)
        let language = UserDefaults.standard.string(forKey: "language_preference")
        if (language != nil) {
            setenv("LANGUAGE", language, 1);
        }
        setlocale(LC_CTYPE, "UTF-8");
        setlocale(LC_ALL, "UTF-8");
        let libraryURL = try! FileManager().url(for: .libraryDirectory,
                                                in: .userDomainMask,
                                                appropriateFor: nil,
                                                create: true)
        // Clear old Python 3.7 files, keep user extensions:
        if (needToRemovePython37Files()) {
            // Remove files and directories created with Python 3.7
            removePython37Files()
            // Also remove packages with multiple versions installed:
            // This one even causes a crash:
            var pid = ios_fork()
            ios_system("rm -rf " + libraryURL.path + "/lib/python3.7/site-packages/idna*")
            ios_waitpid(pid)
            pid = ios_fork()
            ios_system("rm -rf " + libraryURL.path + "/lib/python3.7/site-packages/jupyter_core*")
            ios_waitpid(pid)
            pid = ios_fork()
            ios_system("rm -rf " + libraryURL.path + "/lib/python3.7/site-packages/Pygments*")
            ios_waitpid(pid)
            // Move all remaining packages to $HOME/Library/lib/python3.9/site-packages/
            pid = ios_fork()
            ios_system("mkdir -p " + libraryURL.path + "/lib/python3.9/site-packages/")
            ios_waitpid(pid)
            pid = ios_fork()
            ios_system("mv -n " + libraryURL.path + "/lib/python3.7/site-packages/* " + libraryURL.path + "/lib/python3.9/site-packages/")
            ios_waitpid(pid)
            // Erase the old directory
            pid = ios_fork()
            ios_system("rm -rf " + libraryURL.path + "/lib/python3.7/")
            ios_waitpid(pid)
        }
        if (versionNumberIncreased()) {
            // The version number changed, so the App has been re-installed. Clean all pre-compiled Python files:
            NSLog("Cleaning __pycache__")
            let pid = ios_fork()
            ios_system("rm -rf " + libraryURL.path + "/__pycache__/*")
            ios_waitpid(pid)
        }
        UserDefaults.standard.register(defaults: ["file_access" : true])
        // Main Python install: $APPDIR/Library/lib/python3.x
        let bundleUrl = URL(fileURLWithPath: Bundle.main.resourcePath!).appendingPathComponent("Library")
        setenv("PYTHONHOME", bundleUrl.path.toCString(), 1)
        // Compiled files: ~/Library/__pycache__
        setenv("PYTHONPYCACHEPREFIX", (libraryURL.appendingPathComponent("__pycache__")).path.toCString(), 1)
        setenv("PYTHONUSERBASE", libraryURL.path.toCString(), 1)
        setenv("PLATFORM", "iphone", 1) // prevents numpy.system_info from calling gcc
        // Detect changes in user defaults:
        NotificationCenter.default.addObserver(self, selector: #selector(self.settingsChanged), name: UserDefaults.didChangeNotification, object: nil)
        // add our own function "openurl"
        replaceCommand("openurl", "openURL_internal", true)
        // When it quits normally, the Jupyter server removes these files
        // If it crashes, it doesn't. So we do some cleanup before the start.
        var pid = ios_fork()
        ios_system("rm -f $HOME/Library/Jupyter/runtime/*.html")
        ios_waitpid(pid)
        pid = ios_fork()
        ios_system("rm -f $HOME/Library/Jupyter/runtime/*.json")
        ios_waitpid(pid)
        pid = ios_fork()
        ios_system("rm -rf $HOME/tmp/*")
        ios_waitpid(pid)
        if (versionNumberIncreased()) {
            updateExtensionsIfNeeded()
        }
        // SSL certificate location:
        let sslCertLocation = bundleUrl.appendingPathComponent("lib/python3.9/site-packages/certifi/cacert.pem")
        let sslCertDir = bundleUrl.appendingPathComponent("lib/python3.9/site-packages/certifi/")
        setenv("SSL_CERT_FILE", sslCertLocation.path, 1); // SLL cacert.pem in $APPDIR/Library/lib/python3.9/site-packages/certifi/cacert.pem
        setenv("SSL_CERT_DIR", sslCertDir.path, 1); // SLL cacert.pem in $APPDIR/Library/lib/python3.9/site-packages/certifi/cacert.pem
        setenv("REQUESTS_CA_BUNDLE", sslCertLocation.path, 1); // SLL cacert.pem in $APPDIR/Library/lib/python3.9/site-packages/certifi/cacert.pem
        // Help aiohttp install itself:
        setenv("YARL_NO_EXTENSIONS", "1", 1)
        setenv("MULTIDICT_NO_EXTENSIONS", "1", 1)
        // This one is not required, but it helps:
        setenv("DISABLE_SQLALCHEMY_CEXT", "1", 1)
        setenv("PYPROJ_GLOBAL_CONTEXT", "ON", 1) // This helps pyproj in cleaning up.
        let documentsUrl = try! FileManager().url(for: .documentDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true)
        let nltkData = documentsUrl.appendingPathComponent("nltk_data")
        setenv("NLTK_DATA", nltkData.path, 1)
        let projDir = bundleUrl.appendingPathComponent("share/proj")
        setenv("PROJ_LIB", projDir.path, 1)
        // Carnets Pro (with scipy) only: specify data location using env var:
        if (appVersion == "Carnets-sci") {
            // GDAL_DATA?
            let seabornData = libraryURL.appendingPathComponent("seaborn-data")
            setenv("SEABORN_DATA", seabornData.path, 1)
            let sklearnData = libraryURL.appendingPathComponent("scikit_learn_data")
            setenv("SCIKIT_LEARN_DATA", sklearnData.path, 1)
            let statsmodelsData = libraryURL.appendingPathComponent("statsmodels_data")
            setenv("STATSMODELS_DATA", statsmodelsData.path, 1)
            let pysalData = libraryURL.appendingPathComponent("pysal_data")
            setenv("PYSALDATA", pysalData.path, 1)
        }
        // iCloud abilities:
        // We check whether the user has iCloud ability here, and that the container exists
        let currentiCloudToken = FileManager().ubiquityIdentityToken
        if (currentiCloudToken != nil) {
            copyWelcomeFileToiCloud()
        }
        // print("Available fonts: \(UIFont.familyNames)");
        // Register a background execution:
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "AsheKube.Carnets.cleanupApplication", using: nil) { task in
            self.handleBackgroundCleanup(task: task as! BGAppRefreshTask)
        }
        return true
    }

    @objc func shutdownRequested() {
        shutdownRequest = true
    }

    @objc func settingsChanged() {
        // UserDefaults.didChangeNotification is called every time the window becomes active
        // We only act if things have really changed.
        let language = UserDefaults.standard.string(forKey: "language_preference")
        if (language != nil) {
            setenv("LANGUAGE", language, 1);
        }
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
    
    @objc func startNotebookServer() {
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
            // start the Jupyter notebook server:
            // (the server will call openURL with the name of the local file)
            self.notebookServerRunning = true
            ios_switchSession(jupyterServerSession)
            NSLog("Starting jupyter notebook server")
            joinMainThread = true
            jupyterServerPid = ios_fork()
            let shellCommand = "jupyter-notebook --notebook-dir /"
            ios_system(shellCommand)
            ios_waitpid(jupyterServerPid)
            ios_releaseThreadId(jupyterServerPid)
            NSLog("Terminated jupyter notebook server")
            DispatchQueue.main.async {
                self.notebookServerTerminated()
            }
        }
    }

    func completeShutdown() {
        // terminate the app by calling exit():
        // Other termination methods leave 0MQ sockets hanging, resulting in a crash later.
        // (not always, but often enough for it to be a nuisance).
        let handle = dlopen("libc.dylib", RTLD_LAZY | RTLD_GLOBAL)
        let function = dlsym(handle, "exit")
        typealias randomFunc = @convention(c) (CInt) -> Void
        let libc_exit = unsafeBitCast(function, to: randomFunc.self)
        NSLog("Calling exit in completeShutdown: Time left = %f ", UIApplication.shared.backgroundTimeRemaining)
        libc_exit(0) // calls exit(0), terminating all threads.
        dlclose(handle) // not reached, but hey.
    }
    
    func handleBackgroundCleanup(task: BGAppRefreshTask) {
        // Called after 10 mn in background
        NSLog("Background cleanup called after 10+ mn")
        task.expirationHandler = {
            task.setTaskCompleted(success: true)
        }
        // It would make more sense to call the actual server shutdown here, rather than exit():
        let handle = dlopen("libc.dylib", RTLD_LAZY | RTLD_GLOBAL)
        let function = dlsym(handle, "exit")
        typealias randomFunc = @convention(c) (CInt) -> Void
        let libc_exit = unsafeBitCast(function, to: randomFunc.self)
        libc_exit(0) // calls exit(0), terminating all threads.
        dlclose(handle) // not reached, but hey.
        task.setTaskCompleted(success: true)
    }
    
    @objc func terminateServer() {
        // Called after 30s in background: terminate all sessions except the front one:
        // Only run this function once at a time
        if (terminateServerRunning) {
            return
        }
        terminateServerRunning = true
        let app = UIApplication.shared
        let timeLeft = app.backgroundTimeRemaining
        NSLog("Terminating server. Time left = %f ", timeLeft)
        // New system: terminate all sessions not in foreground:
        var currentNumberOfRunningSessions = numberOfRunningSessions()
        while (currentNumberOfRunningSessions > 1) {
            removeOldestSession()
            // Wait for the session to be effectively terminated:
            while (numberOfRunningSessions() == currentNumberOfRunningSessions) {
                usleep(10) // The loop needs to be non-empty, otherwise there's a crash.
            }
            currentNumberOfRunningSessions = numberOfRunningSessions()
        }
        // cancel the shutdown task (if it was set):
        if (shutdownTaskIdentifier != .invalid) {
            app.endBackgroundTask(shutdownTaskIdentifier)
            shutdownTaskIdentifier = UIBackgroundTaskIdentifier.invalid
        }
        terminateServerRunning = false
        NSLog("Done closing sessions. Time left = %f ", timeLeft)
        return
        //
        if (numberOfRunningSessions() > 0) {
            NSLog("Closing all sessions:")
            closeAllRunningSessions()
            // Now, we wait for all these deletions to be effective:
            // Yes, parallelism is difficult, see examples below:
            while (numberOfRunningSessions() > 0) {
                usleep(10) // The loop needs to be non-empty, otherwise there's a crash.
            }
            sleep(1) // Required too. Gives time for the sessions to be actually terminated
            NSLog("Terminating server.")
        }
        // shutdown Jupyter server and notebooks (takes about 7s with notebooks open)
        // cancel the alert (if it was set):
        if (shutdownTaskIdentifier != .invalid) {
            app.endBackgroundTask(shutdownTaskIdentifier)
            shutdownTaskIdentifier = UIBackgroundTaskIdentifier.invalid
        }
        shutdownRequested()
        completeShutdown()
        // TODO: remove the rest of the function. This code is not executed if completeShutdown() does its job.
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
            NSLog("Server is now terminated: Time left = %f ", app.backgroundTimeRemaining)
            clearAllRunningSessions()
            self.terminateServerRunning = false
            NSLog("Cleanup done: Time left = %f ", app.backgroundTimeRemaining)
            let handle = dlopen("libc.dylib", RTLD_LAZY | RTLD_GLOBAL)
            let function = dlsym(handle, "exit")
            typealias randomFunc = @convention(c) (CInt) -> Void
            let libc_exit = unsafeBitCast(function, to: randomFunc.self)
            if (app.backgroundTimeRemaining > 1) {
                sleep(1) // Wait 1 more s
            }
            NSLog("Calling exit in terminateServer: Time left = %f ", app.backgroundTimeRemaining)
            libc_exit(0) // calls exit(0), terminating all threads.
            dlclose(handle) // not reached, but hey.
        }
        task.resume()
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        NSLog("Carnets: received memory warning")
        if (!applicationInBackground) {
            // Don't remove the session currently in the foreground:
            if (numberOfRunningSessions() > 1) {
                removeOldestSession()
            } else {
                // A single session is taking too much memory.
                // For now, we don't kill it, as it creates a lot of other issues
                // In case, here is the code for showing an alert (the alert showing part doesn't work on iOS 15)
                // Kill it, and show an alert.
                // How to kill? If the running operation is the one taking too much memory and continuing, not much we can do.
                // Kill all processes except server? doesn't work
                // let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                // let documentViewController = storyBoard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
                // documentViewController.displayAlert(title:"Memory Warning", message: "The current session is using too much memory. It will be terminated.")
                // removeOldestSession() // Will terminate the current session if it's not active
            }
        } else {
            // completeShutdown()
        }
    }
    
    func applicationProtectedDataWillBecomeUnavailable(_ application: UIApplication) {
        // iPhone/iPad being turned off. Let's release everything:
        NSLog("Carnets: received protected data warning")
        if (applicationInBackground) {
            completeShutdown()
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        NSLog("Carnets: applicationWillResignActive")
        // store the bookmarks for future use:
        UserDefaults.standard.set(bookmarks, forKey: "storedBookmarks")
        // 10 mn from now, clear up the entire application:
        let request = BGAppRefreshTaskRequest(identifier: "AsheKube.Carnets.cleanupApplication")
        // "earliestBeginDate should not be set too far in the future." Try 5.
        // 10 mn: called after 13 mn, 11 mn 6 s, works at 11 mn, 10mn.
        // 5 mn: called after 8 mn, works (application killed, nothing happens till then)
        // 0 mn: called after 7 to 10 mn, works (as in: kills the application)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 10 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
            NSLog("successfully scheduled background task, earliest begin date is: \(request.earliestBeginDate as Any))")
        } catch {
            NSLog("Could not schedule cleanupApplication: \(error)")
        }
        if (!applicationInBackground) {
            applicationDidEnterBackground(application)
        }
        guard (serverAddress != nil) else {
            return
        }
        let urlPost = serverAddress!.appendingPathComponent("api/shutdown")
        urlShutdownRequest = URLRequest(url: urlPost)
        urlShutdownRequest.httpMethod = "POST"
        let app = UIApplication.shared
        shutdownTaskIdentifier = app.beginBackgroundTask(withName:"cleanupSessions", expirationHandler: self.terminateServer)
    }

    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        // TODO: terminate running kernels, *except* if they are opened in a different app (see user preferences)
        NSLog("Carnets: applicationDidEnterBackground")
        if (!applicationInBackground) {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let documentViewController = storyBoard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
            NSFileCoordinator.removeFilePresenter(documentViewController)
        }
        applicationInBackground = true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        NSLog("Carnets: applicationWillEnterForeground")
        if (applicationInBackground) {  
            applicationInBackground = false
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let documentViewController = storyBoard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
            documentViewController.modalPresentationStyle = UIModalPresentationStyle.fullScreen;
            NSFileCoordinator.addFilePresenter(documentViewController)
            startNotebookServer()
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        NSLog("Carnets: applicationDidBecomeActive")
        // retrieve the bookmarks:
        let storedBookmarksDictionary = UserDefaults.standard.dictionary(forKey: "storedBookmarks") as? [String: Data]
        bookmarks = storedBookmarksDictionary ?? [:]
        BGTaskScheduler.shared.getPendingTaskRequests(completionHandler: { taskRequests in
            NSLog("Unexecuted tasksRequests: \(taskRequests)")
        })
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: "AsheKube.Carnets.cleanupApplication")
        if (applicationInBackground) {
            applicationWillEnterForeground(application)
        }
        // cancel the termination:
        if (shutdownTaskIdentifier != UIBackgroundTaskIdentifier.invalid) {
            let app = UIApplication.shared
            app.endBackgroundTask(shutdownTaskIdentifier)
            shutdownTaskIdentifier = UIBackgroundTaskIdentifier.invalid
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
            guard (revealedDocumentURL != nil) else {
                return
            }
            self.startNotebookServer()
            // NSLog("Received document to open: \(revealedDocumentURL)")
            // Present the Document View Controller for the revealed URL
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let documentViewController = storyBoard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
            documentViewController.modalPresentationStyle = UIModalPresentationStyle.fullScreen;

            UserDefaults.standard.set(revealedDocumentURL, forKey: "lastOpenUrl")
            if (!notebookViewerActive) {
                // The documentBrowserViewController is active, we ask it to display the document:
                documentBrowserViewController.presentDocument(at: revealedDocumentURL!)
            } else {
                // The documentViewController is active, we ask it to display the document:
                documentViewController.load(url: revealedDocumentURL!)
            }
        }
        return true
    }

}
