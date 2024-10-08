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

    // MARK: -

    private let session = AVCaptureSession()
    private var isSessionRunning = false

    private var audioCaptureDevice: AVCaptureDevice?
    private(set) var videoCaptureDevice: AVCaptureDevice?

    private var videoDeviceInput: AVCaptureDeviceInput!
    private var audioDeviceInput: AVCaptureDeviceInput!

    private var videoOutput = AVCaptureVideoDataOutput()
    private var audioOutput = AVCaptureAudioDataOutput()

    private let sessionQueue = DispatchQueue(label: "com.zzr.camera.capture")
    private let videoOutputQueue = DispatchQueue(label: "com.zzr.camera.videoOutput")
    private let audioOutputQueue = DispatchQueue(label: "com.zzr.camera.audioOutput")

    public var previewLayer: AVCaptureVideoPreviewLayer?

    public var onPreviewLayerSetSuccess: ((_ previewLayer: AVCaptureVideoPreviewLayer) -> Void)?
    public var onVideoSampleBuffer: ((_ sampleBuffer: CMSampleBuffer) -> Void)?
    public var onAudioSampleBuffer: ((_ sampleBuffer: CMSampleBuffer) -> Void)?

    // MARK: -

    private override init() {
        super.init()
    }

    /// 初始化方法
    /// - Parameters:
    ///   - videoCaptureDevice: 通过外部指定捕获Video的Device，如果传空，则默认选择获取列表中的第一个；
    ///   - audioCaptureDevice: 通过外部指定捕获Audio的Device，如果传空，则默认选择获取列表中的第一个;
    ///   - completion:
    static func create(videoCaptureDevice: AVCaptureDevice? = nil, audioCaptureDevice: AVCaptureDevice? = nil, completion: @escaping (Result<Capturer, Error>) -> Void) {

        let instance = Capturer()

        instance.checkCameraAccess { [weak instance] cameraResult in
            guard let instance = instance else { return }

            switch cameraResult {
            case .success:
                instance.checkMicrophoneAccess { micResult in
                    switch micResult {
                    case .success:
                        instance.setupDevices(videoCaptureDevice: videoCaptureDevice, audioCaptureDevice: audioCaptureDevice)
                        instance.sessionQueue.async {
                            do {
                                try instance.configureSession()
                                completion(.success(instance))
                                instance.setupPreviewLayer()

                            } catch {
                                completion(.failure(error))
                            }
                        }
                    case .failure(let micError):
                        completion(.failure(micError))
                    }
                }
            case .failure(let cameraError):
                completion(.failure(cameraError))
            }
        }
    }

    private func setupDevices(videoCaptureDevice: AVCaptureDevice?, audioCaptureDevice: AVCaptureDevice?) {

        if let videoCaptureDevice = videoCaptureDevice {
            self.videoCaptureDevice = videoCaptureDevice
        } else {
            // TODO: 还是使用系统的 AVCaptureDevice.systemPreferredCamera？
            // AVCaptureDevice.self.addObserver(self, forKeyPath: "systemPreferredCamera", options: [.new], context: &systemPreferredCameraContext)
            self.videoCaptureDevice = CapturerHelpers.getSupportVideoDevices().first?.raw
        }

        if let audioCaptureDevice = audioCaptureDevice {
            self.audioCaptureDevice = audioCaptureDevice
        } else {
            self.audioCaptureDevice = CapturerHelpers.getSupportAudioDevices().first?.raw
        }
    }

    // MARK: - Access

    /// 检查相机权限
    private func checkCameraAccess(completion: @escaping (Result<Void, Error>) -> Void) {

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:   completion(.success(()))
        case .denied:       completion(.failure(CapturerError.videoDeviceAccessDenied))
        case .notDetermined: do {
            self.sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { granted in

                self.sessionQueue.resume()

                if granted {
                    completion(.success(()))
                } else {
                    completion(.failure(CapturerError.videoDeviceAccessDenied))
                }
            }
        }
        default:    completion(.failure(CapturerError.videoDeviceAccessDenied))
        }
    }

    private func checkMicrophoneAccess(completion: @escaping (Result<Void, Error>) -> Void) {

        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:   completion(.success(()))
        case .denied:       completion(.failure(CapturerError.audioDeviceAccessDenied))
        case .notDetermined: do {
            self.sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .audio) { granted in

                self.sessionQueue.resume()

                if granted {
                    completion(.success(()))
                } else {
                    completion(.failure(CapturerError.audioDeviceAccessDenied))
                }
            }
        }
        default:    completion(.failure(CapturerError.audioDeviceAccessDenied))
        }
    }

    // MARK: - Session

    /// Call this on the session queue.
    private func configureSession() throws {
        // 配置session（这里先不指定session的preset,使用默认的inputPriority，以保证后续设置ActiveFormat的成功 https://developer.apple.com/documentation/avfoundation/avcapturesessionpresetinputpriority）

        self.session.beginConfiguration()

        try self.addVideoInput()
        try self.addAudioInput()
        try self.addVideoOutput()
        try self.addAudioOutput()

        self.session.commitConfiguration()
    }

    private func addVideoInput() throws {

        guard let videoCaptureDevice = self.videoCaptureDevice else {
            print("Create video device failed")
            throw CapturerError.videoCaptureDeviceNotExist
        }

        let videoDeviceInput = try AVCaptureDeviceInput(device: videoCaptureDevice)

        if self.session.canAddInput(videoDeviceInput) {
            self.session.addInput(videoDeviceInput)
            self.videoDeviceInput = videoDeviceInput
        } else {
            print("Couldn't add video device input to the session.")
            throw CapturerError.addVideoInputFailed
        }

        // TODO: createDeviceRotationCoordinator
    }

    private func addAudioInput() throws {

        guard let audioCaptureDevice = self.audioCaptureDevice else {
            print("Create audio device failed")
            throw CapturerError.audioCaptureDeviceNotExist
        }

        let audioDeviceInput = try AVCaptureDeviceInput(device: audioCaptureDevice)

        if self.session.canAddInput(audioDeviceInput) {
            self.session.addInput(audioDeviceInput)
            self.audioDeviceInput = audioDeviceInput
        } else {
            print("Could not add audio device input to the session")
            throw CapturerError.addAudioInputFailed
        }
    }

    private func addVideoOutput() throws {

        self.videoOutput.alwaysDiscardsLateVideoFrames = false
        self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]

        guard self.session.canAddOutput(self.videoOutput) else {
            print("Could not add video data output to the session")
            throw CapturerError.addVideoOutputFailed
        }

        self.session.addOutput(self.videoOutput)
        self.videoOutput.setSampleBufferDelegate(self, queue: self.videoOutputQueue)

        // 设置横竖屏

        if let videoConnection = self.videoOutput.connection(with: .video) {
            // 根据设备的当前方向设置视频方向
            if UIDevice.current.orientation == .portrait {
                videoConnection.videoOrientation = .portrait
            } else if UIDevice.current.orientation == .landscapeRight {
                videoConnection.videoOrientation = .landscapeRight
            } else if UIDevice.current.orientation == .landscapeLeft {
                videoConnection.videoOrientation = .landscapeLeft
            } else if UIDevice.current.orientation == .portraitUpsideDown {
                videoConnection.videoOrientation = .portraitUpsideDown
            }
        }
    }

    private func addAudioOutput() throws {

        guard self.session.canAddOutput(self.audioOutput) else {
            print("Could not add audio data output to the session")
            throw CapturerError.addAudioOutputFailed
        }

        self.session.addOutput(self.audioOutput)
        self.audioOutput.setSampleBufferDelegate(self, queue: self.audioOutputQueue)
    }

    // MARK: - Preview

    private func setupPreviewLayer() {

        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.previewLayer?.videoGravity = .resizeAspectFill
//        self.previewLayer?.connection?.videoOrientation = .portrait

        self.onPreviewLayerSetSuccess?(self.previewLayer!)
    }

    public func updatePreviewVideoOrientation(videoOrientation: AVCaptureVideoOrientation) {

//        self.previewLayer?.connection?.videoOrientation = videoOrientation

        if let videoConnection = self.videoOutput.connection(with: .video) {
            videoConnection.videoOrientation = videoOrientation
        }

    }

    // MARK: - Public start or stop session

    public func startRunning() {

        self.sessionQueue.async {
            self.session.startRunning()
            self.isSessionRunning = self.session.isRunning
        }
    }

    public func stopRunning() {

        self.sessionQueue.async {
            self.session.stopRunning()
            self.isSessionRunning = self.session.isRunning
        }
    }

    // MARK: -

    // MARK: 更新分辨率
    public func updateSessionPreset(sessionPreset:AVCaptureSession.Preset,complate: @escaping ((_ preset: AVCaptureSession.Preset) -> Void)) {

//        session.beginConfiguration()
//        session.sessionPreset = sessionPreset
//        session.commitConfiguration()
//
//        preset = sessionPreset
//
//        complate(preset)
    }

    /// 设置分辨率和帧率，直接设置activeFormat，从getSupportFormats(captureDevice: AVCaptureDevice)中获取。
    /// https://developer.apple.com/documentation/avfoundation/avcapturedevice/1389221-activeformat
    /// - Parameter format:
    public func updateActiveFormat(format: CaptureDeviceFormatInfo) {

        guard let videoCaptureDevice = self.videoCaptureDevice else { return }

        self.session.beginConfiguration()

        do {
            try videoCaptureDevice.lockForConfiguration()

            // Set the device's active format.
            videoCaptureDevice.activeFormat = format.raw// a supported format.

            // Set the device's min/max frame duration.
            videoCaptureDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: Int32(format.maxFrameRate)) // a supported minimum duration.
            videoCaptureDevice.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: Int32(format.maxFrameRate))// a supported maximum duration.

            videoCaptureDevice.unlockForConfiguration()
        } catch {
            // Handle error.
        }


        // Apply the changes to the session.
        self.session.commitConfiguration()
    }

    // MARK: 更新FPS
    public func updateVideoFPS(_ fps: Int32) {

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

    // MARK: - Snapshot

    private(set) var snapshotVideoBuffer: CMSampleBuffer?
    private(set) var currentVideoBuffer: CMSampleBuffer?

    public func doSnapshotVideoBuffer() {

        self.snapshotVideoBuffer = self.currentVideoBuffer
    }

    public func getSnapshotVideoBuffer() -> CMSampleBuffer? {

        return self.snapshotVideoBuffer
    }

    // MARK: - Device, Foucs

    // MARK: - Device, Exposure

    // MARK: - Device, Flash

    // MARK: - Device, Torch

    // MARK: - Device, Video Stabilization

    // MARK: - Device, White Balance

    // MARK: - Device, Zoom

    public func updateZoom(factor: CGFloat, rate: Float, isAnimation: Bool) {

        guard let videoCaptureDevice = self.videoCaptureDevice else { return }

        do {
            try videoCaptureDevice.lockForConfiguration()
            if isAnimation {
                videoCaptureDevice.cancelVideoZoomRamp()
                videoCaptureDevice.ramp(toVideoZoomFactor: factor, withRate: rate)
            } else {
                videoCaptureDevice.videoZoomFactor = factor
            }

            videoCaptureDevice.unlockForConfiguration()
        } catch let error {
            print(error)
        }
    }

    // MARK: - Device Orientation

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

    // MARK: - Device
    
    /// 切换摄像头，判断当前摄像头是前摄还是后摄，使用相反的摄像头
    public func switchingCamera() {

        if self.videoCaptureDevice?.position == .back {

            if let videoCaptureDevice = CapturerHelpers.getSupportVideoDevices(position: .front).first?.raw {
                self.updateVideoCaptureDevice(videoCaptureDevice: videoCaptureDevice)
            }

        } else if self.videoCaptureDevice?.position == .front {

            if let videoCaptureDevice = CapturerHelpers.getSupportVideoDevices(position: .back).first?.raw {
                self.updateVideoCaptureDevice(videoCaptureDevice: videoCaptureDevice)
            }

        } else {

        }
    }
    
    /// 更新当前使用的摄像头信息
    /// - Parameter videoCaptureDevice: Device实例
    public func updateVideoCaptureDevice(videoCaptureDevice: AVCaptureDevice) {

        self.session.beginConfiguration()

        self.session.removeInput(self.videoDeviceInput)

        self.videoCaptureDevice = videoCaptureDevice
        try? self.addVideoInput()

        self.session.commitConfiguration()
    }

    // MARK: - Calculator

    private var lastTimestamp: CMTime?
    private var frameCount: Int = 0
    private var frameRate: Double = 0.0
    private var startTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate

extension Capturer: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {


    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        if output == self.videoOutput {

            self.currentVideoBuffer = sampleBuffer
            self.onVideoSampleBuffer?(sampleBuffer)

//            self.calaulatorResAndFps(sampleBuffer: sampleBuffer)

        } else if output == self.audioOutput {

            self.onAudioSampleBuffer?(sampleBuffer)
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        //        print("zzr+++captureOutput didDrop sampleBuffer = \(sampleBuffer), output = \(output)")

    }

    func calaulatorResAndFps(sampleBuffer: CMSampleBuffer) {

        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)

        // 打印分辨率
        print("[Calculator] 当前分辨率: \(width)x\(height)")

        // 获取当前帧的时间戳
        let currentTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        // 计算瞬时帧率
        if let lastTimestamp = lastTimestamp {
            let elapsed = CMTimeGetSeconds(currentTimestamp - lastTimestamp)
            if elapsed > 0 {
                frameRate = 1.0 / elapsed
//                print(String(format: "[Calculator] 瞬时帧率: %.2f FPS", frameRate))
            }
        }

        lastTimestamp = currentTimestamp

        // 动态计算平均帧率（每秒统计一次）
        frameCount += 1
        let currentTime = CFAbsoluteTimeGetCurrent()
        let elapsedTime = currentTime - startTime

        if elapsedTime >= 1.0 {
            frameRate = Double(frameCount) / elapsedTime
            frameCount = 0
            startTime = currentTime
            print(String(format: "[Calculator] 动态计算帧率: %.2f FPS", frameRate))
        }
    }
}
