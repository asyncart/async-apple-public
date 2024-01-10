//
//  Metadatab.swift
//  tvOS
//
//  Created by Fitzgerald Afful on 16/07/2021.
//

import Foundation
import Realm
import RealmSwift

@objcMembers class MetaData: Object, Codable {

    dynamic var imageFormat: String?
    dynamic var imageSize = RealmOptional<Int>()
    dynamic var imageDimensions: String?
    dynamic var lastUpdatedAt: Date?
    dynamic var lastUpdatedLayer: String?
    dynamic var lastUpdatedOnBlock = RealmOptional<Int>()
    dynamic var audio: Audio?

    func instantiate(from data: [String: Any]) -> MetaData {
        let obj = try? DictionaryDecoder().decode(MetaData.self, from: data)
        return obj!
    }

    enum CodingKeys: String, CodingKey {
        case imageFormat
        case imageSize
        case imageDimensions
        case lastUpdatedAt
        case lastUpdatedLayer
        case lastUpdatedOnBlock
        case audio
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let unwrappedImageSize = try? container.decode(Int.self, forKey: .imageSize) {
            self.imageSize.value = unwrappedImageSize
        }
        imageFormat = try? container.decode(String.self, forKey: .imageFormat)
        imageDimensions = try? container.decode(String.self, forKey: .imageDimensions)
        if let metaLastUpdatedAt = try? container.decode(Double.self, forKey: .lastUpdatedAt) {
            self.lastUpdatedAt = Date(timeIntervalSince1970: metaLastUpdatedAt)
        }
        lastUpdatedLayer = try? container.decode(String.self, forKey: .lastUpdatedLayer)
        if let metLastUpdated = try? container.decode(Int.self, forKey: .lastUpdatedOnBlock) {
            self.lastUpdatedOnBlock.value = metLastUpdated
        }
        audio = try? container.decode(Audio.self, forKey: .audio)
        super.init()
    }

    required override init() {
        super.init()
    }
}




@objcMembers class AutonomousMetaData: Object, Codable {

    dynamic var autonomousDesc: String?
    dynamic var autonomousTimezone: String?

    func instantiate(from data: [String: Any]) -> AutonomousMetaData {
        let obj = try? DictionaryDecoder().decode(AutonomousMetaData.self, from: data)
        return obj!
    }

    enum CodingKeys: String, CodingKey {
        case autonomousDesc = "description"
        case autonomousTimezone = "timezone"
        //case autonomousGasTankAddress
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        autonomousDesc = try? container.decode(String.self, forKey: .autonomousDesc)
        autonomousTimezone = try? container.decode(String.self, forKey: .autonomousTimezone)
        //autonomousGasTankAddress = try? container.decode(String.self, forKey: .autonomousGasTankAddress)
        super.init()
    }

    required override init() {
        super.init()
    }
}
