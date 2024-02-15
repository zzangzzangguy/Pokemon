//
//  TabBarController.swift
//  Pokemon
//
//  Created by 강호성 on 2/15/24.
//

import UIKit

final class TabBarController: UITabBarController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewController()
    }

    // MARK: - Helpers

    private func configureViewController() {
        let list = templateTabBarController(
            unselectedImage: UIImage(systemName: "greetingcard")!,
            selectedImage: UIImage(systemName: "greetingcard.fill")!,
            rootViewController: ListViewController()
        )

        let search = templateTabBarController(
            unselectedImage: UIImage(systemName: "magnifyingglass.circle")!,
            selectedImage: UIImage(systemName: "magnifyingglass.circle.fill")!,
            rootViewController: SearchViewController()
        )

        viewControllers = [list, search]
    }

    private func templateTabBarController(
        unselectedImage: UIImage,
        selectedImage: UIImage,
        rootViewController: UIViewController
    ) -> UINavigationController {
        let nav = UINavigationController(rootViewController: rootViewController)
        nav.tabBarItem.image = unselectedImage
        nav.tabBarItem.selectedImage = selectedImage
        return nav
    }
}
