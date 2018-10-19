//
//  AppDelegate.swift
//  BiocheckMovil
//
//  Created by Arturo Avalos on 4/13/18.
//  Copyright © 2018 Arturo Avalos. All rights reserved.
//

import UIKit
import NotificationCenter

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var daySettings: DaySettings?
    var employee: Employee?
    var records: [Record]?
    var sessionTimer: RepeatingTimer?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        if Login.getToken() == nil {
            showLoginScreen(duration: 0)
        }
    
        return true
    }
    
    func showLoginScreen (duration: Double)
    {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "loginViewController")
        vc.view.frame = (self.window!.rootViewController?.view.frame)!
        vc.view.layoutIfNeeded()
        
        UIView.transition(with: self.window!, duration: duration, options: .transitionCurlDown , animations: {
            self.window!.rootViewController = vc
        }, completion: nil)
        
    }
    
    func showEnrollView ()
    {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "enrollViewController")
        vc.view.frame = (self.window!.rootViewController?.view.frame)!
        vc.view.layoutIfNeeded()
        
        
        UIView.transition(with: self.window!, duration: 1, options: .transitionCrossDissolve , animations: {
            self.window!.rootViewController = vc
        }, completion: nil)
        
    }
    
    func logOut() {
        showLoginScreen (duration: 1)
        
        if Login.deleteToken() {
            print("se borro a la chingada")
        }
    }
    
    func logIn(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "appNavController")
        vc.view.frame = (self.window!.rootViewController?.view.frame)!
        vc.view.layoutIfNeeded()
        
        UIView.transition(with: self.window!, duration: 1, options: .transitionCrossDissolve, animations: {
            self.window!.rootViewController = vc
        }, completion: nil)
    }
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        sessionTimer = RepeatingTimer(timeInterval: 1)
        sessionTimer?.eventHandler = {
            let alert = UIAlertController(title: "Sesion invalida", message: "Tu sesion a caducado por inactividad.",preferredStyle: .alert)
            alert.popoverPresentationController?.sourceView = self.window?.rootViewController?.view
            alert.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection()
            alert.popoverPresentationController?.sourceRect = CGRect(x: (self.window?.rootViewController?.view.bounds.midX)!, y: (self.window?.rootViewController?.view.bounds.midY)!, width: 0, height: 0)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:{ action in
                self.logOut()
            }))
            
            self.window?.rootViewController?.present(alert, animated: true, completion: nil)
        }
        sessionTimer?.resume()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if sessionTimer != nil {
            sessionTimer?.cancel()
            sessionTimer = nil
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

