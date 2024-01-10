//
//  Async Art
//
//  Created by Fitzgerald Afful on 26/06/21.
//

import RealmSwift
import UIKit
import ModernAVPlayer
import AVKit

var currentlyPlayedArtwork: Artwork?

class MusicSlideShowController: UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bgImageView: CachedImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var playButton: ClearCircleButton!
    @IBOutlet weak var previousButton: ClearCircleButton!
    @IBOutlet weak var nextButton: ClearCircleButton!
    @IBOutlet weak var repeatButton: ClearCircleButton!
    @IBOutlet weak var moreDetailsButton: UIButton!
    @IBOutlet weak var bufferLoader: UIActivityIndicatorView!
    @IBOutlet weak var bufferConstraint: NSLayoutConstraint!
    @IBOutlet weak var stemLabel: UILabel!
    @IBOutlet weak var stemTitleLabel: UILabel!
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    @IBOutlet weak var remainingTimeLabel: UILabel!
    @IBOutlet weak var slider: Slider!
    var isScrubbing: Bool = false

    let flowLayout = MusicSlideShowFlowLayout()
    var results: Results<Artwork>?
    var currentIndex = 0
    var oldIndex = 0
    var currentlyPlayedIndex = -1
    var setPlayFocused = false
    var preFocus = true
    var fromSearch = false

    var artworks: [Artwork] {
        get {
            if let arts = results {
                return Array(arts)
            }
            return []
        }
    }

    var notificationToken: NotificationToken?

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.bufferLoader.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        oldIndex = currentIndex
        slider.addTarget(self, action: #selector(sliderValueChanges), for: .touchDragInside)
        slider.addTarget(self, action: #selector(scrubbingStopped), for: .touchDragExit)
        collectionView.register(MusicSlideShowCell.self, forCellWithReuseIdentifier: MusicSlideShowCell.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false
        collectionView.collectionViewLayout = flowLayout
        collectionView.remembersLastFocusedIndexPath = false
        collectionView.contentInsetAdjustmentBehavior = .always
        collectionView.reloadData()
        setupButtons()
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.updateMetaData(index: self.oldIndex)
            self.moveToItem(index: self.oldIndex, playMusic: true)
            delay(1.0) { [self] in
                self.setPlayFocused = true
                self.setNeedsFocusUpdate()
                self.updateFocusIfNeeded()
                self.setPlayFocused = false
                self.preFocus = false
                recordView()

                notificationToken = results?.observe({ [weak self] (changes) in
                    self?.didObserveRealmChanges(changes)
                })
            }
        }
        collectionView.reloadData()
        CATransaction.commit()
        player.delegate = self
    }

    private func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Artwork>>) {
        switch changes {
        case .initial(_):
            collectionView.reloadData()
        case .update(_, let deletions, let insertions, let modifications):
            collectionView.performBatchUpdates({
                collectionView.deleteItems(at: deletions.map{ IndexPath(row: $0, section: 0)})
                collectionView.insertItems(at: insertions.map{ IndexPath(row: $0, section: 0)})
                collectionView.reloadItems(at: modifications.map{ IndexPath(row: $0, section: 0)})
            })
        case .error(let error):
            print(error)
        }
    }

    private func recordView() {
        let artwork = artworks[currentIndex];
        if let slug = artwork.slug {
            let task = ApiClient.shared.recordView(slug: slug)
            task.resume()
        }
    }

    func getArtDetails() {
        if let slug = artworks[currentIndex].slug {
            AppRealm.getArt(slug: slug) { error, newArtwork in
                print("Get Art Details")
            }
        }
    }

    func setupData() {
        ///check for current song playing so when you return to player screen from another controller, player still shows
        if currentlyPlayedArtwork == artworks[currentIndex] && player.state == .playing {
            updateCurrentData(indexPath: IndexPath(item: currentIndex, section: 0))
            return
        }

        if currentlyPlayedIndex == currentIndex && fromSearch == false {
            player.play()
            return
        }
        player.delegate = self
        var dataSource: [MediaResource] = []
        for item in artworks {
            dataSource.append(.custom(item.audioURL!))
        }
        TrackingEvent.musicPiecePlayed.send(withProperties: ["slug": artworks[currentIndex].slug ?? ""])
        let media = dataSource[currentIndex].playerMedia
        currentlyPlayedArtwork = artworks[currentIndex]
        self.currentlyPlayedIndex = currentIndex
        self.slider.setValue(Float(0), animated: true)
        player.load(media: media , autostart: true)
        player.play()
    }

    func setupButtons() {
        repeatButton.bgFillColor = .clear
        self.setPlayButtonState(forAudioPlayerState: .stopped)
        nextButton.isEnabled = currentIndex != (artworks.count - 1)
    }

    @IBAction func showDetails(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MusicFullScreen") as! MusicFullScreenViewController
        vc.artwork = artworks[currentIndex]
        TrackingEvent.musicPieceDetailsViewed.send(withProperties: ["slug": vc.artwork.slug ?? ""])
        self.present(vc, animated: true, completion: nil)
    }

    @objc func sliderValueChanges(slider: Slider) {
        isScrubbing = true
        let artwork = artworks[currentIndex]
        let actualCurrentTime = player.currentTime.isNaN ? 0 : player.currentTime
        var totalTime = Double(artwork.metadata!.audio!.duration.value ?? 0) != 0 ? Double(artwork.metadata!.audio!.duration.value ?? 0) : CMTimeGetSeconds(player.player.currentItem?.duration ?? CMTime.zero)
        if totalTime.isNaN {
            totalTime = 0.0
        }
        let seekTime = Double(slider.value / slider.maximumValue) * totalTime
        player.seek(offset: seekTime - actualCurrentTime)
        updateTimeValues()
    }

    @objc func scrubbingStopped(slider: Slider) {
        isScrubbing = false
    }

    func updateTimeValues(currentTime: Double = player.currentTime) {
        let actualCurrentTime = currentTime.isNaN ? 0 : currentTime
        let artwork = artworks[currentIndex]
        var totalTime = Double(artwork.metadata!.audio!.duration.value ?? 0) != 0 ? Double(artwork.metadata!.audio!.duration.value ?? 0) : CMTimeGetSeconds(player.player.currentItem?.duration ?? CMTime.zero)
        if totalTime.isNaN {
            totalTime = 0.0
        }
        if actualCurrentTime != 0 && totalTime != 0 {
            self.slider.minimumValue = 0.0
            self.slider.maximumValue = Float(totalTime)
            if !isScrubbing {
                self.slider.setValue(Float(actualCurrentTime), animated: true)
            }
            self.bufferConstraint.constant = self.slider.thumbViewCenterXConstraint.constant - 8
        } else {
            self.slider.setValue(Float(0), animated: true)
            self.bufferConstraint.constant =  -10
        }
        self.elapsedTimeLabel.text = actualCurrentTime.secondsToString()
        self.remainingTimeLabel.text = totalTime.asString(style: .positional)
    }

    @IBAction func play(_ sender: Any) {
        if (player.state == .playing) {
            player.pause()
            return
        }
        setupData()
    }

    @IBAction func next(_ sender: Any) {
        moveToItem(index: (currentIndex + 1 < artworks.count) ? currentIndex + 1 : 0)
    }

    @IBAction func previous(_ sender: Any) {
        moveToItem(index: currentIndex != 0 ? currentIndex - 1 : 0)
    }

    func moveToItem(index: Int, playMusic: Bool = true) {
        self.currentIndex = index
        let indexPath = IndexPath(item: currentIndex, section: 0)
        print("Mooooove \(indexPath)")
        self.updateCurrentData(indexPath: indexPath)
        self.getArtDetails()
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        delay(0.5) {
            if (player.state == .playing || player.state == .stopped || player.state == .initialization) && playMusic {
                self.setupData()
            } else {
                player.pause()
            }
            if let cell = self.collectionView.cellForItem(at: indexPath) as? MusicSlideShowCell {
                UIView.transition(with: self.bgImageView, duration: 0.5, options: .transitionCrossDissolve,
                    animations: { self.bgImageView.image = cell.imageView.image }, completion: nil)
            }
        }
        self.collectionView.reloadSections(IndexSet(arrayLiteral: 0))
    }

    @IBAction func toggleRepeat(_ sender: Any) {
        repeatButton.toggleRepeatMode(mode: repeatMode)
    }

    func setPlayButtonState(forAudioPlayerState state: ModernAVPlayer.State) {
        playButton.setPlayingButtonStates(state: state)
        nextButton.setNextButtonStates(state: state)
        previousButton.setPreviousButtonStates(state: state, currentIndex: self.currentIndex)
        repeatButton.setRepeatButtonStates(mode: repeatMode)
    }

    func updateMetaData(index: Int) {
        print("Update Meta Data")
        let artwork = artworks[index]
        self.titleLabel.text = artwork.title
        let artist = Array(artwork.artists).map({ $0.displayName ?? "" }).joined(separator: ", ")
        self.artistLabel.text = artist
        //stemLabel.text = artwork.mixId ?? ""
        self.stemLabel.text = artist
        self.stemTitleLabel.text = artwork.title
    }
}

extension MusicSlideShowController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return artworks.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MusicSlideShowCell.identifier, for: indexPath)
        if let cell = cell as? MusicSlideShowCell {
            cell.configure(from: artworks[indexPath.row], size: flowLayout.itemSize)
            if currentIndex == indexPath.item {
                cell.scaleUp()
            } else {
                cell.resetScale()
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        return !preFocus
    }

    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let indexPath = context.nextFocusedIndexPath {
            currentIndex = indexPath.item
            self.updateCurrentData(indexPath: indexPath)
            collectionView.isScrollEnabled = false
            coordinator.addCoordinatedAnimations({
                self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                self.getArtDetails()
                if let cell = self.collectionView.cellForItem(at: indexPath) as? MusicSlideShowCell {
                    cell.scaleUpFocus()
                    delay(0.5) {
                        UIView.transition(with: self.bgImageView, duration: 0.5, options: .transitionCrossDissolve,
                            animations: { self.bgImageView.image = cell.imageView.image }, completion: nil)
                    }
                }
            }, completion: nil)
        }

        if let prevIndex = context.previouslyFocusedIndexPath {
            if let cell = collectionView.cellForItem(at: prevIndex) as? MusicSlideShowCell {
                cell.resetScale()
            }
        }

        if(context.nextFocusedIndexPath == nil && context.previouslyFocusedIndexPath != nil) {
            if let cell = collectionView.cellForItem(at: context.previouslyFocusedIndexPath!) as? MusicSlideShowCell {
                cell.scaleUp()
            }
        }

        if(context.nextFocusedIndexPath != nil && context.previouslyFocusedIndexPath != nil && (player.state == .playing || player.state == .loading || player.state == .loaded || player.state == .buffering)) {
            self.setupData()
        }
    }

    override weak var preferredFocusedView: UIView? {
        return setPlayFocused ? self.playButton : nil
    }

    func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        let indexPath = IndexPath(item: currentIndex, section: 0)
        //self.updateCurrentData(indexPath: indexPath)
        return indexPath
    }

    func updateCurrentData(indexPath: IndexPath) {
        updateMetaData(index: indexPath.item)
        if let cell = collectionView.cellForItem(at: indexPath) as? MusicSlideShowCell {
            cell.overlay.backgroundColor = .clear
            cell.scaleUp()

            setPlayButtonState(forAudioPlayerState: player.state)
            if player.state != .paused && player.state != .stopped {
                updateTimeValues()
                return
            }
            if currentIndex != currentlyPlayedIndex {
                updateTimeValues(currentTime: 0)
            }
        }
    }
}

extension MusicSlideShowController: ModernAVPlayerDelegate {
    func modernAVPlayer(_ player: ModernAVPlayer, didStateChange state: ModernAVPlayer.State) {
        DispatchQueue.main.async {
            print(state.description)
            self.setPlayButtonState(forAudioPlayerState: state)
            switch state {
            case .buffering, .waitingForNetwork, .loading:
                delay(0.8) {
                    if player.state == .buffering || player.state == .waitingForNetwork || player.state == .loading {
                        self.bufferLoader.isHidden = false
                    }
                }
            case .playing, .paused:
                self.bufferLoader.isHidden = true
                self.updateTimeValues()
            case .stopped:
                switch repeatMode {
                case .repeatAll, .repeatNone:
                    self.next(self.nextButton!)
                case .repeatOnce:
                    self.setupData()
                }
            default:
                break
            }
        }
    }

    func modernAVPlayer(_ player: ModernAVPlayer, didCurrentTimeChange currentTime: Double) {
        DispatchQueue.main.async {
            self.updateTimeValues(currentTime: currentTime)
        }
    }
}

extension MusicSlideShowController {
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for item in presses {
            if item.type == .playPause {
                self.play(playButton!)
            }

            if item.type == .menu && player.state == .playing {
                player.pause()
            }
        }
    }

    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        return  !(moreDetailsButton.isFocused && context.focusHeading == .up)
    }
}
