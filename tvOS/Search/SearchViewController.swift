//
//  GalleryViewController.swift
//  Async Art
//
//  Created by Francis Li on 5/22/20.
//

import RealmSwift
import UIKit


class SearchViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchResultsUpdating, UISearchBarDelegate {

    func updateSearchResults(for searchController: UISearchController) {
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if self.searchController.searchBar.text!.count < 2 {
            isSearching = false
            self.collectionView.reloadData()
        } else {
            isSearching = true
            self.search(word: searchBar.text!)
        }
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if let searchWord = searchBar.text {
            TrackingEvent.searchedForArtwork.send(withProperties: ["searchWord": searchWord])
        }
    }

    var searchController = UISearchController()

    @IBOutlet weak var collectionView: UICollectionView!

    var activityIndicatorView: UIActivityIndicatorView!
    
    var notificationToken: NotificationToken?
    var results: Results<Artwork>?
    var searchResults: [Artwork] = []
    var isSearching: Bool = false
    var runResults = false

    deinit {
        notificationToken?.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchController = UISearchController(searchResultsController: self)
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self

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
        collectionView.dataSource = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        notificationToken?.invalidate()
    }

    override func viewWillAppear(_ animated: Bool) {
        searchController.searchBar.overrideUserInterfaceStyle = .light
        searchController.searchBar.setTextColor(color: .black)
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).keyboardAppearance = .light
        results = AppRealm.getMarket(completionHandler: { (error, _) in
        })
        /*notificationToken = results?.observe(on: .main, { changes in
            self.didObserveRealmChanges(changes)
        })*/
    }

    override func viewDidLayoutSubviews() {
        searchController.searchBar.overrideUserInterfaceStyle = .light
        searchController.searchBar.setTextColor(color: .black)
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).keyboardAppearance = .light
    }

    override func viewDidAppear(_ animated: Bool) {
        searchController.searchBar.overrideUserInterfaceStyle = .light
        searchController.searchBar.setTextColor(color: .black)
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).keyboardAppearance = .light
    }

    /*private func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Artwork>>) {
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
            if collectionView.isVisible && !isSearching {
                collectionView.performBatchUpdates({
                    collectionView.deleteItems(at: deletions.map{ IndexPath(row: $0, section: 0)})
                    collectionView.insertItems(at: insertions.map{ IndexPath(row: $0, section: 0)})
                    collectionView.reloadItems(at: modifications.map{ IndexPath(row: $0, section: 0)})
                })
            }
        case .error(let error):
            print(error)
        }
    }*/

    func search(word: String) {
        self.searchController.searchBar.isLoading = true
        AppRealm.search(searchWord: word) { searchedWord, artworkResults, error in
            if let artworks = artworkResults {
                DispatchQueue.main.async {
                    if word == self.searchController.searchBar.text! || self.isSearching {
                        self.searchResults = artworks
                        self.searchController.searchBar.isLoading = false
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    }
    
    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isSearching ? searchResults.count : (results?.count ?? 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MusicCollectionViewCell.identifier, for: indexPath)
        guard let artwork = isSearching ? searchResults[indexPath.item] : results?[indexPath.item] else {
            return cell
        }
        if let cell = cell as? MusicCollectionViewCell,
           let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            cell.configure(from: artwork, size: layout.itemSize, isTextDark: true)
        }
        return cell
    }

    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let artwork = isSearching ? searchResults[indexPath.item] : results![indexPath.item]
        AppRealm.saveArtwork(artworks: [artwork])
        if (artwork.isMusic) {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MusicSlideShowController") as? MusicSlideShowController {
                player.stop()
                vc.results = AppRealm.retrieveArtwork(slug: artwork.slug ?? "")
                vc.fromSearch = true
                vc.currentIndex = 0
                present(vc, animated: true, completion: nil)
            }
            return
        }
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Slideshow") as? SlideshowViewController {
            if isSearching {
                AppRealm.saveArtwork(artworks: [artwork])
                let artResults = AppRealm.retrieveArtwork(slug: artwork.slug ?? "")
                if !artResults.isEmpty {
                    vc.artworks = artResults
                    vc.currentIndex = 0
                    present(vc, animated: true, completion: nil)
                }
            }else {
                vc.artworks = self.results!.filter("tokenId=%@", artwork.tokenId ?? "")
                vc.currentIndex = 0
                present(vc, animated: true, completion: nil)
            }
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

