//
//  CachedImageView.swift
//  Shared
//
//  Created by Francis Li on 5/23/20.
//

import CryptoKit
import UIKit

protocol CachedImageViewDelegate: NSObject {
    func cachedImageView(_ view: CachedImageView, didSetImage image: UIImage)
}


class CachedImageView: UIImageView {
    private let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .large)
        activityIndicatorView.color = .gray
        return activityIndicatorView
    }()
    private var framedFileURL: URL!
    private var sourceFileURL: URL!
    private var frameSettings: FrameSettings?

    weak var delegate: CachedImageViewDelegate?
    var activityIndicatorViewColor: UIColor! {
        get { return activityIndicatorView.color }
        set { activityIndicatorView.color = newValue }
    }
    var addAutonomousIcon = false
    
    func setImage(from url: URL, frameSettings: FrameSettings? = nil) {
        /// save the frame settings to be applied once we have the image
        self.frameSettings = frameSettings
        /// get the local cached file url for the final framed image
        let framedFileURL = AppRealm.cachedFileURL(for: url, frameSettings: frameSettings)
        self.framedFileURL = framedFileURL
        /// if framed, get the local cached file url for the source image
        let sourceFileURL = frameSettings != nil ? AppRealm.cachedFileURL(for: url) : framedFileURL
        self.sourceFileURL = sourceFileURL
        /// display spinner if the framed file doesn't exist in cache, since will need to download and/or generate it
        if !FileManager.default.fileExists(atPath: framedFileURL.path) {
            activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(activityIndicatorView)
            NSLayoutConstraint.activate([
                activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
                activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
            activityIndicatorView.startAnimating()
        }
        /// perform on background
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            var image: UIImage?
            do {
                /// first check for cached framed file
                if FileManager.default.fileExists(atPath: framedFileURL.path) {
                    image = UIImage(contentsOfFile: framedFileURL.path)
                } else {
                    /// no hit, check for cached source file
                    if FileManager.default.fileExists(atPath: sourceFileURL.path) {
                        image = UIImage(contentsOfFile: sourceFileURL.path)
                    } else {
                        /// no hit, download and cache the source file
                        let data = try Data(contentsOf: url)
                        image = UIImage(data: data)
                        try data.write(to: sourceFileURL)
                    }
                    /// check if we're displaying a framed URL and generate based on settings
                    if let frameSettings = frameSettings, let sourceImage = image {
                        /// generate and cache the framed image
                        image = frameSettings.generateFramedImage(from: sourceImage)
                        if let data = image?.pngData() {
                            try data.write(to: framedFileURL)
                        }
                    }
                }
            } catch {
                print(error)
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.activityIndicatorView.stopAnimating()
                self.activityIndicatorView.removeFromSuperview()
                if self.framedFileURL == framedFileURL, var image = image {
                    if self.addAutonomousIcon {
                        let renderer = UIGraphicsImageRenderer(size: image.size)
                        image = renderer.image(actions: { (context) in
                            image.draw(at: .zero)
                            let autonomousIconView = AutonomousIconView()
                            context.cgContext.translateBy(x: 0, y: image.size.height - autonomousIconView.frame.height * UIScreen.main.scale)
                            context.cgContext.scaleBy(x: UIScreen.main.scale, y: UIScreen.main.scale)
                            autonomousIconView.layer.render(in: context.cgContext)
                        })
                    }
                    self.image = image
                    self.setNeedsDisplay()
                    self.delegate?.cachedImageView(self, didSetImage: image)
                }
            }
        }
    }
}
