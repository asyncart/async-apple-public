//
//  ArtworkCollectionViewswift
//  Shared
//
//  Created by Francis Li on 5/22/20.
//

import UIKit

class MusicSlideShowCell: UICollectionViewCell {
    static let identifier = "MusicSlideShowCell"
    weak var imageView: CachedImageView!
    var overlay = UIView()

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
        imageView.adjustsImageWhenAncestorFocused = false
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            imageView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        self.imageView = imageView
        contentView.addSubview(overlay)
        contentView.bringSubviewToFront(overlay)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        overlay.snp.makeConstraints { maker in
            maker.top.left.right.bottom.equalToSuperview()
        }
    }
    
    func configure(from artwork: Artwork, size: CGSize) {
        imageView.image = nil
        imageView.addAutonomousIcon = (artwork.autonomousMetadata?.autonomousDesc != nil)
        imageView.setImage(from: artwork.imageURL(size: size, transformation: .thumb))
    }

    func scaleUp() {
        imageView.transform3D = CATransform3DMakeScale(1.2, 1.2, 1.2)
        //contentView.layer.shadowColor = UIColor.black.cgColor
        overlay.backgroundColor = .clear
        layer.borderWidth = 0.0
        layer.shadowOffset = CGSize(width: 5, height: 5)
        layer.shadowRadius = 3
        layer.shadowOpacity = 0.1
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        layer.masksToBounds = false
    }

    func scaleUpFocus() {
        imageView.transform3D = CATransform3DMakeScale(1.25, 1.25, 1.25)
        //contentView.layer.shadowColor = UIColor.black.cgColor
        overlay.backgroundColor = .clear
        layer.borderWidth = 0.0
        layer.shadowOffset = CGSize(width: 5, height: 20)
        layer.shadowRadius = 10
        layer.shadowOpacity = 0.4
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        layer.masksToBounds = false
    }

    func resetScale() {
        imageView.transform = CGAffineTransform.identity
        overlay.backgroundColor = .black.withAlphaComponent(0.6)
        layer.masksToBounds = true
    }

}
