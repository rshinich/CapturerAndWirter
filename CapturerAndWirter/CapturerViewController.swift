//
//  CapturerViewController.swift
//  CapturerAndWirter
//
//  Created by 张忠瑞 on 2024/9/16.
//

import UIKit
import AVFoundation
import Foundation

class CapturerViewController: UIViewController {

    let capturer: Capturer = Capturer(fps: 30, preset: .hd1280x720)
    var writer: VideoWriter?

    let cameraView = UIView()
    let returnBtn = UIButton()
    let recordBtn = UIButton()

    // MARK: -

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait    // 只支持竖屏
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait    // 设置默认方向为竖屏
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupCapturer()
        self.setupView()
        self.setupNotification()
        self.handleDeviceOrientationChange()
    }

    private func setupCapturer() {

        self.capturer.startRunning()

        self.capturer.onPreviewLayerSetSuccess = { [weak self] previewLayer in

            guard let self = self else { return }

            DispatchQueue.main.async {

                let width = Int(UIScreen.main.bounds.width)
                let height = Int(UIScreen.main.bounds.width * 16.0 / 9.0)

                previewLayer.frame = CGRect(x: 0, y: (Int(self.view.bounds.height) - height)/2, width: width, height: height)
                self.cameraView.layer.addSublayer(previewLayer)
            }
        }

        self.capturer.onVideoSampleBuffer = { [weak self] videoSampleBuffer in

            if self?.writer?.isRecording ?? false {
                self?.writer?.appendVideoSampleBuffer(videoSampleBuffer)
            }

        }

        self.capturer.onAudioSampleBuffer = { [weak self] audioSampleBuffer in

            if self?.writer?.isRecording ?? false {
                self?.writer?.appendAudioSampleBuffer(audioSampleBuffer)
            }
        }
    }

    private func setupView() {

        self.view.backgroundColor = .black

        self.view.addSubview(self.cameraView)
        self.cameraView.backgroundColor = .black
        self.cameraView.frame = self.view.bounds

        self.view.addSubview(self.returnBtn)
        self.returnBtn.setImage(UIImage.init(systemName: "x.circle.fill"), for: .normal)
        self.returnBtn.addTarget(self, action: #selector(returnBtnClicked), for: .touchUpInside)
        self.returnBtn.frame = CGRect(x: 10, y: 50, width: 44, height: 44)

        self.view.addSubview(self.recordBtn)
        self.recordBtn.setImage(UIImage.init(systemName: "stop.circle"), for: .normal)
        self.recordBtn.addTarget(self, action: #selector(recordBtnClciked), for: .touchUpInside)
        self.recordBtn.frame = CGRect(x: self.view.bounds.midX - 50, y: self.view.bounds.maxY - 200, width: 100, height: 100)
    }

    private func setupNotification() {

        NotificationCenter.default.addObserver(self, selector: #selector(handleDeviceOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)

    }

    // MARK: -

    private func startRecording() {

        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        // 创建一个唯一的文件名
        let fileName = UUID().uuidString + ".mov"
        let fullURL = documentsDirectory.appendingPathComponent(fileName)

        guard let currentVideoBuffer = self.capturer.currentVideoBuffer else { return }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(currentVideoBuffer) else { return }

        self.writer = VideoWriter(outputURL: fullURL, videoSize: CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer)), completion: { error in
            if error == nil {
                print("start recording in \(fullURL)")
            } else {
                print("start recording with error \(error)")
            }
        })

        guard let currentVideoBuffer = self.capturer.currentVideoBuffer else { return }

        let startSessionSourceTime = CMSampleBufferGetPresentationTimeStamp(currentVideoBuffer)

        self.writer?.startRecording(startSessionSourceTime: startSessionSourceTime)
    }

    private func stopRecording() {

        self.writer?.stopRecording { error in

            if error == nil {
                print("stop recording")
            } else {
                print("stop recording with error \(error)")
            }
        }
    }

    // MARK: - Events

    @objc func returnBtnClicked() {
        self.dismiss(animated: true)
    }

    @objc func recordBtnClciked() {

        if self.writer?.isRecording ?? false {
            self.stopRecording()
        } else {
            self.startRecording()
        }
    }

    @objc func handleDeviceOrientationChange() {

        guard self.writer?.isRecording != true else { return }

        let orientation = UIDevice.current.orientation
        switch orientation {
        case .portrait:
            print("设备现在是竖屏模式")
            self.capturer.updatePreviewVideoOrientation(videoOrientation: .portrait)
        case .landscapeLeft:
            print("设备现在是左横屏模式")
            self.capturer.updatePreviewVideoOrientation(videoOrientation: .landscapeRight)
        case .landscapeRight:
            print("设备现在是右横屏模式")
            self.capturer.updatePreviewVideoOrientation(videoOrientation: .landscapeLeft)
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
}
