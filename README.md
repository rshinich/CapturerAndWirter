## Introduction

Hope to have video shooting and storage components that can be used out of the box.

- Capturer: A class responsible for calling the iOS camera through AVFoundation；
- Writer: A class that generates videos through AVAssertWriter and saves them locally；

It supports the modification of the following camera parameters:

- [ ] resolution;
- [ ] FPS;
- [ ] capture device(front or back with dual or triple);
- [ ] orentation;
- [ ] zoom factor;
- [ ] focus;
- [ ] whiteBalance;
- [ ] exposure;

```
if captureDevice.isExposureModeSupported(.continuousAutoExposure) {
    try captureDevice.lockForConfiguration()
    captureDevice.exposureMode = .continuousAutoExposure
    captureDevice.unlockForConfiguration()
}
```

```
if captureDevice.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
    try captureDevice.lockForConfiguration()
    captureDevice.whiteBalanceMode = .continuousAutoWhiteBalance
    captureDevice.unlockForConfiguration()
}
```

···
if captureDevice.isFocusModeSupported(.continuousAutoFocus) {
    try captureDevice.lockForConfiguration()
    captureDevice.focusMode = .continuousAutoFocus
    captureDevice.unlockForConfiguration()
}
```
