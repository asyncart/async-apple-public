//
//  FullScreenViewController.swift
//  tvOS
//
//  Created by Francis Li on 5/23/20.
//

import RealmSwift
import UIKit

protocol MusicFullScreenViewControllerDelegate: NSObject {
    func fullScreenViewController(_ vc: MusicFullScreenViewController, didChangeOverlayState overlayState: FullScreenOverlayState)
}

class MusicFullScreenViewController: UIViewController, CachedImageViewDelegate {
    @IBOutlet weak var imageView: CachedImageView!

    @IBOutlet weak var overlayView: UIView!
    weak var overlayViewGradientLayer: CAGradientLayer!
    @IBOutlet weak var blurView: UIVisualEffectView!

    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var masterOwnerLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var descLabelWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var detailsButtonView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var viewsLabelView: UIView!
    @IBOutlet weak var viewsLabel: UILabel!
    @IBOutlet weak var layersLabelView: UIView!
    @IBOutlet weak var layersLabel: UILabel!
    @IBOutlet weak var autonomousView: UIView!
    @IBOutlet weak var autonomousLabel: UILabel!
    @IBOutlet weak var createdLabelView: UIView!
    @IBOutlet weak var createdLabel: UILabel!
    @IBOutlet weak var qrView: UIView!
    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var frameButtonView: UIView!
    @IBOutlet weak var selectGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var playsLabel: UILabel!
    @IBOutlet weak var stemsLabel: UILabel!
    @IBOutlet weak var recordingsMintedLabel: UILabel!
    @IBOutlet weak var possibleCombinationsLabel: UILabel!
    @IBOutlet weak var playsView: UIView!
    @IBOutlet weak var layersView: UIView!
    @IBOutlet weak var recordingsMintedView: UIView!
    
    weak var delegate: MusicFullScreenViewControllerDelegate?
    var artwork: Artwork!
    var notificationToken: NotificationToken?
    var frameSettings: FrameSettings!
    var overlayState: FullScreenOverlayState = .expanded {
        didSet { delegate?.fullScreenViewController(self, didChangeOverlayState: overlayState) }
    }
    var lastFocusChangeAt: Date?

    weak var layerUpdateView: LayerUpdateView!
    var layerUpdateTimer: Timer?
    
    deinit {
        notificationToken?.invalidate()
    }

    func setOverlayState(_ overlayState: FullScreenOverlayState, animated: Bool) {
        let prevOverlayState = self.overlayState
        self.overlayState = overlayState
        updateOverlayState(animated: animated, prevOverlayState: prevOverlayState)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        frameSettings = Globals.frameSettings(for: artwork)
        
        imageView.activityIndicatorViewColor = .white
        imageView.delegate = self
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.black.withAlphaComponent(0).cgColor, UIColor.black.withAlphaComponent(0.85).cgColor]
        gradientLayer.locations = [0, 1]
        overlayView.layer.insertSublayer(gradientLayer, at: 0)
        self.overlayViewGradientLayer = gradientLayer

        updateOverlayState()
        notificationToken?.invalidate()
        reloadArtwork()
        AppRealm.saveArtwork(artworks: [artwork])
        delay(1) { [self] in
            notificationToken = artwork.observe { [weak self] (change) in
                self?.didObserveRealmChange(change)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        overlayViewGradientLayer.frame = overlayView.bounds
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        var environments: [UIFocusEnvironment] = []
        if detailsButtonView != nil {
            environments.append(detailsButtonView)
        }
        if frameButtonView != nil {
            environments.append(frameButtonView)
        }
        if scrollView != nil {
            environments.append(scrollView)
        }
        return environments
    }

    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        var shouldUpdateFocus = super.shouldUpdateFocus(in: context)
        if shouldUpdateFocus {
            let now = Date()
            if let lastFocusChangeAt = lastFocusChangeAt, lastFocusChangeAt.distance(to: now) < 0.25 {
                shouldUpdateFocus = false
            }
            lastFocusChangeAt = now
        }
        return shouldUpdateFocus
    }
    
    private func reloadArtwork() {

        let url = artwork.imageURL
        imageView.setImage(from: url, frameSettings: frameSettings)

        titleLabel.text = artwork.title

        playsView.isHidden = !(artwork.isMusic)
        layersView.isHidden = (artwork.isMusic)
        recordingsMintedView.isHidden = !(artwork.isMusic)
        recordingsMintedLabel.text = "\(artwork.recordings.value ?? 0)"
        playsLabel.text = "\(artwork.viewCount.value ?? 0)"
        possibleCombinationsLabel.text = "\(artwork.possibleCombinations.value ?? 0)"
        stemsLabel.text = "\(artwork.layerCount.value ?? 0)"

        
        if artwork.artists.count > 0 {
            artistLabel.text = artwork.artists.reduce("", { (result, artist) -> String in
                let name = artist.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return result == "" ? name : "\(result), \(name)"
            })
        } else {
            artistLabel.text = artwork.artist?.displayName ?? " "
        }
        
        masterOwnerLabel.text = artwork.owner?.displayName
        
        descLabel.text = artwork.desc
        
        if let value = artwork.viewCount.value {
            viewsLabel.text = "\(value)"
        } else {
            viewsLabel.text = ""
        }
        
        if let value = artwork.layerCount.value {
            layersLabel.text = "\(value)"
        } else {
            layersLabel.text = "0"
        }
        
        autonomousView.isHidden = !(artwork.autonomousMetadata?.autonomousDesc != nil)
        autonomousLabel.text = artwork.autonomousMetadata?.autonomousDesc ?? ""
        if let timezone = artwork.autonomousMetadata?.autonomousTimezone {
            let format = "\(autonomousLabel.text ?? "")\n\n\(NSLocalizedString("Timezone", comment: ""))"
            var range: Range<String.Index>! = format.range(of: NSLocalizedString("Timezone", comment: ""))
            range = range.lowerBound..<(format.index(range.upperBound, offsetBy: -3))
            let text = String(format: format, timezone)
            let attributedText = NSMutableAttributedString(string: text)
            attributedText.addAttributes([
                .font: UIFont(name: "Chivo-Bold", size: 20) as Any
            ], range: NSRange(range, in: text))
            autonomousLabel.attributedText = attributedText
        }

        if let date = artwork.creationDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            createdLabel.text = dateFormatter.string(from: date)
        } else {
            createdLabel.text = " "
        }

        qrImageView.setImage(artwork.qrCodeUrl)
    }

    private func didObserveRealmChange(_ change: ObjectChange<Artwork>) {
        switch change {
        case .change(_, let properties):
            reloadArtwork()
            if layerChanged {
                showLastLayerUpdate()
                layerChanged = false
            }
            /*for property in properties {
                if property.name == "metaLastUpdatedOnBlock" {
                    showLastLayerUpdate()
                    break
                }
            }*/
        case .error(let error):
            print(error)
        case .deleted:
            break
        }
    }

    private func showLastLayerUpdate() {
        layerUpdateTimer?.invalidate()
        guard let metadata = artwork.metadata else { return }
        guard let metaLastUpdatedLayer = metadata.lastUpdatedLayer,
            let layerArtwork = AppRealm.open().object(ofType: Artwork.self, forPrimaryKey: metaLastUpdatedLayer)
            else { return }
        if layerUpdateView == nil {
            let layerUpdateView = LayerUpdateView()
            layerUpdateView.alpha = 0
            layerUpdateView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(layerUpdateView)
            NSLayoutConstraint.activate([
                layerUpdateView.widthAnchor.constraint(equalToConstant: 780),
                layerUpdateView.heightAnchor.constraint(equalToConstant: 384),
                layerUpdateView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 90),
                layerUpdateView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80)
            ])
            UIView.animate(withDuration: 0.25) {
                layerUpdateView.alpha = 1
            }
            self.layerUpdateView = layerUpdateView
        }
        layerUpdateView.update(from: layerArtwork)
        /// hide the layer update after some time
        layerUpdateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false, block: { [weak self] (timer) in
            self?.hideLastLayerUpdate()
        })
    }

    private func hideLastLayerUpdate() {
        guard let layerUpdateView = layerUpdateView else { return }
        UIView.animate(withDuration: 0.25, animations: {
            layerUpdateView.alpha = 0
        }) { [weak self] (finished) in
            layerUpdateView.removeFromSuperview()
            self?.layerUpdateView = nil
        }
    }

    private func updateOverlayState(animated: Bool = false, prevOverlayState: FullScreenOverlayState? = nil) {
        if !isViewLoaded {
            return
        }
        let duration = animated ? 0.25 : 0
        UIView.animate(withDuration: duration, animations: { [weak self] in
            guard let self = self else { return }
            self.overlayView.alpha = 1
            self.scrollViewTopConstraint.constant = 160
            self.titleLabel.numberOfLines = 0
            self.artistLabel.numberOfLines = 0
            self.masterOwnerLabel.numberOfLines = 0
            self.descLabel.numberOfLines = 0
            self.blurView.alpha = 1
            self.detailsButtonView.isHidden = true
            self.frameButtonView.isHidden = true
            self.stackView.isHidden = false
            self.scrollView.isScrollEnabled = true
            self.scrollView.panGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
            if self.artwork.orientation == "LANDSCAPE" {
                self.previewImageView.contentMode = .scaleAspectFit
            } else {
                self.previewImageView.contentMode = .scaleAspectFill
            }
            self.previewImageView.image = self.imageView.image
            self.previewImageView.alpha = 1
            self.view.layoutIfNeeded()
        }, completion: { [weak self] (finished) in
            guard let self = self else { return }
            if let view = self.view as? FullScreenView {
                view.isFocusable = false
            }
            self.setNeedsFocusUpdate()
        })
    }

    // MARK: - CachedImageViewDelegate
    
    func cachedImageView(_ view: CachedImageView, didSetImage image: UIImage) {
        if self.artwork.orientation == "LANDSCAPE" {
            self.previewImageView.contentMode = .scaleAspectFit
        } else {
            self.previewImageView.contentMode = .scaleAspectFill
        }
        previewImageView.image = image
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for item in presses {
            if item.type == .menu && (self.artwork.isMusic) {
                self.dismiss(animated: true, completion: nil)
            }

            if item.type == .playPause {
                if player.state == .playing {
                    player.pause()
                }
            }
        }
    }
}
