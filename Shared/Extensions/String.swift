//
//  String.swift
//  tvOS
//
//  Created by Fitzgerald Afful on 24/10/2021.
//

import Foundation
import UIKit

extension String {
    func widthOfString(withConstrainedHeight height: CGFloat, usingFont font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(boundingBox.width)
    }
}
