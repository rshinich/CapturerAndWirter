//
//  VideoWriter.swift
//  CapturerAndWirter
//
//  Created by 张忠瑞 on 2024/9/16.
//

import Foundation
import AVFoundation
import Photos

class VideoWriter {

    private let writingQueue = DispatchQueue(label: "com.zzr.camera.writting")


    // MARK: -

    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var videoPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?

    private var outputURL: URL?

    private(set) var isRecording = false

    // MARK: -

    private init() {

    }

    static func create(outputURL: URL, videoSize: CGSize, completion: @escaping (Result<VideoWriter, Error>) -> Void) {

        let instance = VideoWriter()

        if FileManager.default.fileExists(atPath: outputURL.path) {
            completion(.failure(WriterError.fileExists))
            return
        }

        instance.outputURL = outputURL

        do {
            try instance.setupWriter(outputURL: outputURL, videoSize: videoSize)
            completion(.success(instance))
        } catch {
            completion(.failure(error))
        }
    }

    // MARK: -

    private func setupWriter(outputURL: URL, videoSize: CGSize) throws {

        self.assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        try self.addVideoInput(videoSize: videoSize)
        try self.addAudioInput()
        self.setupVideoPixelBufferAdaptor()

    }

    private func addVideoInput(videoSize: CGSize) throws {

        // 设置视频输入
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: videoSize.width,
            AVVideoHeightKey: videoSize.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 6000000,
                AVVideoExpectedSourceFrameRateKey: 30,
                AVVideoMaxKeyFrameIntervalKey: 60,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ],
            AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill
        ]

        self.videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        self.videoInput?.expectsMediaDataInRealTime = true

        if self.assetWriter!.canAdd(self.videoInput!) {
            self.assetWriter!.add(self.videoInput!)
        } else {
            throw WriterError.addVideoInputFailed
        }
    }

    private func addAudioInput() throws {

        // 设置音频输入
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey: 44100,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsNonInterleaved: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        self.audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        self.audioInput?.expectsMediaDataInRealTime = true

        if self.assetWriter!.canAdd(self.audioInput!) {
            self.assetWriter!.add(self.audioInput!)
        } else {
            throw WriterError.addAudioInputFailed
        }
    }

    private func setupVideoPixelBufferAdaptor() {

        // 设置 Pixel Buffer Adaptor
        self.videoPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput!, sourcePixelBufferAttributes: nil)
    }

    // MARK: -

    func saveVideoToPhotoLibrary(url: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }) { success, error in
                    if success {
                        print("视频已保存到相册")
                    } else {
                        print("保存失败: \(String(describing: error))")
                    }
                }
            } else {
                print("没有权限访问相册")
            }
        }
    }

    // MARK: -

    // 开始录制
    func startRecording(startSessionSourceTime: CMTime) {
        // 开始写入会话
        assetWriter?.startWriting()
        assetWriter?.startSession(atSourceTime: startSessionSourceTime)
        isRecording = true
    }

    // 添加视频帧
    func appendVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard isRecording, let videoInput = videoInput, videoInput.isReadyForMoreMediaData else {
            return
        }

        // 从 CMSampleBuffer 获取时间戳
        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        print("presentationTime = \(presentationTime)")

        // 从 CMSampleBuffer 获取 CVPixelBuffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get pixel buffer from sample buffer")
            return
        }

        // 将帧添加到 Pixel Buffer Adaptor
        videoPixelBufferAdaptor?.append(pixelBuffer, withPresentationTime: presentationTime)
    }

    // 添加音频样本
    func appendAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard isRecording, let audioInput = audioInput, audioInput.isReadyForMoreMediaData else {
            return
        }
        audioInput.append(sampleBuffer)
    }

    // 停止录制
    func stopRecording(completion: @escaping (Error?) -> Void) {
        guard isRecording else {
            completion(nil)
            return
        }

        isRecording = false
        videoInput?.markAsFinished()
        audioInput?.markAsFinished()

        assetWriter?.finishWriting {
            completion(nil)
            if let outputURL = self.outputURL {
                self.saveVideoToPhotoLibrary(url: outputURL)
            }
        }
    }
}
