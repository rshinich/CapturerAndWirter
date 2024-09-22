//
//  CameraSelectMenuView.swift
//  CapturerAndWirter
//
//  Created by 张忠瑞 on 2024/9/22.
//

import UIKit

class CameraSelectMenuView: UIView {

    let bgView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.bgView)
        self.bgView.frame = self.bounds
        self.bgView.layer.borderWidth = 1
        self.bgView.layer.borderColor = UIColor.clear.cgColor
        self.bgView.layer.cornerRadius = 2
        self.bgView.backgroundColor = UIColor(white: 0, alpha: 0.4)

        let item1 = CameraSelectMenuItem(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: 40))
        self.addSubview(item1)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
