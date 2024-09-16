//
//  CapturerViewController.swift
//  CapturerAndWirter
//
//  Created by 张忠瑞 on 2024/9/16.
//

import UIKit

class CapturerViewController: UIViewController {

    let capturer: Capturer = Capturer(fps: 30, preset: .iFrame1280x720)

    override func viewDidLoad() {
        super.viewDidLoad()

        self.capturer.startRunning()

        self.capturer.onPreviewLayerSetSuccess = { [weak self] previewLayer in

            guard let self = self else { return }

            DispatchQueue.main.async {
                previewLayer.frame = self.view.bounds
                self.view.layer.addSublayer(previewLayer)
            }

        }
    }
    


}
