//
//  TagViewCell.swift
//  tvOS
//
//  Created by Fitzgerald Afful on 25/10/2021.
//

import UIKit

class TagViewCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bgView: UIView!
    var isSelectedCell: Bool = false

    override func awakeFromNib() {
        super.awakeFromNib()
        self.titleLabel.textColor = .gray
        self.bgView.backgroundColor = .clear
        self.bgView.borderColor = .clear
    }

    func configure(from title: String) {
        titleLabel.text = " \(title.capitalized) "
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if self.isFocused {
            self.titleLabel.textColor = .white
            self.bgView.backgroundColor = .black
            self.bgView.clipsToBounds = false
        } else {
            self.titleLabel.textColor = self.isSelectedCell ? .black : .gray
            self.bgView.backgroundColor = .clear
            self.bgView.clipsToBounds = true
        }
    }
}
