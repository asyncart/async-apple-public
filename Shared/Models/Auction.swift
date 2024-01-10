//
//  Auction.swift
//  tvOS
//
//  Created by Fitzgerald Afful on 16/07/2021.
//

import Foundation
import Realm
import RealmSwift

@objcMembers class Auction: Object, Codable {

    var hasReserve = RealmOptional<Bool>()
    dynamic var endTime: Date?

    func instantiate(from data: [String: Any]) -> Auction {
        let obj = try? DictionaryDecoder().decode(Auction.self, from: data)
        return obj!
    }

    enum CodingKeys: String, CodingKey {
        case hasReserve
        case endTime
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let unwrapHasReserve = try? container.decode(Bool.self, forKey: .hasReserve) {
            self.hasReserve.value = unwrapHasReserve
        }
        if let unwrapAuctionDate = try? container.decode(Double.self, forKey: .endTime) {
            self.endTime = Date(timeIntervalSince1970: unwrapAuctionDate)
        }
        super.init()
    }

    required override init() {
        super.init()
    }
}
