//
//  CapturerTypes.swift
//  CapturerAndWirter
//
//  Created by 张忠瑞 on 2024/10/7.
//

import Foundation
import AVFoundation

enum CapturerError: Error {
    case videoDeviceAccessDenied
    case audioDeviceAccessDenied
    case videoCaptureDeviceNotExist
    case audioCaptureDeviceNotExist
    case addVideoInputFailed
    case addAudioInputFailed
    case addVideoOutputFailed
    case addAudioOutputFailed
}

struct CaptureDeviceInfo {

    var id: String // 使用AVCaptureDevice中的uniqueID，uniqueID能够在设备声明周期内保持不变，对于外部设备(USB摄像头)，可以保证在重连链接时保持一致。
    var name: String // 使用AVCaptureDevice中的localizedName
    var raw: AVCaptureDevice // 原始数据

}

struct CaptureDeviceFormatInfo {

    var raw: AVCaptureDevice.Format

    var description: String {

        return raw.description
    }

    var dimensions: CGSize {

        let desc = raw.formatDescription
        let dimensions = CMVideoFormatDescriptionGetDimensions(desc)
        return CGSize(width: CGFloat(dimensions.width), height: CGFloat(dimensions.height))
    }

    var maxFrameRate: CGFloat {

        var maxFrameRate: CGFloat = 0

        for range in raw.videoSupportedFrameRateRanges {
            maxFrameRate = range.maxFrameRate
        }

        return maxFrameRate
    }

    var isVideoHDRSupported: Bool {
        return raw.isVideoHDRSupported
    }

    var isVideoStabilizationModeSupported: Bool {
        return raw.isVideoStabilizationModeSupported(.cinematic)
    }

    var fov: Float {
        return raw.videoFieldOfView
    }


}
