//
//  UIFont.swift
//  tvOS
//
//  Created by Fitzgerald Afful on 23/06/2021.
//

import Foundation
import UIKit

extension UIFont {

    static func regular(size: Int = 16) -> UIFont {
        return self.baseFontAction(name: "Chivo-Regular", size: size)
    }

    static func medium(size: Int = 16) -> UIFont {
        return self.baseFontAction(name: "Chivo-Regular", size: size)
    }

    static func bold(size: Int = 16) -> UIFont {
        return self.baseFontAction(name: "Chivo-Bold", size: size)
    }

    static func baseFontAction(name: String, size: Int) -> UIFont {
        guard let customFont = UIFont(name: name, size: CGFloat(size)) else {
            return UIFont.systemFont(ofSize: CGFloat(size))
        }
        return UIFontMetrics.default.scaledFont(for: customFont)
    }

    static func getBlackAttributes(size: Int = 13) -> [NSAttributedString.Key: Any] {
        return [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont.medium(size: size)]
    }

    public func hasGlyph(utf32 character:UInt32) -> Bool {

        var code_point: [UniChar] = [ UniChar.init(character), UniChar.init(character >> 16) ]
        var glyphs: [CGGlyph] = [0,0]
        let hasGlyph = CTFontGetGlyphsForCharacters(self as CTFont, &code_point, &glyphs, glyphs.count)
        return hasGlyph
    }
}
