//
//  CameraHandler.h
//  ForwardBackward
//
//  Created by Akram Hussein on 01/02/2014.
//  Copyright (c) 2014 Akram Hussein. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface CameraHandler : NSObject

@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *preview;
@property (weak, nonatomic) UIImage *forwardImage;
@property (weak, nonatomic) UIImage *backwardImage;
@property (nonatomic, readwrite, getter = isForwardCamera) BOOL forwardCamera;

+ (CameraHandler*) handler;

- (void) startupWithForwardCamera:(BOOL)on;
- (void) shutdown;
- (void) suspend;
- (void) restart;
- (void) switchCamera;
- (void) captureImage;
- (void) setFlashOn:(BOOL)on;
- (void) focusWithMode:(AVCaptureFocusMode)focusMode
        exposeWithMode:(AVCaptureExposureMode)exposureMode
         atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange;

@end
