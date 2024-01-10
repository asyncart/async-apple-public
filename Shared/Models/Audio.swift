//
//  Audio.swift
//  tvOS
//
//  Created by Fitzgerald Afful on 16/07/2021.
//

import Foundation
import Realm
import RealmSwift

@objcMembers class Audio: Object, Codable, RealmOptionalType {

    dynamic var duration = RealmOptional<Int>()
    dynamic var audioFormat: String?

    func instantiate(from data: [String: Any]) -> Audio {
        let obj = try? DictionaryDecoder().decode(Audio.self, from: data)
        return obj!
    }

    enum CodingKeys: String, CodingKey {
        case duration
        case audioFormat
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let myDuration = try? container.decode(Int.self, forKey: .duration) {
            self.duration.value = myDuration
        }
        audioFormat = try container.decode(String.self, forKey: .audioFormat)
        super.init()
    }

    required override init() {
        super.init()
    }
}
