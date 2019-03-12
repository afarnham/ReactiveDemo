//
//  Style.swift
//  ReactiveDemo
//
//  Created by Raymond Farnham on 3/3/19.
//  Copyright © 2019 ForeFlight. All rights reserved.
//

import UIKit
import Overture

extension CGFloat {
    static func ff_grid(_ n: Int) -> CGFloat {
        return CGFloat(n) * 4.0
    }
}

let viewMargins = mut(
    \UIView.layoutMargins,
    .init(
        top: .ff_grid(6),
        left: .ff_grid(6),
        bottom: .ff_grid(6),
        right: .ff_grid(6)
    )
)

let autoLayoutStyle = mut(\UIView.translatesAutoresizingMaskIntoConstraints, false)

let baseLabelFont = UIFont.systemFont(ofSize: 20)

let baseLabelStyle = concat(autoLayoutStyle,
                            mut(\UILabel.textColor, .white),
                            mut(\UILabel.textAlignment, .center),
                            mut(\UILabel.backgroundColor, .darkGray))

let metarLabelStyle = concat(baseLabelStyle,
                             mut(\UILabel.lineBreakMode, .byWordWrapping),
                             mut(\UILabel.numberOfLines, 0))

let airportLabelStyle = baseLabelStyle

