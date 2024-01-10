//
//  FrameSettings.swift
//  tvOS
//
//  Created by Francis Li on 6/10/20.
//

import CoreImage
import CryptoKit
import Foundation
import UIKit

enum FrameSettingsKey: String, CustomStringConvertible {
    case isFrameVisible, frameColor, isMatboardVisible, matColor, orientation, isBlurredEdgesVisible, isZoomFillEnabled

    var description: String {
        return NSLocalizedString("FrameSettingsKey.\(rawValue)", comment: "")
    }
}

enum FrameColor: String, CustomStringConvertible, CaseIterable {
    case black, gold, lightWood, darkWood

    var description: String {
        return NSLocalizedString("FrameColor.\(rawValue)", comment: "")
    }
    
    var image: UIImage {
        return UIImage(named: "\(rawValue)Frame")!
    }

    var insets: UIEdgeInsets {
        switch self {
        case .black:
            return UIEdgeInsets(top: 62 * UIScreen.main.scale,
                                left: 65 * UIScreen.main.scale,
                                bottom: 62 * UIScreen.main.scale,
                                right: 65 * UIScreen.main.scale)
        case .gold:
            return UIEdgeInsets(top: 40 * UIScreen.main.scale,
                                left: 40 * UIScreen.main.scale,
                                bottom: 36 * UIScreen.main.scale,
                                right: 36 * UIScreen.main.scale)
        case .lightWood, .darkWood:
            return UIEdgeInsets(top: 58 * UIScreen.main.scale,
                                left: 59 * UIScreen.main.scale,
                                bottom: 57 * UIScreen.main.scale,
                                right: 56 * UIScreen.main.scale)
        }
    }
}

enum MatColor: String, CustomStringConvertible, CaseIterable {
    case white, black, blue, warm

    var description: String {
        return NSLocalizedString("MatColor.\(rawValue)", comment: "")
    }

    var image: UIImage {
        return UIImage(named: "\(rawValue)Matboard")!
    }

    var edgeImage: UIImage {
        if let image = UIImage(named: "\(rawValue)MatboardEdge") {
            return image
        }
        return UIImage(named: "whiteMatboardEdge")!
    }
}

enum Orientation: String, CustomStringConvertible {
    case landscape, portrait
    
    var description: String {
        return NSLocalizedString("Orientation.\(rawValue)", comment: "")
    }
}

protocol FrameSettingsDelegate: NSObject {
    func frameSettings(_ settings: FrameSettings, didSetValueFor key: FrameSettingsKey)
}

class FrameSettings {
    private var artwork: Artwork!
    private var dict: [String: Any]!

    weak var delegate: FrameSettingsDelegate?
    
    init(artwork: Artwork, dictionary: [String: Any]) {
        self.artwork = artwork
        self.dict = dictionary
    }

    var fingerprint: String {
        /// create a new dictionary with values (so that it includes default values that might be missing from underlying backing dict)
        let obj: [String: Any] = [
            FrameSettingsKey.isFrameVisible.rawValue: isFrameVisible,
            FrameSettingsKey.frameColor.rawValue: frameColor.rawValue,
            FrameSettingsKey.isMatboardVisible.rawValue: isMatboardVisible,
            FrameSettingsKey.matColor.rawValue: matColor.rawValue,
            FrameSettingsKey.isBlurredEdgesVisible.rawValue: isBlurredEdgesVisible,
            FrameSettingsKey.isZoomFillEnabled.rawValue: isZoomFillEnabled,
            FrameSettingsKey.orientation.rawValue: orientation.rawValue
        ]
        /// convert to a sorted key json for determinism
        let data = try! JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys])
        /// calculate a sha hash as the fingerprint, without the human readable prefix
        var hash = SHA256.hash(data: data).description
        if hash.starts(with: "SHA256 digest: ") {
            hash = String(hash[hash.index(hash.startIndex, offsetBy: 15)...])
        }
        return hash
    }
    
    func valueForKey(_ key: FrameSettingsKey) -> Any? {
        return dict[key.rawValue]
    }

    func setValue(_ value: Any, forKey key: FrameSettingsKey) {
        dict[key.rawValue] = value
        didSetValue(for: key)
    }

    var isFrameVisible: Bool {
        get { return dict[FrameSettingsKey.isFrameVisible.rawValue] as? Bool ?? false }
        set { dict[FrameSettingsKey.isFrameVisible.rawValue] = newValue; didSetValue(for: .isFrameVisible) }
    }

    var frameColor: FrameColor {
        get { return FrameColor(rawValue: dict[FrameSettingsKey.frameColor.rawValue] as? String ?? "") ?? .black }
        set { dict[FrameSettingsKey.frameColor.rawValue] = newValue.rawValue; didSetValue(for: .frameColor) }
    }
    
    var isMatboardVisible: Bool {
        get { return dict[FrameSettingsKey.isMatboardVisible.rawValue] as? Bool ?? false }
        set { dict[FrameSettingsKey.isMatboardVisible.rawValue] = newValue; didSetValue(for: .isMatboardVisible) }
    }

    var matColor: MatColor {
        get { return MatColor(rawValue: dict[FrameSettingsKey.matColor.rawValue] as? String ?? "") ?? .white }
        set { dict[FrameSettingsKey.matColor.rawValue] = newValue.rawValue; didSetValue(for: .matColor) }
    }
    
    var orientation: Orientation {
        get { return Orientation(rawValue: dict[FrameSettingsKey.orientation.rawValue] as? String ?? "") ?? .landscape }
        set { dict[FrameSettingsKey.orientation.rawValue] = newValue.rawValue; didSetValue(for: .orientation) }
    }

    var isBlurredEdgesVisible: Bool {
        get { return dict[FrameSettingsKey.isBlurredEdgesVisible.rawValue] as? Bool ?? false }
        set { dict[FrameSettingsKey.isBlurredEdgesVisible.rawValue] = newValue; didSetValue(for: .isBlurredEdgesVisible) }
    }

    var isZoomFillEnabled: Bool {
        get { return dict[FrameSettingsKey.isZoomFillEnabled.rawValue] as? Bool ?? false }
        set { dict[FrameSettingsKey.isZoomFillEnabled.rawValue] = newValue; didSetValue(for: .isZoomFillEnabled) }
    }

    private func didSetValue(for key: FrameSettingsKey) {
        Globals.setFrameSettings(dict, for: artwork)
        delegate?.frameSettings(self, didSetValueFor: key)
    }

    func generateFramedImage(from image: UIImage) -> UIImage {
        var size = UIScreen.main.bounds.size
        size.width *= UIScreen.main.scale
        size.height *= UIScreen.main.scale
        let frame = CGRect(origin: .zero, size: size)
        var rect = frame
        var image = image
        let renderer = UIGraphicsImageRenderer(size: size)
        image = renderer.image(actions: { (context) in
            var insets: UIEdgeInsets = .zero
            var inset: CGFloat = 0
            if isFrameVisible {
                /// add frame insets (frame will draw later on top of matboard/image)
                insets = frameColor.insets
            }
            if isMatboardVisible {
                /// load matboard image and draw
                matColor.image.draw(in: frame)
                /// add a minimum inset for the matboard
                inset = 45 * UIScreen.main.scale
                insets.top += inset
                insets.left += inset
                insets.bottom += inset
                insets.right += inset
            }
            /// rotate  as needed
            if orientation == .portrait {
                context.cgContext.translateBy(x: size.width / 2, y: size.height / 2)
                context.cgContext.rotate(by: -.pi / 2)
                context.cgContext.translateBy(x: -size.height / 2, y: -size.width / 2)
                rect.size.width = size.height
                rect.size.height = size.width
            }
            /// adjust the artwork area by frame/matboard insets
            var imageSize = image.size
            var rect = rect.inset(by: insets)
            if isMatboardVisible {
                imageSize = scale(imageSize, toFit: rect.size, isScaleUpAllowed: true)
            } else if isFrameVisible {
                imageSize = scale(imageSize, toFill: rect.size)
            } else {
                if isBlurredEdgesVisible {
                    /// draw a filled/blurred version behind final image
                    if var ciImage = CIImage(image: image) {
                        /// blur image
                        if let blurFilter = CIFilter(name: "CIGaussianBlur") {
                            let blurRadius: CGFloat = 20.0
                            blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
                            blurFilter.setValue(blurRadius, forKey: kCIInputRadiusKey)
                            ciImage = blurFilter.outputImage ?? ciImage
                            /// crop out empty edges
                            ciImage = ciImage.cropped(to: ciImage.extent.insetBy(dx: 4 * blurRadius, dy: 4 * blurRadius))
                        }
                        /// darken image a bit
                        if let darkenFilter = CIFilter(name: "CIExposureAdjust") {
                            darkenFilter.setValue(ciImage, forKey: kCIInputImageKey)
                            darkenFilter.setValue(-2.0, forKey: kCIInputEVKey)
                            ciImage = darkenFilter.outputImage ?? ciImage
                        }
                        let ciContext = CIContext()
                        if let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) {
                            let image = UIImage(cgImage: cgImage)
                            let fillSize = scale(image.size, toFill: rect.size)
                            let fillRect = CGRect(origin: CGPoint(x: floor((rect.width - fillSize.width) / 2), y: floor((rect.height - fillSize.height) / 2)), size: fillSize)
                            image.draw(in: fillRect)
                        }
                    }
                }
                if isZoomFillEnabled {
                    /// scale the target image size to fill
                    imageSize = scale(imageSize, toFill: rect.size)
                } else {
                    /// scale up to fit
                    imageSize = scale(imageSize, toFit: rect.size, isScaleUpAllowed: true)
                }
            }
            /// center in rect
            rect.origin.x += floor((rect.width - imageSize.width) / 2)
            rect.origin.y += floor((rect.height - imageSize.height) / 2)
            rect.size = imageSize
            image.draw(in: rect)
            if isMatboardVisible {
                /// also add matboard bevels
                inset = -5 * UIScreen.main.scale
                rect = rect.insetBy(dx: inset, dy: inset)
                inset = 6 * UIScreen.main.scale
                drawCustomNineSlice(context: context, image: matColor.edgeImage, with: UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset), in: rect)
            }
            /// finally draw frame
            if isFrameVisible {
                if orientation == .portrait {
                    /// rotate back to normal orientation
                    context.cgContext.translateBy(x: size.height / 2, y: size.width / 2)
                    context.cgContext.rotate(by: .pi / 2)
                    context.cgContext.translateBy(x: -size.width / 2, y: -size.height / 2)
                }
                frameColor.image.draw(in: frame)
            }
        })
        return image
    }

    private func scale(_ imageSize: CGSize, toFit rectSize: CGSize, isScaleUpAllowed: Bool = false) -> CGSize {
        var fitSize = imageSize
        if isScaleUpAllowed || imageSize.width > rectSize.width || imageSize.height > rectSize.height {
            /// scale to fit in rect
            let w = rectSize.width / imageSize.width
            let h = rectSize.height / imageSize.height
            if h < w {
                fitSize.width = floor(rectSize.height * imageSize.width / imageSize.height)
                fitSize.height = rectSize.height
            } else if h > w {
                fitSize.height = floor(rectSize.width * imageSize.height / imageSize.width)
                fitSize.width = rectSize.width
            } else {
                fitSize = rectSize
            }
        }
        return fitSize
    }

    private func scale(_ imageSize: CGSize, toFill rectSize: CGSize) -> CGSize {
        var fillSize = imageSize
        /// scale to fill in rect
        let w = rectSize.width / imageSize.width
        let h = rectSize.height / imageSize.height
        if w > h {
            fillSize.width = floor(imageSize.width * w)
            fillSize.height = floor(imageSize.height * w)
        } else if w < h {
            fillSize.width = floor(imageSize.width * h)
            fillSize.height = floor(imageSize.height * h)
        } else {
            fillSize = rectSize
        }
        return fillSize
    }

    private func drawCustomNineSlice(context: UIGraphicsImageRendererContext, image: UIImage, with capInsets: UIEdgeInsets, in rect: CGRect) {
        var clipRect = CGRect(origin: rect.origin, size: CGSize(width: capInsets.left, height: capInsets.top))
        var imageRect = CGRect(origin: rect.origin, size: image.size)
        imageRect.size.width *= UIScreen.main.scale
        imageRect.size.height *= UIScreen.main.scale
        /// upper left corner
        context.cgContext.clip(to: clipRect)
        image.draw(in: imageRect)
        /// upper right corner
        clipRect = CGRect(origin: CGPoint(x: rect.maxX - capInsets.right, y: rect.minY), size: CGSize(width: capInsets.right, height: capInsets.top))
        imageRect.origin = CGPoint(x: rect.maxX - imageRect.width, y: rect.minY)
        context.cgContext.resetClip()
        context.cgContext.clip(to: clipRect)
        image.draw(in: imageRect)
        /// lower left corner
        clipRect = CGRect(origin: CGPoint(x: rect.minX, y: rect.maxY - capInsets.bottom), size: CGSize(width: capInsets.left, height: capInsets.bottom))
        imageRect.origin = CGPoint(x: rect.minX, y: rect.maxY - imageRect.height)
        context.cgContext.resetClip()
        context.cgContext.clip(to: clipRect)
        image.draw(in: imageRect)
        /// lower right corner
        clipRect = CGRect(origin: CGPoint(x: rect.maxX - capInsets.right, y: rect.maxY - capInsets.bottom), size: CGSize(width: capInsets.right, height: capInsets.bottom))
        imageRect.origin = CGPoint(x: rect.maxX - imageRect.width, y: rect.maxY - imageRect.height)
        context.cgContext.resetClip()
        context.cgContext.clip(to: clipRect)
        image.draw(in: imageRect)
        /// top
        clipRect = CGRect(origin: CGPoint(x: rect.minX + capInsets.left, y: rect.minY), size: CGSize(width: imageRect.width - capInsets.left - capInsets.right, height: capInsets.top))
        imageRect.origin = rect.origin
        while clipRect.width > 0 {
            context.cgContext.resetClip()
            context.cgContext.clip(to: clipRect)
            image.draw(in: imageRect)
            clipRect.origin.x += clipRect.width
            clipRect.size.width = min(clipRect.width, rect.maxX - capInsets.right - clipRect.origin.x)
            imageRect.origin.x = clipRect.origin.x - capInsets.left
        }
        /// bottom
        clipRect = CGRect(origin: CGPoint(x: rect.minX + capInsets.left, y: rect.maxY - capInsets.bottom), size: CGSize(width: imageRect.width - capInsets.left - capInsets.right, height: capInsets.bottom))
        imageRect.origin = CGPoint(x: rect.minX, y: rect.maxY - imageRect.height)
        while clipRect.width > 0 {
            context.cgContext.resetClip()
            context.cgContext.clip(to: clipRect)
            image.draw(in: imageRect)
            clipRect.origin.x += clipRect.width
            clipRect.size.width = min(clipRect.width, rect.maxX - capInsets.right - clipRect.origin.x)
            imageRect.origin.x = clipRect.origin.x - capInsets.left
        }
        /// left
        clipRect = CGRect(origin: CGPoint(x: rect.minX, y: rect.minY + capInsets.top), size: CGSize(width: capInsets.left, height: imageRect.height - capInsets.top - capInsets.bottom))
        imageRect.origin = rect.origin
        while clipRect.height > 0 {
            context.cgContext.resetClip()
            context.cgContext.clip(to: clipRect)
            image.draw(in: imageRect)
            clipRect.origin.y += clipRect.height
            clipRect.size.height = min(clipRect.height, rect.maxY - capInsets.bottom - clipRect.origin.y)
            imageRect.origin.y = clipRect.origin.y - capInsets.top
        }
        /// right
        clipRect = CGRect(origin: CGPoint(x: rect.maxX - capInsets.right, y: rect.minY + capInsets.top), size: CGSize(width: capInsets.right, height: imageRect.height - capInsets.top - capInsets.bottom))
        imageRect.origin = CGPoint(x: rect.maxX - imageRect.width, y: rect.minY)
        while clipRect.height > 0 {
            context.cgContext.resetClip()
            context.cgContext.clip(to: clipRect)
            image.draw(in: imageRect)
            clipRect.origin.y += clipRect.height
            clipRect.size.height = min(clipRect.height, rect.maxY - capInsets.bottom - clipRect.origin.y)
            imageRect.origin.y = clipRect.origin.y - capInsets.top
        }
        context.cgContext.resetClip()
    }
}
