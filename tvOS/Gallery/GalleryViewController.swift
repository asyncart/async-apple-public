//
//  GalleryViewController.swift
//  Async Art
//
//  Created by Francis Li on 5/22/20.
//

import RealmSwift
import UIKit


class GalleryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tagsCollectionView: UICollectionView!
    var activityIndicatorView: UIActivityIndicatorView!
    
    var notificationToken: NotificationToken?
    var results: Results<Artwork>?
    var filteredResults: Results<Artwork>?
    var tags: [String] = []
    var selectedIndex = 0
    var isFiltered:Bool = false

    deinit {
        print("De-init")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let savedTags = UserDefaultsManager().getData(type: [String].self, forKey: .tags) {
            if !savedTags.isEmpty {
                self.tags = savedTags
                self.tags.insert("All Artworks", at: 0)
                self.tagsCollectionView.reloadData()
            }
        }
        activityIndicatorView = UIActivityIndicatorView(style: .large)
        activityIndicatorView.color = .gray
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.hidesWhenStopped = true
        view.addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        activityIndicatorView.startAnimating()

        collectionView.register(MusicCollectionViewCell.self, forCellWithReuseIdentifier: "artwork")
        collectionView.delegate = self
        collectionView.dataSource = self

        tagsCollectionView.register(UINib(nibName: "TagViewCell", bundle: nil), forCellWithReuseIdentifier: "TagViewCell")
        tagsCollectionView.delegate = self
        tagsCollectionView.dataSource = self
        tagsCollectionView.remembersLastFocusedIndexPath = true

        notificationToken = results?.observe({ [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        notificationToken?.invalidate()
    }

    override func viewWillAppear(_ animated: Bool) {
        results = AppRealm.getMarket(completionHandler: { (error, _) in
        })
        AppRealm.getTags { _, tagsOptional in
            self.tags = tagsOptional ?? []
            self.tags.insert("All Artworks", at: 0)
            DispatchQueue.main.async {
                self.tagsCollectionView.reloadData()
            }
        }
        notificationToken = results?.observe({ [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        })
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
            if view.isVisible && !self.isFiltered {
                collectionView.performBatchUpdates({
                    collectionView.deleteItems(at: deletions.map{ IndexPath(row: $0, section: 0)})
                    collectionView.insertItems(at: insertions.map{ IndexPath(row: $0, section: 0)})
                    collectionView.reloadItems(at: modifications.map{ IndexPath(row: $0, section: 0)})
                })
                return
            }
        case .error(let error):
            print(error)
        }
    }
    
    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == tagsCollectionView {
            return tags.count
        }
        return isFiltered ? (filteredResults?.count ?? 0) : (results?.count ?? 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == tagsCollectionView {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagViewCell", for: indexPath) as? TagViewCell {
                let tagItem = tags[tags.index(tags.startIndex, offsetBy: indexPath.item)]
                cell.configure(from: tagItem)
                if selectedIndex == indexPath.item {
                    cell.isSelectedCell = true
                    cell.titleLabel.textColor = cell.isSelected ? .white : .black
                    cell.titleLabel.font = .bold(size: 26)
                } else {
                    cell.isSelectedCell = false
                    cell.titleLabel.textColor = .gray
                    cell.titleLabel.font = .regular(size: 24)
                }
                return cell
            }
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "artwork", for: indexPath)
        if let cell = cell as? MusicCollectionViewCell,
           let artwork = isFiltered ? filteredResults?[indexPath.row] : results?[indexPath.row],
           let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            print(artwork.artists)
            cell.configure(from: artwork, size: layout.itemSize, isTextDark: true)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == tagsCollectionView {
            let tagItem = tags[tags.index(tags.startIndex, offsetBy: indexPath.item)]
            var width = tagItem.widthOfString(withConstrainedHeight: 56.0, usingFont: .bold(size: 29))
            //If using storyboard and overriding UICollectionViewDelegateFlowLayout then in swift 5 and Xcode 11+, set Estimate size in Storyboard to None
            width = width < 70 ? 70 : width
            return CGSize(width: width + 20, height: 70.0)
        }
        return CGSize(width: 390.0, height: 460.0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == tagsCollectionView {
            return -10
        }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView == tagsCollectionView {
           return UIEdgeInsets(top: -10, left: 10, bottom: 0, right: 10)
        }
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == tagsCollectionView {
            selectedIndex = indexPath.item
            tagsCollectionView.reloadData()
            if indexPath.item != 0 {
                isFiltered = true
                filteredResults = results?.filter(NSPredicate(format: "%@ IN tags", tags[selectedIndex].lowercased().replacingOccurrences(of: " ", with: "-")))
            } else {
                isFiltered = false
            }
            TrackingEvent.tagChanged.send(withProperties: ["tag": tags[selectedIndex]])
            self.collectionView.reloadData()
            return
        }
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Slideshow") as? SlideshowViewController {
            vc.artworks = isFiltered ? filteredResults : results
            vc.currentIndex = indexPath.row
            present(vc, animated: true, completion: nil)
        }
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
