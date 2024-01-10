//
//  UIImageView.swift
//  tvOS
//
//  Created by Fitzgerald Afful on 20/07/2021.
//

import UIKit
import Nuke

extension UIImageView {
    func setImage(_ imageUrl: String?) {
        if imageUrl == nil {
            return
        }
        if let url = URL(string: imageUrl!) {
            Nuke.loadImage(with: url, into: self)
        }
    }

    func tint(color: UIColor) {
            self.image = self.image?.withRenderingMode(.alwaysTemplate)
            self.tintColor = color
        }

}
