//
//  TrackingEvent.swift
//  Async Art
//
//  Created by Fitzgerald Afful on 21/03/2022.
//

import Foundation
import Mixpanel

enum TrackingEvent: String {

    // MARK: All tracking events
    case tvAppOpened = "Opened TV App"

    case tagChanged = "Tag Changed"

    case artworkViewed = "Artwork Viewed"
    case musicPiecePlayed = "Music Piece Viewed"
    case artworkDetailsViewed = "Artwork Details Viewed"
    case musicPieceDetailsViewed = "Music Piece Details Viewed"

    case searchedForArtwork = "Searched for Piece"

    // MARK: Frame Settings Events
    case frameSettingsViewed = "Frame Settings Viewed"
    case frameEnabled = "Frame Enabled"
    case matboardEnabled = "Matboard Enabled"
    case blurredEdgesEnabled = "Blurred Edges Enabled"
    case zoomFillEnabled = "Zoom Fill Enabled"
    case orientationChanged = "Orientation Changed"

    #if DEBUG
    // MARK: Development and testing events
    case test = "Test Event"
    #endif

    // MARK: Send event method

    func send(withProperties properties: Properties = [:]) {
        print("[📈 Tracking Event] [\(Mixpanel.mainInstance().distinctId)] \(rawValue)")
        Mixpanel.mainInstance().track(
            event: self.rawValue,
            properties: properties
        )
    }
}

