//
//  CircleButton.swift
//  tvOS
//
//  Created by Francis Li on 6/6/20.
//

import UIKit
import ModernAVPlayer

class CircleButton: UIButton {

    var focusedBgFillColor = UIColor(named: "asyncPurple")! {
        didSet {
            let renderer = UIGraphicsImageRenderer(size: bounds.size)
            var image = renderer.image(actions: { (context) in
                context.cgContext.setFillColor(bgFillColor.cgColor)
                context.cgContext.fillEllipse(in: bounds)
            })
            setBackgroundImage(image, for: .normal)

            image = renderer.image(actions: { (context) in
                context.cgContext.setFillColor(focusedBgFillColor.cgColor)
                context.cgContext.fillEllipse(in: bounds)
            })
            setBackgroundImage(image, for: .focused)
            setBackgroundImage(image, for: .selected)
        }
    }
    var bgFillColor = UIColor.white.withAlphaComponent(0.22)

    override func awakeFromNib() {
        super.awakeFromNib()
        
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        var image = renderer.image(actions: { (context) in
            context.cgContext.setFillColor(bgFillColor.cgColor)
            context.cgContext.fillEllipse(in: bounds)
        })
        setBackgroundImage(image, for: .normal)
        
        image = renderer.image(actions: { (context) in
            context.cgContext.setFillColor(focusedBgFillColor.cgColor)
            context.cgContext.fillEllipse(in: bounds)
        })
        setBackgroundImage(image, for: .focused)
        setBackgroundImage(image, for: .selected)
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.transform = (self?.isFocused ?? false) ? CGAffineTransform(scaleX: 1.1, y: 1.1) : CGAffineTransform(scaleX: 1, y: 1)
        }
    }
}


class ClearCircleButton: UIButton {

    var focusedBgFillColor = UIColor.white {
        didSet {
            let renderer = UIGraphicsImageRenderer(size: bounds.size)
            var image = renderer.image(actions: { (context) in
                context.cgContext.setFillColor(bgFillColor.cgColor)
                context.cgContext.fillEllipse(in: bounds)
            })
            setBackgroundImage(image, for: .normal)

            image = renderer.image(actions: { (context) in
                context.cgContext.setFillColor(focusedBgFillColor.cgColor)
                context.cgContext.fillEllipse(in: bounds)
            })
            setBackgroundImage(image, for: .focused)
            setBackgroundImage(image, for: .selected)
        }
    }
    var bgFillColor = UIColor.clear

    override func awakeFromNib() {
        super.awakeFromNib()

        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        var image = renderer.image(actions: { (context) in
            context.cgContext.setFillColor(bgFillColor.cgColor)
            context.cgContext.fillEllipse(in: bounds)
        })
        setBackgroundImage(image, for: .normal)

        image = renderer.image(actions: { (context) in
            context.cgContext.setFillColor(focusedBgFillColor.cgColor)
            context.cgContext.fillEllipse(in: bounds)
        })
        setBackgroundImage(image, for: .focused)
        setBackgroundImage(image, for: .selected)
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.transform = (self?.isFocused ?? false) ? CGAffineTransform(scaleX: 1.1, y: 1.1) : CGAffineTransform(scaleX: 1, y: 1)
        }
    }
}

extension ClearCircleButton {

    func setPlayingButtonStates(state: ModernAVPlayer.State) {
        if state == .playing {
            self.setMultipleImages(normal: UIImage(named: "pause")!.withTintColor(.white), focused: UIImage(named: "pause")!.withTintColor(.black), selected: UIImage(named: "pause")!.withTintColor(.black))
            self.focusedBgFillColor = .white
        } else {
            self.setMultipleImages(normal: UIImage(named: "playButton")!.withTintColor(.white), focused: UIImage(named: "playButton")!.withTintColor(.black), selected: UIImage(named: "playButton")!.withTintColor(.black))
            self.focusedBgFillColor = .white
        }
    }

    func setNextButtonStates(state: ModernAVPlayer.State) {
        self.setMultipleImages(normal: UIImage(named: "next")!.withTintColor(.white), focused: UIImage(named: "next")!.withTintColor(.black), selected: UIImage(named: "next")!.withTintColor(.black))
        self.focusedBgFillColor = .white
    }

    func setPreviousButtonStates(state: ModernAVPlayer.State, currentIndex: Int) {
        self.setMultipleImages(normal: UIImage(named: "previous")!.withTintColor(.white), focused: UIImage(named: "previous")!.withTintColor(.black), selected: UIImage(named: "previous")!.withTintColor(.black))
        self.focusedBgFillColor = .white
        self.isEnabled = currentIndex > 0
    }

    func setRepeatButtonStates(mode: PlayerRepeatMode) {
        switch mode {
        case .repeatNone, .repeatAll:
            self.setMultipleImages(normal: UIImage(named: "repeat")!.withTintColor(.white.withAlphaComponent(0.3)), focused: UIImage(named: "repeat")!.withTintColor(.black.withAlphaComponent(0.3)), selected: UIImage(named: "repeat")!.withTintColor(.black.withAlphaComponent(0.3)))
        default:
            self.setMultipleImages(normal: UIImage(named: "repeat")!.withTintColor(.white), focused: UIImage(named: "repeat")!.withTintColor(.black), selected: UIImage(named: "repeat")!.withTintColor(.black))
        }
        self.focusedBgFillColor = .white
    }

    func toggleRepeatMode(mode: PlayerRepeatMode) {
        switch mode {
        case .repeatNone, .repeatAll:
            repeatMode = .repeatOnce
            UserDefaults.standard.setValue(repeatMode.rawValue, forKey: "repeatMode")
            self.setMultipleImages(normal: UIImage(named: "repeat")!.withTintColor(.white), focused: UIImage(named: "repeat")!.withTintColor(.black), selected: UIImage(named: "repeat")!.withTintColor(.black))
        default:
            repeatMode = .repeatAll
            UserDefaults.standard.setValue(repeatMode.rawValue, forKey: "repeatMode")
            self.setMultipleImages(normal: UIImage(named: "repeat")!.withTintColor(.white.withAlphaComponent(0.3)), focused: UIImage(named: "repeat")!.withTintColor(.black.withAlphaComponent(0.3)), selected: UIImage(named: "repeat")!.withTintColor(.black.withAlphaComponent(0.3)))
        }
    }
}
