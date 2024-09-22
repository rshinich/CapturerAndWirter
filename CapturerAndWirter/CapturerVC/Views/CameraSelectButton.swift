//
//  CameraSelectButton.swift
//  CapturerAndWirter
//
//  Created by 张忠瑞 on 2024/9/22.
//

import UIKit

class CameraSelectButton: UIButton {

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.setImage(UIImage(named: "BackTripleCameraNormal"), for: .normal)

    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.setImage(UIImage(named: "BackTripleCameraNormal"), for: .normal)

    }

    public func transformRotation(angle: CGFloat) {

        self.transform = CGAffineTransform(rotationAngle: angle)
    }

}
