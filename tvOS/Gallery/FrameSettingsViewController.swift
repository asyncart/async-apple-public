//
//  FrameSettingsViewController.swift
//  tvOS
//
//  Created by Francis Li on 6/10/20.
//

import UIKit

class FrameSettingsViewController: UIViewController, UINavigationControllerDelegate, FrameSettingsDelegate {
    @IBOutlet weak var frameSettingsLabel: UILabel!
    @IBOutlet weak var imageView: CachedImageView!
    private weak var gradientLayer: CAGradientLayer!

    var artwork: Artwork!
    var settings: FrameSettings!

    override func viewDidLoad() {
        super.viewDidLoad()

        /// set as delegate to respond to settings changes
        settings.delegate = self
        /// trigger an update to display the preview image
        frameSettings(settings, didSetValueFor: .frameColor)

        /// update imageView spinner color
        imageView.activityIndicatorViewColor = UIColor(named: "gray")
        
        /// add a gradient overlay
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.black.withAlphaComponent(0).cgColor, UIColor.black.withAlphaComponent(0.85).cgColor]
        gradientLayer.locations = [0, 1]
        view.layer.insertSublayer(gradientLayer, at: 0)
        self.gradientLayer = gradientLayer
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navVC = segue.destination as? UINavigationController,
            let vc = navVC.topViewController as? FrameSettingsTableViewController {
            navVC.delegate = self
            vc.settings = settings
        }
    }

    // MARK: - FrameSettingsDelegate

    func frameSettings(_ settings: FrameSettings, didSetValueFor key: FrameSettingsKey) {
        let url = artwork.imageURL
        imageView.setImage(from: url, frameSettings: settings)
    }
    
    // MARK: - UINavigationControllerDelegate

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let title = viewController.title {
            frameSettingsLabel.text = title
        }
    }
}
