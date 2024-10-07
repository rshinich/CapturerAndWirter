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


    // MARK: -

    private let writingQueue = DispatchQueue(label: "com.zzr.camera.writting")

    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var videoPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?

    private var outputURL: URL?

    private(set) var isRecording = false

    // MARK: -

    private init() {

    }

    static func create(outputURL: URL, videoSize: CGSize, frameRate: Int32, completion: @escaping (Result<VideoWriter, Error>) -> Void) {

        let instance = VideoWriter()

        if FileManager.default.fileExists(atPath: outputURL.path) {
            completion(.failure(WriterError.fileExists))
            return
        }

        instance.outputURL = outputURL

        do {
            try instance.setupWriter(outputURL: outputURL, videoSize: videoSize, frameRate: frameRate)
            completion(.success(instance))
        } catch {
            completion(.failure(error))
        }
    }

    // MARK: -

    private func setupWriter(outputURL: URL, videoSize: CGSize, frameRate: Int32) throws {

        self.assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        try self.addVideoInput(videoSize: videoSize, frameRate: frameRate)
        try self.addAudioInput()
        self.setupVideoPixelBufferAdaptor()

    }

    private func addVideoInput(videoSize: CGSize, frameRate: Int32) throws {

        // 设置视频输入
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: videoSize.width,
            AVVideoHeightKey: videoSize.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 6000000,
                AVVideoExpectedSourceFrameRateKey: frameRate,
                AVVideoMaxKeyFrameIntervalKey: frameRate,
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
//            AVEncoderBitRateKey: 128000,
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
        writingQueue.async {
            self.assetWriter?.startWriting()
            self.assetWriter?.startSession(atSourceTime: startSessionSourceTime)
            self.isRecording = true
        }
    }

    // 添加视频帧
    func appendVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) {

        writingQueue.async {

            guard self.isRecording, let videoInput = self.videoInput, videoInput.isReadyForMoreMediaData else {
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
            self.videoPixelBufferAdaptor?.append(pixelBuffer, withPresentationTime: presentationTime)

        }
    }

    // 添加音频样本
    func appendAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        writingQueue.async {
            guard self.isRecording, let audioInput = self.audioInput, audioInput.isReadyForMoreMediaData else {
                return
            }
            audioInput.append(sampleBuffer)
        }
    }

    // 停止录制
    func stopRecording(completion: @escaping (Error?) -> Void) {


        writingQueue.async {
            guard self.isRecording else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            self.isRecording = false
            self.videoInput?.markAsFinished()
            self.audioInput?.markAsFinished()

            self.assetWriter?.finishWriting {
                if let error = self.assetWriter?.error {
                    DispatchQueue.main.async {
                        completion(error)
                    }
                    return
                }

                completion(nil)

                if let outputURL = self.outputURL {
                    self.saveVideoToPhotoLibrary(url: outputURL)
                }
            }
        }
    }
}
