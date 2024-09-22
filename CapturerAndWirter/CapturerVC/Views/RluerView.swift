//
//  RluerView.swift
//  CapturerAndWirter
//
//  Created by 张忠瑞 on 2024/9/22.
//

import UIKit

class RulerView: UIView {

    let numberOfMarks: Int      // 总的刻度数
    let majorMarkInterval: Int  // 主刻度间隔
    let markSpacing: CGFloat    // 每个刻度之间的间距
    let majorMarkHeight: CGFloat = 10  // 主刻度高度
    let minorMarkHeight: CGFloat = 5  // 次刻度高度
    let markWidth: CGFloat = 1         // 刻度线的宽度
    var labels: [UILabel] = []

    init(frame: CGRect, numberOfMarks: Int, majorMarkInterval: Int, markSpacing: CGFloat) {
        self.numberOfMarks = numberOfMarks
        self.majorMarkInterval = majorMarkInterval
        self.markSpacing = markSpacing
        super.init(frame: frame)
        self.backgroundColor = .clear

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func transformRotation(angle: CGFloat) {

        for label in self.labels {
            label.transform = CGAffineTransform(rotationAngle: angle)
        }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

//        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(markWidth)

        // 开始绘制刻度
        for i in 0...numberOfMarks {
            let xPosition = CGFloat(i) * markSpacing
            let isMajorMark = i % majorMarkInterval == 0

            if isMajorMark {
                context.setStrokeColor(UIColor.white.cgColor)
            } else {
                context.setStrokeColor(UIColor.gray.cgColor)
            }

            let markHeight = isMajorMark ? majorMarkHeight : minorMarkHeight
            let startY: CGFloat = 0
            let endY = markHeight

            // 画刻度线
            context.move(to: CGPoint(x: xPosition, y: startY))
            context.addLine(to: CGPoint(x: xPosition, y: endY))
            context.strokePath()

            // 如果是主刻度，还要绘制刻度数值
            if isMajorMark {
                let label = UILabel(frame: CGRect(x: xPosition - 8, y: 15, width: 16, height: 12))
                label.text = "\(i)"
                label.textAlignment = .center
                label.font = UIFont.systemFont(ofSize: 10)
                label.textColor = .white
                self.addSubview(label)

                self.labels.append(label)
            }
        }
    }
}
