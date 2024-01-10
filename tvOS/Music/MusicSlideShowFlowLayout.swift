//
//  MusicSlideShowFlowLayout.swift
//  tvOS
//
//  Created by Fitzgerald Afful on 28/06/2021.
//

import Foundation
import UIKit

class MusicSlideShowFlowLayout: UICollectionViewFlowLayout {

    override init() {
        super.init()

        scrollDirection = .horizontal
        minimumLineSpacing = 80
        itemSize = CGSize(width: 400, height: 400)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare() {
        guard let collectionView = collectionView else { fatalError() }
        let verticalInsets = (collectionView.frame.height - collectionView.adjustedContentInset.top - collectionView.adjustedContentInset.bottom - itemSize.height) / 2
        let horizontalInsets = (collectionView.frame.width - collectionView.adjustedContentInset.right - collectionView.adjustedContentInset.left - itemSize.width) / 2
        sectionInset = UIEdgeInsets(top: verticalInsets, left: horizontalInsets, bottom: verticalInsets, right: horizontalInsets)
        super.prepare()
    }
}

class TagsFlowLayout: UICollectionViewFlowLayout {

    override init() {
        super.init()

        scrollDirection = .horizontal
        minimumLineSpacing = 10
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
