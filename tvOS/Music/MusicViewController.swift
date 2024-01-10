//
//  GalleryViewController.swift
//  Async Art
//
//  Created by Francis Li on 5/22/20.
//

import RealmSwift
import UIKit


class MusicViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    var activityIndicatorView: UIActivityIndicatorView!
    
    var notificationToken: NotificationToken?
    var results: Results<Artwork>?

    deinit {
        notificationToken?.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicatorView = UIActivityIndicatorView(style: .large)
        activityIndicatorView.color = .white
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.hidesWhenStopped = true
        view.addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        activityIndicatorView.startAnimating()
        
        collectionView.register(MusicCollectionViewCell.self, forCellWithReuseIdentifier: MusicCollectionViewCell.identifier)
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self

        results = AppRealm.getMusicMarket(errorHandler: { (error) in
            print(error)
        })
        notificationToken = results?.observe({ [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        self.setGradientBackground()
        super.viewWillAppear(animated)
    }

    func setGradientBackground() {
        let colorTop =  UIColor.black.cgColor
        let colorBottom = UIColor(red: 38.0/255.0, green: 5.0/255.0, blue: 108.0/255.0, alpha: 1.0).cgColor

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorTop, colorBottom]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = self.view.bounds

        self.view.layer.insertSublayer(gradientLayer, at:0)
    }

    private func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Artwork>>) {
        switch changes {
        case .initial(_):
            if results?.count ?? 0 > 0 {
                activityIndicatorView.stopAnimating()
                activityIndicatorView.removeFromSuperview()
            }
            collectionView.reloadData()
        case .update(_, let deletions, let insertions, let modifications):
            activityIndicatorView.stopAnimating()
            activityIndicatorView.removeFromSuperview()
            collectionView.performBatchUpdates({
                collectionView.deleteItems(at: deletions.map{ IndexPath(row: $0, section: 0)})
                collectionView.insertItems(at: insertions.map{ IndexPath(row: $0, section: 0)})
                collectionView.reloadItems(at: modifications.map{ IndexPath(row: $0, section: 0)})
            })
        case .error(let error):
            print(error)
        }
    }
    
    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MusicCollectionViewCell.identifier, for: indexPath)
        if let cell = cell as? MusicCollectionViewCell,
           let artwork = results?[indexPath.row],
           let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            cell.configure(from: artwork, size: layout.itemSize)
        }
        return cell
    }

    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MusicSlideShowController") as? MusicSlideShowController {
            vc.results = results
            vc.currentIndex = indexPath.item
            present(vc, animated: true, completion: nil)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 390.0, height: 460.0)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for item in presses {
            if item.type == .playPause {
                if player.state == .playing {
                    player.pause()
                }
            }
        }
    }
}

