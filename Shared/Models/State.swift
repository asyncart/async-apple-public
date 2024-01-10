//
//  Metadatab.swift
//  tvOS
//
//  Created by Fitzgerald Afful on 16/07/2021.
//

import Foundation
import Realm
import RealmSwift

@objcMembers class State: Object, Codable {

    dynamic var imagePath: String?
    dynamic var label: String?

    func instantiate(from data: [String: Any]) -> State {
        let obj = try? DictionaryDecoder().decode(State.self, from: data)
        return obj!
    }

    enum CodingKeys: String, CodingKey {
        case imagePath
        case label
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        imagePath = try? container.decode(String.self, forKey: .imagePath)
        super.init()
    }

    required override init() {
        super.init()
    }
}




@objcMembers class Control: Object, Codable {

    var states = List<State>()
    dynamic var label: String?
    dynamic var controlType: String?

    func instantiate(from data: [String: Any]) -> Control {
        let obj = try? DictionaryDecoder().decode(Control.self, from: data)
        return obj!
    }

    enum CodingKeys: String, CodingKey {
        case states = "states"
        case label
        case controlType
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = try? container.decode(String.self, forKey: .label)
        controlType = try? container.decode(String.self, forKey: .controlType)

        let statesList = try container.decode([State].self, forKey: .states)
        states = List<State>()
        states.append(objectsIn: statesList)

        super.init()
    }

    required override init() {
        super.init()
    }
}
