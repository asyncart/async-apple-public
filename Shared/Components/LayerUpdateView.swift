//
//  LayerUpdateView.swift
//  tvOS
//
//  Created by Francis Li on 6/21/20.
//

import UIKit

class LayerUpdateView: UIView {
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var imageView: CachedImageView!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var blockLabel: UILabel!
    
    init() {
        super.init(frame: .zero)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        guard let view = Bundle(for: type(of: self)).loadNibNamed(String(describing: type(of: self)), owner: self, options: nil)?.first as? UIView else { return }
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.leftAnchor.constraint(equalTo: leftAnchor),
            view.topAnchor.constraint(equalTo: topAnchor),
            view.rightAnchor.constraint(equalTo: rightAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        blurView.layer.cornerRadius = 15
        blurView.layer.masksToBounds = true
        
        imageView.activityIndicatorViewColor = .white
        imageView.layer.cornerRadius = 10
        imageView.layer.borderColor = (UIColor(named: "lightGray") ?? UIColor.lightGray).cgColor
        imageView.layer.borderWidth = 2
        imageView.layer.masksToBounds = true
        
        separatorView.layer.cornerRadius = 2
        separatorView.layer.masksToBounds = true
    }

    func update(from artwork: Artwork) {
        let triggerUser = layerChangeUser ?? artwork.owner
        titleLabel.text = artwork.title
        ownerLabel.text = triggerUser?.displayName
        if let value = artwork.metadata?.lastUpdatedOnBlock.value {
            blockLabel.text = "#\(value)"
        } else {
            blockLabel.text = ""
        }
        imageView.setImage(from: artwork.imageURL)
    }
}
