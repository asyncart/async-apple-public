//
//  CornerView.swift
//  Async Art
//
//  Created by Francis Li on 6/6/20.
//

import UIKit

class AutonomousIconView: UIView {
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        backgroundColor = .clear

        let imageView = UIImageView(frame: CGRect(x: 10, y: 33, width: 14, height: 15))
        imageView.image = UIImage(named: "a-icon")
        addSubview(imageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        guard let color = UIColor(named: "asyncPurple")?.withAlphaComponent(0.7).cgColor else { return }
        context.clip(to: rect)
        context.setFillColor(color)
        context.move(to: CGPoint(x: 0, y: 0))
        context.addLine(to: CGPoint(x: 0, y: frame.height))
        context.addLine(to: CGPoint(x: frame.width, y: frame.height))
        context.fillPath()
    }
}
