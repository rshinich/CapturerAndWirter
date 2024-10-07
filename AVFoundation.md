## Introduction

### 捕获视频

捕获视频通常使用来自相机或麦克风的设备，需要组装几个对象来表示输入和输出，并使用AVCaptureSession实例来协调他们之间的数据流。要实现他们，至少需要：

- [AVCaptureSession](https://developer.apple.com/documentation/avfoundation/avcapturesession) 实例，用来协商输入和输出的数据流；
- [AVCaptureDevice](https://developer.apple.com/documentation/avfoundation/avcapturedevice) 实例，例如相机或者麦克风；
- [AVCaptureInput](https://developer.apple.com/documentation/avfoundation/avcaptureinput) 实例，用来处理输入端口；
- [AVCaptureOutput](https://developer.apple.com/documentation/avfoundation/avcaptureoutput) 实例，用来处理输出的内容；

### AVCaptureSession

AVCaptureSession是整个录制功能的核心，用来协调输入的数据流和输出的数据的协调。

#### 开始或结束

可以通过sessionPreset来设置Session的数据质量。可以通过`startSession`和`stopSession`来开始或结束一个sessio。

#### 配置/更新Session

尽量通过beginConfiguration和commitConfiguration方法来调整预设的一些参数，这两个方法能尽可能的保证数据的一致性。
在调用了beginConfiguration后，可以添加或删除输出，更改sessionPreset的属性，或者单独配置输入或输出的属性；
直到调用了commitConfiguration后，所有的改动才会被一起提交并应用。

#### 监听session状态

可以通过以下方法监听session运行的状态：

- AVCaptureSessionDidStartRunningNotification session开始运行；
- AVCaptureSessionDidStopRunningNotification session停止运行；
- AVCaptureSessionWasInterruptedNotification session被打断，通过AVCaptureSessionInterruptionReasonKey可以看到被打断的原因；
- AVCaptureSessionRuntimeErrorNotification session出错，通过AVCaptureSessionErrorKey可以看到出错的原因；
- AVCaptureSessionInterruptionEndedNotification session打断结束，重新开始运行；

### AVCaptureDevice

AVCaptureDevice用来作为和硬件设备链接的管理类。


## Refrence

https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/00_Introduction.html#//apple_ref/doc/uid/TP40010188-CH1-SW3

https://developer.apple.com/documentation/avfoundation/capture_setup/avcam_building_a_camera_app

https://juejin.cn/post/6844904121619726343
