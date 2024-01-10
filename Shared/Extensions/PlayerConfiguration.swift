//
//  PlayerConfiguration.swift
//  tvOS
//
//  Created by Fitzgerald Afful on 29/06/2021.
//

import Foundation
import AVKit
import ModernAVPlayer

let player: ModernAVPlayer = {
    let conf = PlayerConfigurationExample()
    return ModernAVPlayer(config: conf, loggerDomains: [.error, .unavailableCommand])
}()

enum PlayerRepeatMode: Int {
    case repeatNone = 0
    case repeatAll = 1
    case repeatOnce = 2
}

var repeatMode: PlayerRepeatMode = PlayerRepeatMode(rawValue: UserDefaults.standard.integer(forKey: "repeatMode")) ?? .repeatAll {
    didSet {
        UserDefaults.standard.set(repeatMode.rawValue, forKey: "repeatMode")
    }
}

struct PlayerConfigurationExample: PlayerConfiguration {
    var audioSessionCategoryOptions: AVAudioSession.CategoryOptions = .allowAirPlay


    // Buffering State
    let rateObservingTimeout: TimeInterval = 3
    let rateObservingTickTime: TimeInterval = 0.3

    // General Audio preferences
    let preferredTimescale = CMTimeScale(NSEC_PER_SEC)
    let periodicPlayingTime: CMTime
    let audioSessionCategory = AVAudioSession.Category.playback

    // Reachability Service
    let reachabilityURLSessionTimeout: TimeInterval = 3
    //swiftlint:disable:next force_unwrapping
    let reachabilityNetworkTestingURL = URL(string: "https://www.google.com")!
    let reachabilityNetworkTestingTickTime: TimeInterval = 3
    let reachabilityNetworkTestingIteration: UInt = 10

    // RemoteCommandExample is used for example
    var useDefaultRemoteCommand = false

    let allowsExternalPlayback = false

    // AVPlayerItem Init Service
    let itemLoadedAssetKeys = ["playable", "duration"]

    init() {
        periodicPlayingTime = CMTime(seconds: 0.1, preferredTimescale: preferredTimescale)
    }
}


enum MediaResource: CustomStringConvertible {
    case live
    case remote
    case local
    case invalid
    case custom(String)

    var description: String {
        switch self {
        case .live:
            return "Live MP3"
        case .local:
            return "Local MP3"
        case .remote:
            return "Remote MP3"
        case .invalid:
            return "Invalid file - txt"
        case .custom:
            return "Custom url"
        }
    }

    var type: MediaType {
        switch self {
        case .live:
            return .stream(isLive: true)
        case .local, .remote, .invalid, .custom:
            return .clip
        }
    }

    var url: URL {
        switch self {
        case .live:
            return URL(string: "http://direct.franceinter.fr/live/franceinter-midfi.mp3")!
        case .local:
            return URL(fileURLWithPath: Bundle.main.path(forResource: "AllNew", ofType: "mp3")!)
        case .remote:
            return URL(string: "http://media.radiofrance-podcast.net/podcast09/13100-17.01.2017-ITEMA_21199585-0.mp3")!
        case .invalid:
            return URL(fileURLWithPath: Bundle.main.path(forResource: "noreason", ofType: "txt")!)
        case .custom(let customUrl):
            return URL(string: customUrl)!
        }
    }

    var metadata: ModernAVPlayerMediaMetadata? {
        switch self {
        case .live:
            return ModernAVPlayerMediaMetadata(title: "Le live",
                                               albumTitle: "Album0",
                                               artist: "Artist0",
                                               image: UIImage(named: "sennaLive")?.jpegData(compressionQuality: 1.0))
        case .local:
            return ModernAVPlayerMediaMetadata(title: "Local clip",
                                               albumTitle: "Album2",
                                               artist: "Artist2",
                                               image: UIImage(named: "ankierman")?.jpegData(compressionQuality: 1.0),
                                               remoteImageUrl: URL(string: "https://goo.gl/U4QoQj"))
        case .remote:
            return ModernAVPlayerMediaMetadata(title: "Remote clip",
                                               albumTitle: "Album1",
                                               artist: "Artist1",
                                               image: nil)
        case .invalid, .custom:
            return nil
        }
    }

    var item: AVPlayerItem {
        return AVPlayerItem(url: url)
    }

    var playerMedia: ModernAVPlayerMedia {
        return ModernAVPlayerMedia(url: url, type: type, metadata: metadata)
    }

    var playerMediaFromItem: ModernAVPlayerMediaItem? {
        return ModernAVPlayerMediaItem(item: item, type: type, metadata: metadata)
    }
}
