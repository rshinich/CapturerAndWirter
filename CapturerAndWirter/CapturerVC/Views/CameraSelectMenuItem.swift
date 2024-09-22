//
//  CameraSelectMenuItem.swift
//  CapturerAndWirter
//
//  Created by 张忠瑞 on 2024/9/22.
//

import UIKit

class CameraSelectMenuItem: UIButton {

    let iconImageView = UIImageView()
    let nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.iconImageView)
        self.addSubview(self.nameLabel)

        self.iconImageView.image = UIImage(named: "BackTripleCameraNormal")
        self.iconImageView.frame = CGRect(x: (self.bounds.height - 20) / 2, y: (self.bounds.height - 20) / 2, width: 20, height: 20)
        self.iconImageView.contentMode = .scaleAspectFit

        self.nameLabel.text = "BackTriple Camera"
        self.nameLabel.font = UIFont.systemFont(ofSize: 14)
        self.nameLabel.textColor = .white
        self.nameLabel.frame = CGRect(x: self.bounds.height, y: 0, width: self.bounds.width - self.bounds.height, height: self.bounds.height)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

}
