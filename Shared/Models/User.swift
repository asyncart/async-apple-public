//
//  User.swift
//  Shared
//
//  Created by Francis Li on 5/22/20.
//

import Foundation
import RealmSwift

@objcMembers public class User: Object, Codable {
    dynamic var name: String?
    dynamic var username: String?
    dynamic var userProfilePhotoPath: String?
    dynamic var address: String?
    dynamic var email: String?

    override public class func primaryKey() -> String? {
        return "address"
    }

    var displayName: String? {
        if let name = name, !name.isEmpty {
            return name
        }
        if let username = username, !username.isEmpty {
            return username
        }
        if let address = address, !address.isEmpty {
            return address
        }
        return nil
    }

    func instantiate(from data: [String: Any]) -> User {
        let obj = try? DictionaryDecoder().decode(User.self, from: data)
        return obj!
    }

    enum CodingKeys: String, CodingKey {
        case name
        case username
        case userProfilePhotoPath
        case address
        case email
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try? container.decode(String.self, forKey: .name)
        username = try? container.decode(String.self, forKey: .username)
        userProfilePhotoPath = try? container.decode(String.self, forKey: .userProfilePhotoPath)
        address = try? container.decode(String.self, forKey: .address)
        email = try? container.decode(String.self, forKey: .email)

        super.init()
    }

    required override init()
    {
        super.init()
    }
}
