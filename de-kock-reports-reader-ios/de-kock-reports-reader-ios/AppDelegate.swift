//
//  AppDelegate.swift
//  de-kock-reports-reader-ios
//
//  Created by Wikan Setiaji on 15/07/25.
//

import UIKit
import Flutter

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  var flutterEngine: FlutterEngine?
  
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    flutterEngine = FlutterEngine(name: "my_engine")
    flutterEngine?.run()
    
    let flutterVC = FlutterViewController(engine: flutterEngine!, nibName: nil, bundle: nil)
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = flutterVC
    window?.makeKeyAndVisible()
    
    return true
  }
}
