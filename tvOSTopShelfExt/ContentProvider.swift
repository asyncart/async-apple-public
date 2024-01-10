//
//  ContentProvider.swift
//  Async Art Top Shelf
//
//  Created by Francis Li on 5/22/20.
//

import TVServices

class ContentProvider: TVTopShelfContentProvider {

    override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {

        let group = DispatchGroup()
        DispatchQueue.global().async {
            let results = AppRealm.getMarket(isNetworkedCall: false) { (_, _)  in }
            if results.count > 0 {
                var items: [TVTopShelfCarouselItem] = []
                for index in 0..<min(10, results.count) {
                    let artwork = results[index]
                    let item = TVTopShelfCarouselItem(identifier: artwork.slug ?? "")
                    item.title = artwork.title ?? ""
                    item.contextTitle = NSLocalizedString("Gallery", comment: "")
                    item.setImageURL(AppRealm.cachedFileURL(for: artwork.imageURL(size: CGSize(width: 1920, height: 1080), transformation: .fill, scale: 1.0), onlyIfExists: true), for: .screenScale1x)
                    item.setImageURL(AppRealm.cachedFileURL(for: artwork.imageURL(size: CGSize(width: 1920, height: 1080), transformation: .fill, scale: 2.0), onlyIfExists: true), for: .screenScale2x)
                    items.append(item)
                }
                completionHandler(TVTopShelfCarouselContent(style: .actions, items: items))
                return
            }
            group.enter()
            var hadResults: Bool = false
            _ = AppRealm.getMarket(isNetworkedCall: true) { (error, artworks)  in
                if let newArtworks = artworks {
                    if newArtworks.count > 0 {
                        var items: [TVTopShelfCarouselItem] = []
                        for index in 0..<min(10, newArtworks.count) {
                            let artwork = newArtworks[index]
                            let item = TVTopShelfCarouselItem(identifier: artwork.slug ?? "")
                            item.title = artwork.title ?? ""
                            item.contextTitle = NSLocalizedString("Gallery", comment: "")
                            item.setImageURL(AppRealm.cachedFileURL(for: artwork.imageURL(size: CGSize(width: 1920, height: 1080), transformation: .fill, scale: 1.0), onlyIfExists: true), for: .screenScale1x)
                            item.setImageURL(AppRealm.cachedFileURL(for: artwork.imageURL(size: CGSize(width: 1920, height: 1080), transformation: .fill, scale: 2.0), onlyIfExists: true), for: .screenScale2x)
                            items.append(item)
                        }
                        hadResults = true
                        completionHandler(TVTopShelfCarouselContent(style: .actions, items: items))
                    }
                }
                group.leave()
            }
            if !hadResults {
                completionHandler(nil);
            }
        }
    }
}
