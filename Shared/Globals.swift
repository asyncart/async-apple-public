//
//  Globals.swift
//  tvOS
//
//  Created by Francis Li on 5/22/20.
//

import Foundation

class Globals {
    // MARK: - Production settings
    static let API_BASE_URL = "https://async-api.com" //"https://async-2.appspot.com/"
    static let WEB_BASE_URL = "https://async.art/"

    // MARK: - Staging settings
    //static let API_BASE_URL = "https://async-2-staging.appspot.com/"
    //static let WEB_BASE_URL = "https://asyncdotart.now.sh/"

    // MARK: - 
    static let APP_GROUP = "group.art.async"
    static let CLOUDINARY_BASE_URL = "https://res.cloudinary.com/asynchronous-art-inc/image/upload/"

    static func frameSettings(for artwork: Artwork) -> FrameSettings {
        if let slug = artwork.slug {
            let defaults = UserDefaults.standard
            let frameSettings = defaults.dictionary(forKey: "frameSettings") ?? [:]
            return FrameSettings(artwork: artwork, dictionary: frameSettings[slug] as? [String: Any] ?? [:])
        }
        return FrameSettings(artwork: artwork, dictionary: [:])
    }

    static func setFrameSettings(_ dictionary: [String: Any], for artwork: Artwork) {
        if let slug = artwork.slug {
            let defaults = UserDefaults.standard
            var frameSettings = defaults.dictionary(forKey: "frameSettings") ?? [:]
            frameSettings[slug] = dictionary
            defaults.set(frameSettings, forKey: "frameSettings")
        }
    }
}
