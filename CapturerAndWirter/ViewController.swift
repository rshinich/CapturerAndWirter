//
//  ViewController.swift
//  CapturerAndWirter
//
//  Created by 张忠瑞 on 2024/9/16.
//

import UIKit

class ViewController: UIViewController {

    let cameraBtn = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.cameraBtn)

        self.cameraBtn.setTitle("Camera", for: .normal)
        self.cameraBtn.setTitleColor(.blue, for: .normal)
        self.cameraBtn.addTarget(self, action: #selector(cameraBtnClicked), for: .touchUpInside)
        self.cameraBtn.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        self.cameraBtn.center = self.view.center
    }

    @objc func cameraBtnClicked() {

        let capturerVC = CapturerViewController()
        capturerVC.modalPresentationStyle = .fullScreen
        self.present(capturerVC, animated: true)

    }
}

