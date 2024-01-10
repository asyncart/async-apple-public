//
//  UIButton.swift
//  tvOS
//
//  Created by Fitzgerald Afful on 29/06/2021.
//

import UIKit

extension UIButton {
    func setMultipleImages(normal: UIImage?, focused: UIImage?, selected: UIImage?) {
        if let normalImage = normal {
            self.setImage(normalImage, for: .normal)
        }
        if let focusedImage = focused {
            self.setImage(focusedImage, for: .focused)
        }
        if let selectedImage = selected {
            self.setImage(selectedImage, for: .selected)
        }
    }
}
