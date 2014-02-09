//
//  CameraHandler.m
//  ForwardBackward
//
//  Created by Akram Hussein on 01/02/2014.
//  Copyright (c) 2014 Akram Hussein. All rights reserved.
//

#import "CameraHandler.h"

static CameraHandler* theHandler;

// why does this type of interface cause issues?
@interface CameraHandler ()

@property (strong, nonatomic) AVCaptureDeviceInput *input;
@property (strong, nonatomic) AVCaptureStillImageOutput *imageOutput;

@end

@implementation CameraHandler

@synthesize forwardImage;
@synthesize backwardImage;
@synthesize forwardCamera;

+ (CameraHandler*) handler
{
    return theHandler;
}

#pragma mark Session Management

+ (void) initialize
{
    if (self == [CameraHandler class])
    {
        theHandler = [[CameraHandler alloc] init];
    }
}

- (void) setupCamera
{
    NSError *error = nil;
    
    AVCaptureDevicePosition position = [self isForwardCamera] ? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront;
    AVCaptureDevice *device = [CameraHandler deviceWithMediaType:AVMediaTypeVideo preferringPosition:position];
    [self setInput:[AVCaptureDeviceInput deviceInputWithDevice:device error:&error]];
    if (error)
    {
        NSLog(@"%@", error);
    }
     [[self session] beginConfiguration];
    if ([[self session] canAddInput:[self input]])
    {
        [[self session] addInput:[self input]];
    }
    
    if ([[self session] canSetSessionPreset:AVCaptureSessionPresetPhoto])
    {
        [[self session] setSessionPreset:AVCaptureSessionPresetPhoto];
    }
    
    AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    if ([[self session] canAddOutput:stillImageOutput])
    {
        [stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
        [[self session] addOutput:stillImageOutput];
        [self setImageOutput:stillImageOutput];
    }
    
    if ([[[self preview] connection] isVideoOrientationSupported])
    {
        AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationPortrait;
        [[[self preview] connection] setVideoOrientation:orientation];
    }
    [[self session] commitConfiguration];
    [self setPreview:[AVCaptureVideoPreviewLayer layerWithSession:[self session]]];
    [[self preview] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
}

- (void) startupWithForwardCamera:(BOOL) on
{
    [self setForwardCamera:on];
    
    if ([self session] == nil)
    {
        [self setSession:[[AVCaptureSession alloc] init]];
        [self setupCamera];
        [[self session] startRunning];
    }
}

- (void) shutdown
{
    if ([self session])
    {
        [[self session] stopRunning];
        [self setSession: nil];
    }
}

- (void) suspend
{
    if ([self session])
    {
        [[self session] stopRunning];
    }
}

- (void) restart
{
    if ([self session])
    {
        [[self session] startRunning];
    }
}

- (void) switchCamera
{
    [self setForwardCamera: ![self isForwardCamera]];
    //[[self session] beginConfiguration];
    [[self session] removeInput:[self input]];
    [self setupCamera];
    //[[self session] commitConfiguration];
}

- (void) captureImage
{
    [[self imageOutput] captureStillImageAsynchronouslyFromConnection:[[self imageOutput] connectionWithMediaType:AVMediaTypeVideo]
                                                  completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                                      if (imageDataSampleBuffer)
                                                      {
                                                          [self suspend];
                                                          NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                                          UIImage *image = [[UIImage alloc] initWithData:imageData];
                                                          
                                                          [self isForwardCamera] ? [self setForwardImage:image] : [self setBackwardImage:image];

                                                          [[NSNotificationCenter defaultCenter] postNotificationName:@"imageCaptured"
                                                                                                              object:self];
                                                      }
                                                  }];
}

#pragma mark Camera Management

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    AVCaptureDevice *device = [[self input] device];
    NSError *error = nil;
    if ([device lockForConfiguration:&error])
    {
        if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode])
        {
            [device setFocusMode:focusMode];
            [device setFocusPointOfInterest:point];
        }
        if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode])
        {
            [device setExposureMode:exposureMode];
            [device setExposurePointOfInterest:point];
        }
        [device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
        [device unlockForConfiguration];
    }
    else
    {
        NSLog(@"%@", error);
    }
}

- (void)setFlashOn:(BOOL)on
{
    if(on)
    {
        [self setFlashMode:AVCaptureFlashModeOn
                 forDevice:[[self input] device]];
    }
    else
    {
        [self setFlashMode:AVCaptureFlashModeOff
                 forDevice:[[self input] device]];
    }
}

- (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
	if ([device hasFlash] && [device isFlashModeSupported:flashMode])
	{
		NSError *error = nil;
		if ([device lockForConfiguration:&error])
		{
			[device setFlashMode:flashMode];
			[device unlockForConfiguration];
		}
		else
		{
			NSLog(@"%@", error);
		}
	}
}

#pragma mark Device Utilities

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = [devices firstObject];
    
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position)
        {
            captureDevice = device;
            break;
        }
    }
    return captureDevice;
}

@end
