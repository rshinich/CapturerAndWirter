//
//  CapturerHelpers.swift
//  CapturerAndWirter
//
//  Created by 张忠瑞 on 2024/10/7.
//

import Foundation
import AVFoundation

class CapturerHelpers {

    // MARK: -

    public class func getSupportDefinition() {

        // 标清 Standard Definition: 640x480p
        // 高清 High Definition: 1280x720p
        // 全高清 Full High Definition: 1920x1080p
        // 超高清 Ultra High Definition: 3840x2160(4k)，7268x4320(8k)

    }

    public class func getSupportAudioDevices() -> [CaptureDeviceInfo] {

        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInMicrophone  // 麦克风
        ]

        let discoverySessions = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: .audio, position: .unspecified)

        var captureDeviceInfos: [CaptureDeviceInfo] = []

        for device in discoverySessions.devices {
            let captureDeviceInfo = CaptureDeviceInfo(id: device.uniqueID,
                                                      name: device.localizedName,
                                                      raw: device)
            captureDeviceInfos.append(captureDeviceInfo)
        }

        return captureDeviceInfos
    }

    public class func getSupportVideoDevices(position: AVCaptureDevice.Position = .unspecified) -> [CaptureDeviceInfo] {

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

        var captureDeviceInfos: [CaptureDeviceInfo] = []

        for device in discoverySessions.devices {
            let captureDeviceInfo = CaptureDeviceInfo(id: device.uniqueID,
                                                      name: device.localizedName,
                                                      raw: device)
            captureDeviceInfos.append(captureDeviceInfo)
        }

        return captureDeviceInfos
    }

    public class func getSupportFormats(captureDevice: AVCaptureDevice) -> [CaptureDeviceFormatInfo] {

        var captureDeviceFormatInfos: [CaptureDeviceFormatInfo] = []

        for format in captureDevice.formats {

            let captureDeviceFormatInfo = CaptureDeviceFormatInfo.init(raw: format)
            captureDeviceFormatInfos.append(captureDeviceFormatInfo)
        }

//        let minZoomFactor = captureDevice.minAvailableVideoZoomFactor
//        let maxZoomFactor = captureDevice.maxAvailableVideoZoomFactor
//        print("Minimum Zoom Factor: \(minZoomFactor)")
//        print("Maximum Zoom Factor: \(maxZoomFactor)")

        return captureDeviceFormatInfos
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

    // MARK: - Grouped format

    struct FormatKey: Hashable {

        let width: CGFloat
        let height: CGFloat
        let maxFrameRate: CGFloat
    }

    struct GroupedFormat {

        let formatKey: FormatKey
        var formats: [CaptureDeviceFormatInfo]
    }

    class func groupFormats(_ formats: [CaptureDeviceFormatInfo]) -> [GroupedFormat] {

        var groupedDict: [FormatKey: GroupedFormat] = [:]

        for format in formats {

            let key = FormatKey(width: format.dimensions.width,
                                height: format.dimensions.height,
                                maxFrameRate: format.maxFrameRate)

            if var existingGroup = groupedDict[key] {

                existingGroup.formats.append(format)
                groupedDict[key] = existingGroup

            } else {

                let newGroup = GroupedFormat(formatKey: key, formats: [format])
                groupedDict[key] = newGroup

            }
        }

        return Array(groupedDict.values)
    }
}
