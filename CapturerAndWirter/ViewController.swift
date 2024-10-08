//
//  ViewController.swift
//  CapturerAndWirter
//
//  Created by 张忠瑞 on 2024/9/16.
//

import UIKit
import SnapKit

class ViewController: UIViewController {

    let cameraBtn = UIButton()
    let tableview = UITableView(frame: .zero, style: .plain)

    var devices: [CaptureDeviceInfo] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let videoDevices = CapturerHelpers.getSupportVideoDevices()
        let audioDevices = CapturerHelpers.getSupportAudioDevices()
        self.devices = videoDevices + audioDevices

//        for device in devices {
//
//            Capturer.getSupportFormats(captureDevice: device)
//            print("------")
//        }


        self.view.addSubview(self.tableview)
        self.view.addSubview(self.cameraBtn)

        self.tableview.delegate = self
        self.tableview.dataSource = self
        self.tableview.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-100)
        }

        self.cameraBtn.setTitle("Camera", for: .normal)
        self.cameraBtn.setTitleColor(.blue, for: .normal)
        self.cameraBtn.addTarget(self, action: #selector(cameraBtnClicked), for: .touchUpInside)
        self.cameraBtn.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(self.tableview.snp.bottom)
        }
    }

    @objc func cameraBtnClicked() {

        let capturerVC = CapturerViewController()
        capturerVC.modalPresentationStyle = .fullScreen
        self.present(capturerVC, animated: true)

    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return self.devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")

        let device = self.devices[indexPath.row]

        cell.textLabel?.text = device.name

        return cell

    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)


        let device = self.devices[indexPath.row]

        print("device is \(device.name)")

        CapturerHelpers.getSupportFormats(captureDevice: device.raw)
    }

}

