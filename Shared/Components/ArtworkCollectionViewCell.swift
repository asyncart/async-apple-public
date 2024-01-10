//
//  ArtworkCollectionViewCell.swift
//  Shared
//
//  Created by Francis Li on 5/22/20.
//

import UIKit

class ArtworkCollectionViewCell: UICollectionViewCell {
    static let identifier = "ArtworkCollectionViewCell"
    weak var imageView: CachedImageView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        let imageView = CachedImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.adjustsImageWhenAncestorFocused = true
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            imageView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        self.imageView = imageView
    }
    
    func configure(from artwork: Artwork, size: CGSize) {
        imageView.image = nil
        imageView.addAutonomousIcon = (artwork.autonomousMetadata?.autonomousDesc != nil)
        imageView.setImage(from: artwork.imageURL(size: size, transformation: .thumb))
    }
}
