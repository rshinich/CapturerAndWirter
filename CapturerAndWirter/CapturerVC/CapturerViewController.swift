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

    var capturer: Capturer?
    var writer: VideoWriter?

    let cameraView = UIView()
    let returnBtn = UIButton()
    var recordBtn: RecordButton?
    var cameraSelectBtn: CameraSelectButton?
    var parametersBtn: ParametersButton?
    var ruleScorllView: RulerScrollView?

    // MARK: -

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait    // 只支持竖屏
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait    // 设置默认方向为竖屏
    }

    override var prefersStatusBarHidden: Bool {
        return true  // 返回 true 表示隐藏状态栏，false 表示显示状态栏
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupCapturer()
        self.setupView()
        self.setupNotification()
        self.handleDeviceOrientationChange()
    }

    private func setupCapturer() {

        Capturer.create { result in
            switch result {
            case .success(let capturer):
                self.startCapturerRunning(capturer: capturer)
            case .failure(let error):
                print("Failed to create Capturer: \(error)")
            }
        }
    }

    private func startCapturerRunning(capturer: Capturer) {

        self.capturer = capturer

        self.capturer?.startRunning()

        self.capturer?.onPreviewLayerSetSuccess = { [weak self] previewLayer in

            guard let self = self else { return }

            DispatchQueue.main.async {

                let width = Int(UIScreen.main.bounds.width)
                let height = Int(UIScreen.main.bounds.width * 16.0 / 9.0)

                previewLayer.frame = CGRect(x: 0, y: (Int(self.view.bounds.height) - height)/2, width: width, height: height)
                self.cameraView.layer.addSublayer(previewLayer)
            }
        }

        self.capturer?.onVideoSampleBuffer = { [weak self] videoSampleBuffer in

            if self?.writer?.isRecording ?? false {
                self?.writer?.appendVideoSampleBuffer(videoSampleBuffer)
            }

        }

        self.capturer?.onAudioSampleBuffer = { [weak self] audioSampleBuffer in

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
        self.returnBtn.frame = CGRect(x: 10, y: 100, width: 44, height: 44)

        self.recordBtn = RecordButton(frame: CGRect(x: self.view.bounds.midX - 40, y: self.view.bounds.maxY - 180, width: 80, height: 80))
        self.view.addSubview(self.recordBtn!)
        self.recordBtn!.addTarget(self, action: #selector(recordBtnClciked), for: .touchUpInside)

        let y = (UIScreen.main.bounds.height/2.0 + UIScreen.main.bounds.width * 16.0 / 9.0 / 2.0)
        let ruler = RulerScrollView(frame: CGRect(x: 0, y: y, width: UIScreen.main.bounds.width, height: 40), numberOfMarks: 100, majorMarkInterval: 10)
        self.view.addSubview(ruler)
        self.ruleScorllView = ruler

        let cameraSelectBtn = CameraSelectButton(frame: CGRect(x: 10, y: 30, width: 44, height: 44))
        cameraSelectBtn.addTarget(self, action: #selector(cameraSelectBtnClicked), for: .touchUpInside)
        self.view.addSubview(cameraSelectBtn)
        self.cameraSelectBtn = cameraSelectBtn

        let parametersBtn = ParametersButton(frame: CGRect(x: UIScreen.main.bounds.width - 110, y: 30, width: 100, height: 44))
        parametersBtn.addTarget(self, action: #selector(parametersBtnClicked), for: .touchUpInside)
        self.view.addSubview(parametersBtn)
        self.parametersBtn = parametersBtn
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

        guard let currentVideoBuffer = self.capturer?.currentVideoBuffer else { return }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(currentVideoBuffer) else { return }

        self.writer = VideoWriter(outputURL: fullURL, videoSize: CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer)), completion: { error in
            if error == nil {
                print("start recording in \(fullURL)")
            } else {
                print("start recording with error \(error)")
            }
        })

        guard let currentVideoBuffer = self.capturer?.currentVideoBuffer else { return }

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
            self.recordBtn?.stopRecordingAnimation()
            self.stopRecording()
        } else {
            self.recordBtn?.startRecordingAnimation()
            self.startRecording()
        }
    }

    @objc func cameraSelectBtnClicked() {

        let cameraSelectView = CameraSelectMenuView(frame: CGRect(x: 10, y: 100, width: 200, height: 300))
        self.view.addSubview(cameraSelectView)
    }

    @objc func parametersBtnClicked() {

        let parametersMenuView = ParametersMenuView(frame: CGRect(x: 10, y: 100, width: 400, height: 300))
        self.view.addSubview(parametersMenuView)

        if let videoCaptureDevice = self.capturer?.videoCaptureDevice {
            let formats = Capturer.getSupportFormats(captureDevice: videoCaptureDevice)
            parametersMenuView.updateInfo(formats: formats)
        }

        parametersMenuView.didSelectedFormat = { [weak self] format in
            self?.capturer?.updateActiveFormat(format: format, activeVideoMinFrameDuration: CMTime(), activeVideoMaxFrameDuration: CMTime())
        }
    }

    @objc func handleDeviceOrientationChange() {

        guard self.writer?.isRecording != true else { return }

        var angle: CGFloat = 0

        let orientation = UIDevice.current.orientation
        switch orientation {
        case .portrait:
            print("设备现在是竖屏模式")
            self.capturer?.updatePreviewVideoOrientation(videoOrientation: .portrait)
            angle = 0
        case .landscapeLeft:
            print("设备现在是左横屏模式")
            self.capturer?.updatePreviewVideoOrientation(videoOrientation: .landscapeRight)
            angle = .pi/2
        case .landscapeRight:
            print("设备现在是右横屏模式")
            self.capturer?.updatePreviewVideoOrientation(videoOrientation: .landscapeLeft)
            angle = -.pi/2
        case .portraitUpsideDown:
            print("设备现在是倒立竖屏模式")
            return
        case .faceUp:
            print("设备现在是平放屏幕朝上")
            return
        case .faceDown:
            print("设备现在是平放屏幕朝下")
            return
        case .unknown:
            print("未知设备方向")
            return
        @unknown default:
            print("新设备方向")
            return
        }

        UIView.animate(withDuration: 0.3) {
            self.cameraSelectBtn?.transformRotation(angle: angle)
            self.parametersBtn?.transformRotation(angle: angle)
            self.ruleScorllView?.transformRotation(angle: angle)
        }

    }
}
