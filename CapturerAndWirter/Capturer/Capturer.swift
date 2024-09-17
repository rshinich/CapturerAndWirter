//
//  Capturer.swift
//  CapturerAndWirter
//
//  Created by 张忠瑞 on 2024/9/16.
//

import Foundation
import AVFoundation
import UIKit

class Capturer: NSObject {

    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }

    private var setupResult: SessionSetupResult = .success

    private let sessionQueue = DispatchQueue(label: "com.zzr.camera.capture")
    private let videoOutputQueue = DispatchQueue(label: "com.zzr.camera.videoOutput")
    private let audioOutputQueue = DispatchQueue(label: "com.zzr.camera.audioOutput")

    private let session = AVCaptureSession()
    private var isSessionRunning = false

    private var videoDevice: AVCaptureDevice!
    private var videoDeviceInput: AVCaptureDeviceInput!

    private var videoOutput = AVCaptureVideoDataOutput()
    private var audioOutput = AVCaptureAudioDataOutput()

    private var preset: AVCaptureSession.Preset
    private var fps: Int32

    public var previewLayer: AVCaptureVideoPreviewLayer?

    public var onPreviewLayerSetSuccess: ((_ previewLayer: AVCaptureVideoPreviewLayer) -> Void)?
    public var onVideoSampleBuffer: ((_ sampleBuffer: CMSampleBuffer) -> Void)?
    public var onAudioSampleBuffer: ((_ sampleBuffer: CMSampleBuffer) -> Void)?

    // MARK: -

    public class func getSupportDevices() {

        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera, // 广角摄像头
            .builtInTelephotoCamera, // 长焦摄像头
            .builtInUltraWideCamera, // 超广角摄像头
            .builtInDualCamera,      // 双摄像头
            .builtInDualWideCamera,  // 双广角摄像头
            .builtInTripleCamera,    // 三摄像头
            .builtInTrueDepthCamera, // 景深摄像头(支持Face ID的摄像头) 主要用于需要捕捉FaceID的建模，或者类似Animoji之类的情况
        ]

        let position: AVCaptureDevice.Position = .unspecified

        let discoverySessions = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes,
                                                                 mediaType: .video,
                                                                 position: position)

        for device in discoverySessions.devices {
            print("discoverySession = \(device)")
        }
    }

    // MARK: -

    init(fps: Int32, preset: AVCaptureSession.Preset) {

        self.fps = fps
        self.preset = preset

        super.init()
        self.setup()
    }

    private func setup() {

        self.checkCameraAccess()

        self.sessionQueue.async {

            if self.session.canSetSessionPreset(self.preset) {
                self.session.sessionPreset = self.preset
            }

            self.configureSession()
            self.updateVideoFPS(self.fps)
            self.setupPreviewLayer()
        }
    }

    /// 检查相机权限
    private func checkCameraAccess() {

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: break
        case .notDetermined: do {
            self.sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted { self.setupResult = .notAuthorized }
                self.sessionQueue.resume()
            }
        }
        default: self.setupResult = .notAuthorized
        }
    }

    /// Call this on the session queue.
    private func configureSession() {

        guard self.setupResult == .success else {
            // TODO: log auth failed
            return
        }

        self.session.beginConfiguration()

        self.addVideoInput()
        self.addAudioInput()
        self.addVideoOutput()
        self.addAudioOutput()

        self.session.commitConfiguration()
    }

    private func addVideoInput() {

        do {
//            var defaultVideoDevice: AVCaptureDevice? = AVCaptureDevice.systemPreferredCamera
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {

                print("Create video device failed")
                self.setupResult = .configurationFailed
                return
            }

            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)

//            AVCaptureDevice.self.addObserver(self, forKeyPath: "systemPreferredCamera", options: [.new], context: &systemPreferredCameraContext)

            guard self.session.canAddInput(videoDeviceInput) else {

                print("Couldn't add video device input to the session.")
                self.setupResult = .configurationFailed
                return
            }

            self.session.addInput(videoDeviceInput)

            self.videoDevice = videoDevice
            self.videoDeviceInput = videoDeviceInput

            // TODO: createDeviceRotationCoordinator


        } catch {
            print("Couldn't create video device input: \(error)")
            self.setupResult = .configurationFailed
            return
        }

    }

    private func addAudioInput() {

        do {
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else {

                print("Create audio device failed")
                self.setupResult = .configurationFailed
                return
            }

            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)

            if self.session.canAddInput(audioDeviceInput) {
                self.session.addInput(audioDeviceInput)
            } else {
                print("Could not add audio device input to the session")
            }

        } catch {
            print("Could not create audio device input: \(error)")
        }

    }

    private func addVideoOutput() {

        self.videoOutput.alwaysDiscardsLateVideoFrames = false
        self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]

        guard self.session.canAddOutput(self.videoOutput) else {
            print("Could not add video data output to the session")
            self.setupResult = .configurationFailed
            return
        }

        self.session.addOutput(self.videoOutput)
        self.videoOutput.setSampleBufferDelegate(self, queue: self.videoOutputQueue)

    }

    private func addAudioOutput() {

        guard self.session.canAddOutput(self.audioOutput) else {
            print("Could not add audio data output to the session")
            self.setupResult = .configurationFailed
            return
        }

        self.session.addOutput(self.audioOutput)
        self.audioOutput.setSampleBufferDelegate(self, queue: self.audioOutputQueue)

    }

    private func setupPreviewLayer() {

        guard self.setupResult == .success else { return }

        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.previewLayer?.videoGravity = .resizeAspectFill
//        self.previewLayer?.connection?.videoOrientation = .portrait

        self.onPreviewLayerSetSuccess?(self.previewLayer!)
    }



    // MARK: - Public

    public func startRunning() {

        self.sessionQueue.async {

            switch self.setupResult {
            case .success:
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
            case .notAuthorized: break
            case .configurationFailed: break
            }
        }
    }

    public func stopRunning() {

        self.sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
            }
        }
    }

    // MARK: 更新分辨率
    public func updateSessionPreset(sessionPreset:AVCaptureSession.Preset,complate: @escaping ((_ preset: AVCaptureSession.Preset) -> Void)) {

        session.beginConfiguration()
        session.sessionPreset = sessionPreset
        session.commitConfiguration()

        preset = sessionPreset

        complate(preset)
    }

    // MARK: 更新FPS
    public func updateVideoFPS(_ fps: Int32) {

        guard self.setupResult == .success else {
            // TODO: log auth failed
            return
        }

        print("UpdateVideoFPS fps = \(fps)")

        do {
            try self.videoDeviceInput.device.lockForConfiguration()
//            self.videoDeviceInput.videoMinFrameDurationOverride = CMTimeMake(value: 1, timescale: fps)
            self.videoDeviceInput.device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: fps)
            self.videoDeviceInput.device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: fps)
            self.videoDeviceInput.device.unlockForConfiguration()
        } catch {
            print("UpdateVideoFPS failed with \(error)")
        }
    }

    //MARK: 更新zoom
    public func updateZoom(factor: CGFloat, rate: Float, isAnimation: Bool) {
        do {
            try videoDevice?.lockForConfiguration()
            if isAnimation {
                videoDevice?.cancelVideoZoomRamp()
                videoDevice?.ramp(toVideoZoomFactor: factor, withRate: rate)
            } else {
                videoDevice?.videoZoomFactor = factor
            }

            videoDevice?.unlockForConfiguration()
        } catch let error {
            print(error)
        }
    }

    /// 开关闪光灯
    public func turnOnOffTroch(_ isOn: Bool) {
        // TODO: complete me
    }

    // MARK: 切换摄像头
    public func switchingCamera() {

        var videoDevice: AVCaptureDevice?
        var isFrontNow = false

        if videoDevice?.position == .back {

            videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera , for: .video, position: .front)
            isFrontNow = true

        } else if videoDevice?.position == .front {

            videoDevice = AVCaptureDevice.default(.builtInUltraWideCamera , for: .video, position: .back)

            isFrontNow = false
        }

        self.videoDevice = videoDevice

    }

    public func updatePreviewVideoOrientation(videoOrientation: AVCaptureVideoOrientation) {

        self.previewLayer?.connection?.videoOrientation = videoOrientation

    }

    // MARK: - Snapshot

    private(set) var snapshotVideoBuffer: CMSampleBuffer?
    private(set) var currentVideoBuffer: CMSampleBuffer?

    public func doSnapshotVideoBuffer() {

        self.snapshotVideoBuffer = self.currentVideoBuffer
    }

    public func getSnapshotVideoBuffer() -> CMSampleBuffer? {

        return self.snapshotVideoBuffer
    }


    // MARK: - DeviceRotationCoordinator

//    private var videoRotationAngleForHorizonLevelPreviewObservation: NSKeyValueObservation?
//    private var videoDeviceRotationCoordinator: AVCaptureDevice.RotationCoordinator!
//
//    private func createDeviceRotationCoordinator() {
//        videoDeviceRotationCoordinator = AVCaptureDevice.RotationCoordinator(device: videoDeviceInput.device, previewLayer: self.previewLayer)
//        self.previewLayer?.connection?.videoRotationAngle = videoDeviceRotationCoordinator.videoRotationAngleForHorizonLevelPreview
//
//        videoRotationAngleForHorizonLevelPreviewObservation = videoDeviceRotationCoordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: .new) { _, change in
//            guard let videoRotationAngleForHorizonLevelPreview = change.newValue else { return }
//
//            self.previewLayer?.connection?.videoRotationAngle = videoRotationAngleForHorizonLevelPreview
//        }
//    }

}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate

extension Capturer: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        if output == self.videoOutput {

            self.currentVideoBuffer = sampleBuffer
            self.onVideoSampleBuffer?(sampleBuffer)

        } else if output == self.audioOutput {

            self.onAudioSampleBuffer?(sampleBuffer)
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

//        print("zzr+++captureOutput didDrop sampleBuffer = \(sampleBuffer), output = \(output)")

    }


}
