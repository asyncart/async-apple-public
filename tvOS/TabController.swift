//
//  TabController.swift
//  tvOS
//
//  Created by Fitzgerald Afful on 09/07/2021.
//

import UIKit
import ModernAVPlayer

class TabController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let tabItem = UITabBarItem(title: nil, image: UIImage(named: "search"), tag: 2)
        self.view.backgroundColor = .white
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SearchViewController") as? SearchViewController {
            vc.view.backgroundColor = .clear
            let searchContainerViewController = UISearchContainerViewController(searchController: vc.searchController)
            let searchNavigationController = UINavigationController(rootViewController: searchContainerViewController)
            searchNavigationController.navigationBar.isTranslucent = true
            searchNavigationController.navigationBar.tintColor = .black
            searchNavigationController.tabBarItem = tabItem

            //searchContainerViewController.tabBarItem = tabItem
            self.viewControllers?.append(searchNavigationController)
        }
        TrackingEvent.tvAppOpened.send()
    }
}
