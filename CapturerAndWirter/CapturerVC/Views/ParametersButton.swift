//
//  ParametersButton.swift
//  CapturerAndWirter
//
//  Created by 张忠瑞 on 2024/9/22.
//

import UIKit

class ParametersButton: UIButton {

    let stackView = UIStackView()
    let fpsLabel = UILabel()
    let point1Label = UILabel()
    let resolutionLabel = UILabel()
    let point2Label = UILabel()
    let bitRateLabel = UILabel()

    override init(frame: CGRect) {

        super.init(frame: frame)

        self.addSubview(self.stackView)
        self.stackView.frame = self.bounds
        self.stackView.axis = .horizontal
        self.stackView.distribution = .fillProportionally
        self.stackView.alignment = .fill
        self.stackView.isUserInteractionEnabled = false

        self.stackView.addArrangedSubview(self.bitRateLabel)
        self.stackView.addArrangedSubview(self.point1Label)
        self.stackView.addArrangedSubview(self.resolutionLabel)
        self.stackView.addArrangedSubview(self.point2Label)
        self.stackView.addArrangedSubview(self.fpsLabel)

        self.fpsLabel.text = "30"
        self.fpsLabel.textAlignment = .center
        self.fpsLabel.textColor = .white
        self.fpsLabel.font = UIFont.systemFont(ofSize: 12)

        self.point1Label.text = "·"
        self.point1Label.textAlignment = .center
        self.point1Label.textColor = .white
        self.point1Label.font = UIFont.systemFont(ofSize: 12)

        self.resolutionLabel.text = "HD"
        self.resolutionLabel.textAlignment = .center
        self.resolutionLabel.textColor = .white
        self.resolutionLabel.font = UIFont.systemFont(ofSize: 12)

        self.point2Label.text = "·"
        self.point2Label.textAlignment = .center
        self.point2Label.textColor = .white
        self.point2Label.font = UIFont.systemFont(ofSize: 12)

        self.bitRateLabel.text = "5M/s"
        self.bitRateLabel.textAlignment = .center
        self.bitRateLabel.textColor = .white
        self.bitRateLabel.font = UIFont.systemFont(ofSize: 12)
    }

    @objc func handleDeviceOrientationChange() {

        let orientation = UIDevice.current.orientation
        switch orientation {
        case .portrait:
            print("设备现在是竖屏模式")
            UIView.animate(withDuration: 0.3) {
                self.transformRotation(angle: 0)
            }
        case .landscapeLeft:
            print("设备现在是左横屏模式")
            UIView.animate(withDuration: 0.3) {
                self.transformRotation(angle: .pi / 2)
            }
        case .landscapeRight:
            print("设备现在是右横屏模式")
            UIView.animate(withDuration: 0.3) {
                self.transformRotation(angle: -.pi / 2)
            }
        case .portraitUpsideDown:
            print("设备现在是倒立竖屏模式")
        case .faceUp:
            print("设备现在是平放屏幕朝上")
        case .faceDown:
            print("设备现在是平放屏幕朝下")
        case .unknown:
            print("未知设备方向")
        @unknown default:
            print("新设备方向")
        }
    }

    public func transformRotation(angle: CGFloat) {

        self.fpsLabel.transform = CGAffineTransform(rotationAngle: angle)
        self.resolutionLabel.transform = CGAffineTransform(rotationAngle: angle)
        self.bitRateLabel.transform = CGAffineTransform(rotationAngle: angle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

}
