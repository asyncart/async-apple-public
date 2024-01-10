//
//  AppDelegate.swift
//  Async Art
//
//  Created by Francis Li on 5/22/20.
//

import UIKit
import Sentry
import Mixpanel

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        /// disable idle timer so screensaver doesn't take over
        application.isIdleTimerDisabled = true
        SentrySDK.start { options in
            options.dsn = "https://f5a3c2e3d53240fc85d1f53043fd4e23@o994041.ingest.sentry.io/5952311"
            options.debug = false
        }
        Mixpanel.initialize(token: "49bbbd1c9446bc2ccec2a2d9e6543024")
        AppRealm.compactRealm()
        AppRealm.listenForUpdates()
        Mixpanel.mainInstance().identify(distinctId: UIDevice.current.identifierForVendor?.uuidString ?? "")
        return true
    }

    func initializePlayButtonRecognition() {
        addPlayButtonRecognizer(#selector(AppDelegate.handlePlayButton(_:)))
    }

    func addPlayButtonRecognizer(_ selector: Selector) {
        let playButtonRecognizer = UITapGestureRecognizer(target: self, action:selector)
        playButtonRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.playPause.rawValue as Int)]
        self.window?.addGestureRecognizer(playButtonRecognizer)
    }

    @objc func handlePlayButton(_ sender: AnyObject) {
        if player.state == .playing {
            player.player.pause() 
        } else {
            player.player.play()
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
}
