//
//  SlideshowViewController.swift
//  Async Art
//
//  Created by Francis Li on 5/22/20.
//

import RealmSwift
import UIKit

class SlideshowViewController: UIViewController, UIScrollViewDelegate, FullScreenViewControllerDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var prevView: UIView!
    @IBOutlet weak var currentView: UIView!
    @IBOutlet weak var nextView: UIView!

    var artworks: Results<Artwork>!
    var artworkArray: [Artwork]?
    var currentIndex: Int = 0 {
        didSet {
            getArtDetails()
            recordView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        
        //AppRealm.saveArtwork(artworks: artworkArray ?? [])

        if let vc = viewController(at: currentIndex) {
            addChild(vc, to: currentView)
        }
        if let vc = viewController(at: currentIndex - 1) {
            addChild(vc, to: prevView)
        }
        if let vc = viewController(at: currentIndex + 1) {
            addChild(vc, to: nextView)
        }
    }

    //0x4f37310372dd39d451f7022ee587fa8b9f72d80b-4182, 0x4f37310372dd39d451f7022ee587fa8b9f72d80b-4183, 0x4f37310372dd39d451f7022ee587fa8b9f72d80b-4184

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = CGSize(width: nextView.frame.maxX, height: scrollView.frame.height)
        scrollView.setContentOffset(CGPoint(x: currentView.frame.minX, y: 0), animated: false)
    }

    private func recordView() {
        let artwork = artworkArray != nil ? artworkArray![currentIndex] : artworks[currentIndex];
        if let slug = artwork.slug {
            TrackingEvent.artworkViewed.send(withProperties: ["slug": slug])
            let task = ApiClient.shared.recordView(slug: slug)
            task.resume()
        }
    }

    func getArtDetails() {
        let artwork = artworkArray != nil ? artworkArray![currentIndex] : artworks[currentIndex];
        if let slug = artwork.slug {
            AppRealm.getArt(slug: slug) { [self] error, newArtwork in
                if let newArtwork = newArtwork {
                    if artworkArray != nil {
                        artworkArray![currentIndex] = newArtwork
                    }
                }
            }
        }
    }
    
    private func addChild(_ vc: UIViewController, to view: UIView) {
        addChild(vc)
        vc.view.frame = view.bounds
        view.addSubview(vc.view)
        vc.didMove(toParent: self)
    }

    private func moveChild(from: UIView, to: UIView) {
        to.addSubview(from.subviews[0])
    }
    
    private func removeChild(from: UIView) {
        if from.subviews.count > 0 {
            let view = from.subviews[0]
            if let vc = children.first(where: { $0.view == view }) {
                vc.willMove(toParent: nil)
                view.removeFromSuperview()
                vc.removeFromParent()
            }
        }
    }
    
    private func viewController(at index: Int) -> UIViewController? {
        if index < 0 || index >= (artworkArray != nil ? artworkArray!.count : artworks.count) {
            return nil
        }
        var overlayState = FullScreenOverlayState.visible
        if children.count > 0, let vc = children[0] as? FullScreenViewController {
            overlayState = vc.overlayState
        }
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FullScreen") as? FullScreenViewController {
            vc.artwork = artworkArray != nil ? artworkArray![index] : artworks[index]
            vc.overlayState = overlayState
            vc.delegate = self
            return vc
        }
        return nil
    }

    // MARK: - FullScreenViewControllerDelegate

    func fullScreenViewController(_ vc: FullScreenViewController, didChangeOverlayState overlayState: FullScreenOverlayState) {
        /// ignore if not the current
        if let cvc = children.first(where: { $0.view == currentView.subviews[0] }), cvc != vc {
            return
        }
        /// change all other vcs to match
        for cvc in children {
            if let cvc = cvc as? FullScreenViewController, cvc != vc {
                cvc.setOverlayState(overlayState, animated: false)
            }
        }
    }
    
    // MARK: - UIScrollViewDelegate

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let x = scrollView.contentOffset.x
        if x < currentView.frame.minX {
            /// remove next
            removeChild(from: nextView)
            /// move current to next
            moveChild(from: currentView, to: nextView)
            /// move prev to current
            moveChild(from: prevView, to: currentView)
            scrollView.setContentOffset(CGPoint(x: currentView.frame.minX, y: 0), animated: false)
            /// update index, record view
            if let vc = children.first(where: {$0.view == currentView.subviews[0]}) as? FullScreenViewController,
                let index = (artworkArray != nil ? artworkArray! : Array(artworks)).firstIndex(of: vc.artwork) {
                currentIndex = index
            }
            /// load new prev
            if let vc = viewController(at: currentIndex - 1) {
                addChild(vc, to: prevView)
            }
        } else if x >= currentView.frame.maxX {
            /// remove prev
            removeChild(from: prevView)
            /// move current to prev
            moveChild(from: currentView, to: prevView)
            /// move next to current
            moveChild(from: nextView, to: currentView)
            scrollView.setContentOffset(CGPoint(x: currentView.frame.minX, y: 0), animated: false)
            /// update index, record view
            if let vc = children.first(where: {$0.view == currentView.subviews[0]}) as? FullScreenViewController,
                let index = (artworkArray != nil ? artworkArray! : Array(artworks)).firstIndex(of: vc.artwork) {
                currentIndex = index
            }
            /// load new next
            if let vc = viewController(at: currentIndex + 1) {
                addChild(vc, to: nextView)
            }
        }
    }
}
