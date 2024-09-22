//
//  RulerScrollView.swift
//  CapturerAndWirter
//
//  Created by 张忠瑞 on 2024/9/22.
//

import UIKit

class RulerScrollView: UIView, UIScrollViewDelegate {

    let scrollView = UIScrollView()
    let rulerView: RulerView

    let rulerWidth: CGFloat = 1000   // 视图的总长度，控制刻度尺的宽度
    let markSpacing: CGFloat = 10.0  // 每个刻度的间距
    let numberOfMarks: Int           // 总的刻度数量

    var currentMark: Int = 0 {       // 当前刻度
        didSet {
            print("当前刻度: \(currentMark)")
        }
    }

    init(frame: CGRect, numberOfMarks: Int, majorMarkInterval: Int) {
        self.numberOfMarks = numberOfMarks
        self.rulerView = RulerView(frame: CGRect(x: 0, y: 0, width: rulerWidth, height: frame.height), numberOfMarks: numberOfMarks, majorMarkInterval: majorMarkInterval, markSpacing: markSpacing)
        super.init(frame: frame)

        scrollView.frame = self.bounds
        scrollView.contentSize = CGSize(width: rulerWidth, height: frame.height)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.addSubview(rulerView)

        self.addSubview(scrollView)

        // 中心标线
        let indicatorLine = UIView(frame: CGRect(x: frame.width / 2 - 1, y: 0, width: 2, height: 10))
        indicatorLine.backgroundColor = .yellow
        self.addSubview(indicatorLine)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func transformRotation(angle: CGFloat) {

        self.rulerView.transformRotation(angle: angle)
    }

    // 监听滚动，计算当前刻度
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.x + scrollView.bounds.width / 2
        let newMark = Int(offset / markSpacing)
        if newMark != currentMark {
            currentMark = newMark
        }
    }

    // 当减速结束时（即滑动停止时）自动贴近最近的刻度
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        snapToNearestMark()
    }

    // 当用户结束拖动时（无论是否减速）自动贴近最近的刻度
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            snapToNearestMark()
        }
    }

    // 让刻度自动贴近最近的刻度
    private func snapToNearestMark() {
        let offset = scrollView.contentOffset.x + scrollView.bounds.width / 2
        let nearestMark = round(offset / markSpacing)
        let targetOffsetX = nearestMark * markSpacing - scrollView.bounds.width / 2

        // 使用动画平滑滚动到最近的刻度
        scrollView.setContentOffset(CGPoint(x: targetOffsetX, y: scrollView.contentOffset.y), animated: true)

        // 更新当前刻度
        currentMark = Int(nearestMark)
    }
}
