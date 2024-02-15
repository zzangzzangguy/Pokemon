//
//  AppDelegate.swift
//  Pokemon
//
//  Created by 강호성 on 2/9/24.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        AppAppearance.setupAppearance()
        return true
    }
}
