//
//  Artwork.swift
//  Shared
//
//  Created by Francis Li on 5/22/20.
//

import CoreImage
import Foundation
import RealmSwift

enum ImageTransformation: String, CustomStringConvertible {
    case thumb = "c_thumb"
    case fill = "c_fill,g_face:auto"
    case fit = "c_fit"
    case pad = "c_pad,b_black"

    var description: String {
        return rawValue
    }
}

@objcMembers class Artwork: Object, Codable {
    dynamic var isMaster: Bool = false
    dynamic var containingSlug: String?
    dynamic var title: String?
    dynamic var desc: String?
    dynamic var imagePath: String?
    dynamic var masterPreviewPath: String?
    dynamic var tokenAddress: String?
    dynamic var mixId: String?
    dynamic var tokenId: String?
    dynamic var orientation: String?
    dynamic var creationDate: Date?
    dynamic var creationTXHash: String?
    dynamic var slug: String?
    var webURL: URL? { return URL(string: "\(Globals.WEB_BASE_URL)art/master/\(slug ?? "")") }

    dynamic var audioURL: String?
    dynamic var audioPreviewURL: String?
    dynamic var qrCodeUrl: String?

    dynamic var metadata: MetaData?
    dynamic var autonomousMetadata: AutonomousMetaData?
    dynamic var auction: Auction?
    dynamic var artist: User?
    var artists = List<User>()
    var controls = List<Control>()
    dynamic var owner: User?

    var tags = List<String>()

    var viewCount = RealmOptional<Int>()
    var layerCount = RealmOptional<Int>()
    var mintedCount = RealmOptional<Int>()
    var recordings = RealmOptional<Int>()
    var possibleCombinations = RealmOptional<Int>()
    dynamic var isMusic: Bool = false

    override public class func primaryKey() -> String? { return "slug" }


    enum CodingKeys: String, CodingKey {
        case isMaster
        case containingSlug
        case title
        case desc = "description"
        case imagePath
        case masterPreviewPath
        case tokenAddress
        case mixId
        case tokenId
        case orientation
        case creationDate
        case creationTXHash
        case slug
        case audioURL
        case audioPreviewURL
        case qrCodeUrl

        case autonomousMetadata
        case auction

        case metadata
        case artist
        case artists
        case tags
        case owner
        case viewCount = "views"
        case layerCount
        case mintedCount
        case recordings
        case possibleCombinations
        case controls
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isMaster = try! container.decode(Bool.self, forKey: .isMaster)
        containingSlug = try? container.decode(String.self, forKey: .containingSlug)
        title = try? container.decode(String.self, forKey: .title)
        desc = try? container.decode(String.self, forKey: .desc)
        imagePath = try? container.decode(String.self, forKey: .imagePath)
        masterPreviewPath = try? container.decode(String.self, forKey: .masterPreviewPath)
        tokenAddress = try? container.decode(String.self, forKey: .tokenAddress)
        mixId = try? container.decode(String.self, forKey: .mixId)
        tokenId = try? container.decode(String.self, forKey: .tokenId)
        orientation = try? container.decode(String.self, forKey: .orientation)
        if let unwrapCreationDate = try? container.decode(Double.self, forKey: .creationDate) {
            self.creationDate = Date(timeIntervalSince1970: unwrapCreationDate)
        }
        creationTXHash = try? container.decode(String.self, forKey: .creationTXHash)
        slug = try? container.decode(String.self, forKey: .slug)
        audioURL = try? container.decode(String.self, forKey: .audioURL)
        audioPreviewURL = try? container.decode(String.self, forKey: .audioPreviewURL)
        qrCodeUrl = try? container.decode(String.self, forKey: .qrCodeUrl)


        autonomousMetadata = try? container.decode(AutonomousMetaData.self, forKey: .autonomousMetadata)
        auction = try? container.decode(Auction.self, forKey: .auction)
        metadata = try? container.decode(MetaData.self, forKey: .metadata)

        artist = try? container.decode(User.self, forKey: .artist)
        owner = try? container.decode(User.self, forKey: .owner)

        if let viewCount = try? container.decode(Int.self, forKey: .viewCount) {
            self.viewCount.value = viewCount
        }
        if let layCount = try? container.decode(Int.self, forKey: .layerCount) {
            self.layerCount.value = layCount
        }
        if let mintCount = try? container.decode(Int.self, forKey: .mintedCount) {
            self.mintedCount.value = mintCount
        }
        if let recordings = try? container.decode(Int.self, forKey: .recordings) {
            self.recordings.value = recordings
        }

        let artistList = try container.decode([User].self, forKey: .artists)
        artists = List<User>()
        artists.append(objectsIn: artistList)

        let tagsList = try container.decode([String].self, forKey: .tags)
        tags = List<String>()
        tags.append(objectsIn: tagsList)

        controls = List<Control>()
        if let controlsList = try? container.decode([Control].self, forKey: .controls) {
            controls.append(objectsIn: controlsList)
        }

        self.isMusic = (metadata?.audio != nil)

        super.init()
    }

    required override init()
    {
        super.init()
    }

    var imageURL: URL {
        let url = "\(Globals.CLOUDINARY_BASE_URL)\(imagePath ?? "")"
        return URL(string: url)!
    }
    
    func imageURL(size: CGSize, transformation: ImageTransformation, scale: CGFloat = UIScreen.main.scale) -> URL {
        /// adjust size for scale
        var size = size
        size.width *= scale
        size.height *= scale
        /// generate cloudinary url for the given size
        let url = "\(Globals.CLOUDINARY_BASE_URL)w_\(Int(size.width)),h_\(Int(size.height)),\(transformation),q_70,f_auto/\(imagePath ?? "")"
        return URL(string: url)!
    }

    func webQRCode(size: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        guard var webURL = webURL, let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        /// TODO parameterize for other platforms as needed
        if var components = URLComponents(url: webURL, resolvingAgainstBaseURL: false) {
            components.queryItems = [
                URLQueryItem(name: "utm_source", value: "Apple_OS"),
                URLQueryItem(name: "utm_medium", value: "TV_Frames"),
                URLQueryItem(name: "utm_campaign", value: "AppleTV_QR")
            ]
            webURL = components.url ?? webURL
        }
        let data = webURL.absoluteString.data(using: .ascii)
        qrFilter.setValue(data, forKey: "inputMessage")
        guard var ciImage = qrFilter.outputImage else { return nil }
        let sx = scale * size.width / ciImage.extent.width
        let sy = scale * size.height / ciImage.extent.height
        ciImage = ciImage.transformed(by: CGAffineTransform(scaleX: sx, y: sy))
        return UIImage(ciImage: ciImage)
    }

    func instantiate(from data: [String: Any]) -> Artwork {
        let obj = try! DictionaryDecoder().decode(Artwork.self, from: data)
        return obj
    }
}


