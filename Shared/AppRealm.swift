//
//  AppRealm.swift
//  Shared
//
//  Created by Francis Li on 5/22/20.
//

import CryptoKit
import Foundation
import RealmSwift
import SocketIO

public var layerChanged = false
public var layerChangeUser: User?

class AppRealm {
    private static var main: Realm!
    private static var socketManager: SocketManager!
    private static let fileURL = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: Globals.APP_GROUP)!
        .appendingPathComponent("Library/Caches/default.realm")
    
    public static func open() -> Realm {
        if Thread.current.isMainThread && AppRealm.main != nil {
            return AppRealm.main
        }
        var realm: Realm?
        var config = Realm.Configuration(fileURL: fileURL, deleteRealmIfMigrationNeeded: true, shouldCompactOnLaunch: { totalBytes, usedBytes in
            let oneHundredMB = 50 * 1024 * 1024
            return (totalBytes > oneHundredMB) && (Double(usedBytes) / Double(totalBytes)) < 0.5
        })
        config.maximumNumberOfActiveVersions = 20
        do {
            try autoreleasepool {
                realm = try Realm(configuration: config)
                realm?.autorefresh = true
            }
        } catch let error {
            print(error)
        }
        if Thread.current.isMainThread {
            AppRealm.main = realm
        }
        return realm!
    }

    public static func compactRealm() {
        let defaultParentURL = fileURL.deletingLastPathComponent()
        let compactURL = defaultParentURL.appendingPathComponent("default-compacted.realm")
        autoreleasepool {
            let realm = AppRealm.open()
            try! realm.writeCopy(toFile: compactURL)
        }
        try! FileManager.default.removeItem(at: fileURL)
        try! FileManager.default.moveItem(at: compactURL, to: fileURL)
        print("Size: \(AppRealm.sizePerMB(url: compactURL))")
    }

    public static func sizePerMB(url: URL?) -> Double {
        guard let filePath = url?.path else {
            return 0.0
        }
        do {
            let attribute = try FileManager.default.attributesOfItem(atPath: filePath)
            if let size = attribute[FileAttributeKey.size] as? NSNumber {
                return size.doubleValue / 1000000.0
            }
        } catch {
            print("Error: \(error)")
        }
        return 0.0
    }

    public static func listenForUpdates() {
        if AppRealm.socketManager == nil {
            self.socketManager = SocketManager(socketURL: URL(string: Globals.API_BASE_URL)!, config: [.log(false),.connectParams(["EIO": "4"])])
            let socket = self.socketManager.defaultSocket
            socket.on("all-updates") { (updates, ack) in
                if let updates = updates as? [[String: Any]] {
                    for update in updates {
                        if let artworkJson = update["art"] as? [String: Any] {
                            layerChanged = true
                            let newArtwork = Artwork().instantiate(from: artworkJson)
                            self.saveArtwork(artworks: [newArtwork])
                        }
                        if let userJson = update["user"] as? [String: Any] {
                            layerChanged = true
                            let newUser = User().instantiate(from: userJson)
                            layerChangeUser = newUser
                        }
                    }
                }
            }
            socket.connect()
        }
    }

    public static func getArt(slug: String, completionHandler: @escaping (Error?, Artwork?) -> Void) {
        let task = ApiClient.shared.getArt(slug: slug) { (data, error) in
            if error == nil, let data = data {
                var primaryArtwork: Artwork?
                var artworks: [Artwork] = []
                if let data = data["primary"] as? [String: Any] {
                    primaryArtwork = Artwork().instantiate(from: data)
                }
                if let fragments = data["fragments"] as? [[String: Any]] {
                    let fragmentArtworks = fragments.map({ Artwork().instantiate(from: $0) })
                    var possibleCombinations = 1
                    for item in fragmentArtworks {
                        if let first = item.controls.first {
                            let (partialValue, _) = possibleCombinations.multipliedReportingOverflow(by: first.states.count)
                            possibleCombinations = partialValue
                        }
                        artworks.append(item)
                    }
                    primaryArtwork?.possibleCombinations.value = possibleCombinations
                }
                artworks.append(primaryArtwork!)
                self.saveArtwork(artworks: artworks)
                completionHandler(nil, primaryArtwork)
            } else {
                completionHandler(error, nil)
            }
        }
        task.resume()
    }

    public static func getTags(completionHandler: @escaping (Error?, [String]?) -> Void) {
        let task = ApiClient.shared.getTags() { (data, error) in
            if error == nil, let data = data {
                var tags: [String] = []
                if let tagArray = data["tags"] as? [String] {
                    tags = tagArray
                }
                UserDefaultsManager().setData(value: tags, key: .tags)
                completionHandler(nil, tags)
            } else {
                completionHandler(error, nil)
            }
        }
        task.resume()
    }
    
    public static func getMarket(isNetworkedCall: Bool = true, completionHandler: @escaping (Error?, [Artwork]?) -> Void) -> Results<Artwork> {
        if isNetworkedCall { AppRealm.getMarket(page: 1, ids: [], completionHandler: completionHandler) }
        let results = AppRealm.open().objects(Artwork.self).filter("isMaster=%@", true).filter("isMusic=%@", false).sorted(byKeyPath: "creationDate", ascending: false)
        return results
    }

    public static func getMarket(isNetworkedCall: Bool = true, tag: String, completionHandler: @escaping (Error?, [Artwork]?) -> Void) -> Results<Artwork> {
        if isNetworkedCall { AppRealm.getMarket(page: 1, ids: [], completionHandler: completionHandler) }
        let results = AppRealm.open().objects(Artwork.self).filter("isMaster=%@", true).filter("isMusic=%@", false).sorted(byKeyPath: "creationDate", ascending: false)
        return results
    }

    public static func getMusicMarket(errorHandler: @escaping (Error) -> Void) -> Results<Artwork> {
        AppRealm.getMusicMarket(page: 1, ids: [], errorHandler: errorHandler)
        let results = AppRealm.open().objects(Artwork.self).filter("isMaster=%@", true).filter("isMusic=%@", true).sorted(byKeyPath: "creationDate", ascending: false)
        return results
    }
    
    private static func getMarket(page: Int, ids: [String], completionHandler: @escaping (Error?, [Artwork]?) -> Void) {
        let task = ApiClient.shared.getMarket(page: page, completionHandler: { (results, error) in
            if let error = error {
                completionHandler(error, nil)
            } else if let results = results, let market = results["market"] as? [[String: Any]] {
                if market.count > 0 {
                    /// collect and append received slug ids in this call
                    var ids = ids
                    ids.append(contentsOf: market.map({ $0["slug"] as? String ?? "" }))
                    /// instantiate and save Artwork records
                    let artworks = market.map({ Artwork().instantiate(from: $0) })
                    self.saveArtwork(artworks: artworks)
                    if page == 1 {
                        completionHandler(nil, artworks)
                    }
                    AppRealm.getMarket(page: page + 1, ids: ids, completionHandler: completionHandler)
                } else {
                    /// search for and delete any artworks not received across all pages of calls
                    let realm = AppRealm.open()
                    try! realm.write {
                        let results = realm.objects(Artwork.self).filter("NOT (slug IN %@)", ids.filter({ $0 != "" }))
                        realm.delete(results)
                    }
                }
            }
        })
        task.resume()
    }

    public static func saveArtwork(artworks: [Artwork]) {
        DispatchQueue.main.async {
                do {
                    let realm = AppRealm.open()
                    realm.refresh()
                    try! realm.safeWrite({
                        realm.add(artworks, update: .modified)
                    })
                }
            }
    }

    public static func retrieveArtwork(slug: String) -> Results<Artwork> {
        return AppRealm.open().objects(Artwork.self).filter("slug=%@", slug)
    }

    private static func getMusicMarket(page: Int, ids: [String], errorHandler: @escaping (Error) -> Void) {
        let task = ApiClient.shared.getMusicMarket(page: page, completionHandler: { (results, error) in
            if let error = error {
                errorHandler(error)
            } else if let results = results, let market = results["market"] as? [[String: Any]] {
                if market.count > 0 {
                    /// collect and append received slug ids in this call
                    var ids = ids
                    ids.append(contentsOf: market.map({ $0["slug"] as? String ?? "" }))
                    /// instantiate and save Artwork records
                    let artworks = market.map({ Artwork().instantiate(from: $0) })
                    self.saveArtwork(artworks: artworks)
                    AppRealm.getMusicMarket(page: page + 1, ids: ids, errorHandler: errorHandler)
                } else {
                    /// search for and delete any artworks not received across all pages of calls
                    let realm = AppRealm.open()
                    try! realm.write {
                        let results = realm.objects(Artwork.self).filter("NOT (slug IN %@)", ids.filter({ $0 != "" }))
                        realm.delete(results)
                    }
                }
            }
        })
        task.resume()
    }

    public static func search(searchWord: String, completionHandler: @escaping (String, [Artwork]?, Error?) -> Void) {
        let task = ApiClient.shared.searchMarket(searchWord: searchWord, completionHandler: { (results, error) in
            if let error = error {
                completionHandler(searchWord, nil, error)
            } else if let results = results, let market = results["market"] as? [[String: Any]] {
                var artworks: [Artwork] = []
                if market.count > 0 {
                    artworks = market.map({ Artwork().instantiate(from: $0) })
                }
                completionHandler(searchWord, artworks, nil)
            }
        })
        task.resume()
    }
    
    public static func cachedFileURL(for url: URL, frameSettings: FrameSettings? = nil, onlyIfExists: Bool = false) -> URL {
        /// generate a cache id for the url
        var sha256 = SHA256()
        sha256.update(data: Data(url.absoluteString.utf8))
        if let frameSettings = frameSettings {
            sha256.update(data: Data(frameSettings.fingerprint.utf8))
        }
        var cacheId = sha256.finalize().description
        if cacheId.starts(with: "SHA256 digest: ") {
            cacheId = String(cacheId[cacheId.index(cacheId.startIndex, offsetBy: 15)...])
        }
        /// generate file path for the cache file
        let fileManager = FileManager.default
        let cacheDirURL = fileManager
            .containerURL(forSecurityApplicationGroupIdentifier: Globals.APP_GROUP)!
            .appendingPathComponent("Library/Caches/Images")
        if !fileManager.fileExists(atPath: cacheDirURL.path) {
            try! fileManager.createDirectory(at: cacheDirURL, withIntermediateDirectories: true, attributes: [:])
        }
        let fileURL = cacheDirURL.appendingPathComponent("\(cacheId)")
        if onlyIfExists && !fileManager.fileExists(atPath: fileURL.path) {
            return url
        }
        return fileURL
    }
}
