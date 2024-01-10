//
//  ArtworkCollectionViewCell.swift
//  Shared
//
//  Created by Francis Li on 5/22/20.
//

import UIKit
import SnapKit

class MusicCollectionViewCell: UICollectionViewCell {
    static let identifier = "MusicCollectionViewCell"
    
    weak var imageView: CachedImageView!
    var titleLabel: UILabel!
    var subTitleLabel: UILabel!

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
        imageView.clipsToBounds = false
        imageView.adjustsImageWhenAncestorFocused = true
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.top.left.right.equalToSuperview()
            maker.bottom.equalToSuperview().inset(70)
        }
        self.imageView = imageView

        titleLabel = UILabel()
        titleLabel.textColor = .white
        titleLabel.text = ""
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = UIFont.bold(size: 22)
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(self.imageView.snp_bottomMargin).offset(20)
            maker.left.right.equalToSuperview().inset(5)
            maker.height.equalTo(40)
        }

        subTitleLabel = UILabel()
        subTitleLabel.textColor = .white
        subTitleLabel.text = ""
        subTitleLabel.textAlignment = .center
        subTitleLabel.adjustsFontForContentSizeCategory = true
        subTitleLabel.font = UIFont.regular(size: 16)
        contentView.addSubview(subTitleLabel)
        subTitleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(self.titleLabel.snp_bottomMargin).offset(0)
            maker.left.right.equalToSuperview().inset(5)
            maker.height.equalTo(28)
        }
    }
    
    func configure(from artwork: Artwork, size: CGSize, isTextDark: Bool = false) {
        imageView.image = nil
        imageView.addAutonomousIcon = (artwork.autonomousMetadata?.autonomousDesc != nil)
        imageView.setImage(from: artwork.imageURL(size: size, transformation: .thumb))
        titleLabel.text = artwork.title ?? ""
        let names = Array(artwork.artists).map({ $0.displayName ?? "" }).joined(separator: ", ")
        subTitleLabel.text = names.replacingOccurrences(of: "ꟻ", with: "F")
        if isTextDark {
            titleLabel.textColor = .black
            subTitleLabel.textColor = .black
        }
    }

    func configureSlide(from artwork: Artwork, size: CGSize) {
        imageView.image = nil
        imageView.addAutonomousIcon = (artwork.autonomousMetadata?.autonomousDesc != nil)
        imageView.setImage(from: artwork.imageURL(size: size, transformation: .thumb))
        titleLabel.text = ""
        subTitleLabel.text = ""
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
      coordinator.addCoordinatedAnimations({ [unowned self] in
         self.setStateForFocusState()
      }, completion: nil)
    }

    func setStateForFocusState() {
        titleLabel.snp.remakeConstraints { maker in
            maker.top.equalTo(self.imageView.snp_bottomMargin).offset(isFocused ? 50 : 20)
            maker.left.right.equalToSuperview().inset(5)
            maker.height.equalTo(40)
        }

        subTitleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(self.titleLabel.snp_bottomMargin).offset(0)
            maker.left.right.equalToSuperview().inset(5)
            maker.height.equalTo(28)
        }
    }
}
