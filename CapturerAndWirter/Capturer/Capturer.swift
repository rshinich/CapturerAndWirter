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


//    private var preset: AVCaptureSession.Preset
//    private var fps: Int32

    public var previewLayer: AVCaptureVideoPreviewLayer?

    public var onPreviewLayerSetSuccess: ((_ previewLayer: AVCaptureVideoPreviewLayer) -> Void)?
    public var onVideoSampleBuffer: ((_ sampleBuffer: CMSampleBuffer) -> Void)?
    public var onAudioSampleBuffer: ((_ sampleBuffer: CMSampleBuffer) -> Void)?

    // MARK: -

    private let session = AVCaptureSession()
    private var isSessionRunning = false

    private var audioCaptureDevice: AVCaptureDevice?
    private(set) var videoCaptureDevice: AVCaptureDevice?

    private var videoDeviceInput: AVCaptureDeviceInput!
    private var audioDeviceInput: AVCaptureDeviceInput!

    private var videoOutput = AVCaptureVideoDataOutput()
    private var audioOutput = AVCaptureAudioDataOutput()

    // MARK: -

    //

    public class func getSupportDefinition() {

        // 标清 Standard Definition: 640x480p
        // 高清 High Definition: 1280x720p
        // 全高清 Full High Definition: 1920x1080p
        // 超高清 Ultra High Definition: 3840x2160(4k)，7268x4320(8k)

    }

    public class func getSupportAudioDevices() -> [AVCaptureDevice] {

        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInMicrophone  // 麦克风
        ]

        let discoverySessions = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: .audio, position: .unspecified)

        return discoverySessions.devices
    }

    public class func getSupportVideoDevices(position: AVCaptureDevice.Position = .unspecified) -> [AVCaptureDevice] {

        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera, // 广角摄像头
            .builtInTelephotoCamera, // 长焦摄像头
            .builtInUltraWideCamera, // 超广角摄像头
            .builtInDualCamera,      // 双摄像头
            .builtInDualWideCamera,  // 双广角摄像头
            .builtInTripleCamera,    // 三摄像头
            .builtInTrueDepthCamera, // 景深摄像头(支持Face ID的摄像头) 主要用于需要捕捉FaceID的建模，或者类似Animoji之类的情况
        ]

        let discoverySessions = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes,
                                                                 mediaType: .video,
                                                                 position: position)

        for device in discoverySessions.devices {
            print("discoverySession = \(device), localizedName = \(device.localizedName)")
        }

        return discoverySessions.devices
    }

    public class func getSupportFormats(captureDevice: AVCaptureDevice) -> [AVCaptureDevice.Format] {

        for format in captureDevice.formats {

//            print("\(format.description)")

            let desc = format.formatDescription
            let dimensions = CMVideoFormatDescriptionGetDimensions(desc)

            print("device \(captureDevice) support dimensions = \(dimensions)")

            for range in format.videoSupportedFrameRateRanges {
                let minFrameRate = range.minFrameRate
                let maxFrameRate = range.maxFrameRate
                print("Supported frame rate range: \(minFrameRate) to \(maxFrameRate) FPS")

            }

        }

        let minZoomFactor = captureDevice.minAvailableVideoZoomFactor
        let maxZoomFactor = captureDevice.maxAvailableVideoZoomFactor
        print("Minimum Zoom Factor: \(minZoomFactor)")
        print("Maximum Zoom Factor: \(maxZoomFactor)")

        // TODO: 解耦，返回一些合集的参数
        return captureDevice.formats
    }

    public class func getSupportDimensions(captureDevice: AVCaptureDevice) {

        for format in captureDevice.formats {

            let desc = format.formatDescription
            let dimensions = CMVideoFormatDescriptionGetDimensions(desc)

            print("device \(captureDevice) support dimensions = \(dimensions)")
        }
    }

    public class func getSupportFrameRateRanges(captureDevice: AVCaptureDevice) {

        for format in captureDevice.formats {

            for range in format.videoSupportedFrameRateRanges {
                let minFrameRate = range.minFrameRate
                let maxFrameRate = range.maxFrameRate
                print("Supported frame rate range: \(minFrameRate) to \(maxFrameRate) FPS")

            }
        }
    }

    public class func getSupportZoomRange(captureDevice: AVCaptureDevice) {

        let minZoomFactor = captureDevice.minAvailableVideoZoomFactor
        let maxZoomFactor = captureDevice.maxAvailableVideoZoomFactor

        print("Minimum Zoom Factor: \(minZoomFactor)")
        print("Maximum Zoom Factor: \(maxZoomFactor)")
    }

    // MARK: -
    
    /// 初始化方法
    /// - Parameters:
    ///   - videoCaptureDevice: 通过外部指定捕获Video的Device，如果传空，则默认选择获取列表中的第一个；
    ///   - audioCaptureDevice: 通过外部指定捕获Audio的Device，如果传空，则默认选择获取列表中的第一个;
    init(videoCaptureDevice: AVCaptureDevice? = nil, audioCaptureDevice: AVCaptureDevice? = nil) {

        super.init()

        // 1. 检查权限
        self.checkCameraAccess()
        self.checkMicrophoneAccess()

        // 2. 设置device信息
        if let videoCaptureDevice = videoCaptureDevice {
            self.videoCaptureDevice = videoCaptureDevice
        } else {
            // TODO: 还是使用系统的 AVCaptureDevice.systemPreferredCamera？
            // AVCaptureDevice.self.addObserver(self, forKeyPath: "systemPreferredCamera", options: [.new], context: &systemPreferredCameraContext)
            self.videoCaptureDevice = Capturer.getSupportVideoDevices().first
        }

        if let audioCaptureDevice = audioCaptureDevice {
            self.audioCaptureDevice = audioCaptureDevice
        } else {
            self.audioCaptureDevice = Capturer.getSupportAudioDevices().first
        }

        // TODO: 判断如果device赋值失败了，则应该初始化也失败了，是不是不需要直接走后边的步骤了？

        // 3. 配置session（这里先不指定session的preset,使用默认的inputPriority，以保证后续设置ActiveFormat的成功 https://developer.apple.com/documentation/avfoundation/avcapturesessionpresetinputpriority）

        self.sessionQueue.async {

//            if self.session.canSetSessionPreset(self.preset) {
//                self.session.sessionPreset = self.preset
//            }

            self.configureSession()
//            self.updateVideoFPS(self.fps)
            self.setupPreviewLayer()
        }

    }

    // MARK: - Access

    /// 检查相机权限
    private func checkCameraAccess() {

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: break
        case .denied: break //TODO: alert user
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

    private func checkMicrophoneAccess() {

        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: break
        case .denied: break //TODO: alert user
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

    // MARK: - Session

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

    // TODO: 使用try-catch
    private func addVideoInput() {

        do {

            guard let videoCaptureDevice = self.videoCaptureDevice else {
                print("Create video device failed")
                self.setupResult = .configurationFailed
                return
            }

            let videoDeviceInput = try AVCaptureDeviceInput(device: videoCaptureDevice)

            if self.session.canAddInput(videoDeviceInput) {
                self.session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                print("Couldn't add video device input to the session.")
                self.setupResult = .configurationFailed
                return
            }

            // TODO: createDeviceRotationCoordinator

        } catch {
            print("Couldn't create video device input: \(error)")
            self.setupResult = .configurationFailed
            return
        }

    }

    // TODO: 使用try-catch
    private func addAudioInput() {

        do {

            guard let audioCaptureDevice = self.audioCaptureDevice else {
                print("Create audio device failed")
                self.setupResult = .configurationFailed
                return
            }

            let audioDeviceInput = try AVCaptureDeviceInput(device: audioCaptureDevice)

            if self.session.canAddInput(audioDeviceInput) {
                self.session.addInput(audioDeviceInput)
                self.audioDeviceInput = audioDeviceInput
            } else {
                print("Could not add audio device input to the session")
                self.setupResult = .configurationFailed
                return
            }

        } catch {
            print("Could not create audio device input: \(error)")
            self.setupResult = .configurationFailed
            return
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

    private func addAudioOutput() {

        guard self.session.canAddOutput(self.audioOutput) else {
            print("Could not add audio data output to the session")
            self.setupResult = .configurationFailed
            return
        }

        self.session.addOutput(self.audioOutput)
        self.audioOutput.setSampleBufferDelegate(self, queue: self.audioOutputQueue)

    }

    // MARK: - Preview

    private func setupPreviewLayer() {

        guard self.setupResult == .success else { return }

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
    public func updateActiveFormat(format: AVCaptureDevice.Format, activeVideoMinFrameDuration: CMTime, activeVideoMaxFrameDuration: CMTime) {

        guard let videoCaptureDevice = self.videoCaptureDevice else { return }

        self.session.beginConfiguration()

        do {
            try videoCaptureDevice.lockForConfiguration()

            // Set the device's active format.
            videoCaptureDevice.activeFormat = format// a supported format.

            // Set the device's min/max frame duration.
//            videoCaptureDevice.activeVideoMinFrameDuration = activeVideoMinFrameDuration // a supported minimum duration.
//            videoCaptureDevice.activeVideoMaxFrameDuration = activeVideoMaxFrameDuration// a supported maximum duration.

            videoCaptureDevice.unlockForConfiguration()
        } catch {
            // Handle error.
        }


        // Apply the changes to the session.
        self.session.commitConfiguration()
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
    public func swicthingCamera() {

        if self.videoCaptureDevice?.position == .back {

            if let videoCaptureDevice = Capturer.getSupportVideoDevices(position: .front).first {
                self.updateVideoCaptureDevice(videoCaptureDevice: videoCaptureDevice)
            }

        } else if self.videoCaptureDevice?.position == .front {

            if let videoCaptureDevice = Capturer.getSupportVideoDevices(position: .back).first {
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
        self.addVideoInput()

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

            self.calaulatorResAndFps(sampleBuffer: sampleBuffer)

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
                print(String(format: "[Calculator] 瞬时帧率: %.2f FPS", frameRate))
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

// MARK: -


