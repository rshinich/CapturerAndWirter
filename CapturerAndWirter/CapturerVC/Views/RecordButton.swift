//
//  RecordButton.swift
//  CapturerAndWirter
//
//  Created by 张忠瑞 on 2024/9/21.
//

import UIKit

class RecordButton: UIButton {

    private let borderView = UIView()
    private let animatedView = UIView()

    override init(frame: CGRect) {

        super.init(frame: frame)

        // 边框视图设置
        self.addSubview(self.borderView)
        self.borderView.backgroundColor = .clear
        self.borderView.layer.borderWidth = 4
        self.borderView.layer.borderColor = UIColor.white.cgColor
        self.borderView.isUserInteractionEnabled = false
        self.borderView.isExclusiveTouch = false
        self.borderView.frame = self.bounds
        self.borderView.layer.cornerRadius = self.bounds.width / 2.0

        // 红色动画视图设置
        self.addSubview(self.animatedView)
        self.animatedView.backgroundColor = .red
        self.animatedView.layer.borderWidth = 1
        self.animatedView.layer.borderColor = UIColor.clear.cgColor
        self.animatedView.isUserInteractionEnabled = false
        self.animatedView.isExclusiveTouch = false
        let padding: CGFloat = 8
        let animatedSize = self.bounds.width - 2 * padding
        self.animatedView.frame = CGRect(x: padding, y: padding, width: animatedSize, height: animatedSize)
        self.animatedView.layer.cornerRadius = animatedSize / 2.0

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func startRecordingAnimation() {
        // 缩小到某个尺寸，比如说宽度减少 50%
        let newSize = CGSize(width: self.animatedView.frame.width * 0.6, height: self.animatedView.frame.height * 0.6)
        let newCornerRadius: CGFloat = 10

        UIView.animate(withDuration: 0.3) {
            self.animatedView.layer.cornerRadius = newCornerRadius
            self.animatedView.bounds = CGRect(origin: CGPoint.zero, size: newSize)
        }
    }

    public func stopRecordingAnimation() {
        // 恢复到原始尺寸
        let originalSize = CGSize(width: self.bounds.width - 16, height: self.bounds.height - 16)
        let originalCornerRadius = (self.bounds.width - 16) / 2.0

        UIView.animate(withDuration: 0.3) {
            self.animatedView.layer.cornerRadius = originalCornerRadius
            self.animatedView.bounds = CGRect(origin: CGPoint.zero, size: originalSize)
        }

    }
}
