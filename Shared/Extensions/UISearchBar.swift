//
//  UISearchBar.swift
//  tvOS
//
//  Created by Fitzgerald Afful on 09/07/2021.
//

import UIKit

extension UISearchBar {

    public var textField: UITextField? {
        let subViews = subviews.flatMap { $0.subviews }
        guard let textField = (subViews.filter { $0 is UITextField }).first as? UITextField else {
            return nil
        }
        return textField
    }

    public var activityIndicator: UIActivityIndicatorView? {
        return textField?.rightView?.subviews.compactMap{ $0 as? UIActivityIndicatorView }.first
    }

    var isLoading: Bool {
        get {
            return activityIndicator != nil
        } set {
            if newValue {
                if activityIndicator == nil {
                    let newActivityIndicator = UIActivityIndicatorView(style: .medium)
                    newActivityIndicator.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
                    newActivityIndicator.startAnimating()
                    newActivityIndicator.backgroundColor = UIColor.green
                    textField?.rightView?.addSubview(newActivityIndicator)
                    let rightViewSize = textField?.rightView?.frame.size ?? CGSize.zero
                    newActivityIndicator.center = CGPoint(x: rightViewSize.width/2, y: rightViewSize.height/2)
                }
            } else {
                activityIndicator?.removeFromSuperview()
            }
        }
    }

    public func setTextColor(color: UIColor) {
        let svs = subviews.flatMap { $0.subviews }
        for item in svs where item is UITextField {
            (item as! UITextField).textColor = color
            (item as! UITextField).attributedPlaceholder = NSAttributedString(string: "Search", attributes: [NSAttributedString.Key.foregroundColor : UIColor.darkGray])
        }

        for item in svs where item is UIImageView {
            item.tintColor = color
        }
    }

}
