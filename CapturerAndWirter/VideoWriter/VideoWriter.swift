//
//  VideoWriter.swift
//  CapturerAndWirter
//
//  Created by 张忠瑞 on 2024/9/16.
//

import Foundation
import AVFoundation

class VideoWriter {

    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var videoPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?

    private(set) var isRecording = false
    private var videoSize: CGSize

    init(videoSize: CGSize) {
        self.videoSize = videoSize
    }

    // 开始录制
    func startRecording(outputURL: URL, startSessionSourceTime: CMTime, completion: @escaping (Error?) -> Void) {
        do {
            // 初始化 AVAssetWriter
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)

            // 设置视频输入
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: videoSize.width,
                AVVideoHeightKey: videoSize.height
            ]
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            videoInput?.expectsMediaDataInRealTime = true

            if let videoInput = videoInput, assetWriter?.canAdd(videoInput) == true {
                assetWriter?.add(videoInput)
            }

            // 设置 Pixel Buffer Adaptor
            videoPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput!, sourcePixelBufferAttributes: nil)

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
            audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audioInput?.expectsMediaDataInRealTime = true

            if let audioInput = audioInput, assetWriter?.canAdd(audioInput) == true {
                assetWriter?.add(audioInput)
            }

            // 开始写入会话
            assetWriter?.startWriting()
            assetWriter?.startSession(atSourceTime: startSessionSourceTime)
            isRecording = true

            completion(nil)
        } catch {
            completion(error)
        }
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
        }
    }
}
