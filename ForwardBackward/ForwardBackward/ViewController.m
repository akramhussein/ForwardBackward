//
//  ViewController.m
//  ForwardBackward
//
//  Created by Akram Hussein on 27/01/2014.
//  Copyright (c) 2014 Akram Hussein. All rights reserved.
//

#import "ViewController.h"

#import "CameraHandler.h"
#import "AssetManagement.h"
#import "UIImage+Resize.h"

static void * CapturingStillImageContext = &CapturingStillImageContext;

@interface ViewController () <UIActionSheetDelegate>

// Interface outlets
@property (weak, atomic) IBOutlet UIView *topCameraView;
@property (weak, atomic) IBOutlet UIView *bottomCameraView;

@property (weak, nonatomic) IBOutlet UIButton *captureButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *flashButton;
@property (weak, nonatomic) IBOutlet UIButton *forwardButton;

// Interface actions
- (IBAction)captureButtonPressed:(id)sender;
- (IBAction)cancelButtonPressed:(id)sender;
- (IBAction)flashButtonPressed:(id)sender;
- (IBAction)forwardButtonPressed:(id)sender;
- (IBAction)focusAndExposeTap:(UITapGestureRecognizer *)gestureRecognizer;

// Utilities
@property (nonatomic, getter = isForwardCaptured) BOOL forwardCaptured;
@property (nonatomic, getter = isFlashEnabled) BOOL flashEnabled;

// Asset Management
@property (strong, nonatomic) AssetManagement *assetManagementLibrary;

@end

@implementation ViewController

#define FORWARD_CAMERA_START 1 // start with the forward camera?

#pragma mark ViewController Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.assetManagementLibrary = [[AssetManagement alloc] init];
    
    [[CameraHandler handler] startupWithForwardCamera:FORWARD_CAMERA_START];
    [[CameraHandler handler] addObserver:self
                              forKeyPath:@"imageOutput.capturingStillImage"
                                 options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
                                    context:CapturingStillImageContext];
    [self startPreview];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    // ensure 50/50 split of views - AutoLayout isn't playing nice
    [[self topCameraView] setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height / 2)];
    [[self bottomCameraView]  setFrame:CGRectMake(0, self.view.frame.size.height / 2, self.view.frame.size.width, self.view.frame.size.height / 2)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload
{
    [[CameraHandler handler] removeObserver:self
                                 forKeyPath:@"imageOutput.capturingStillImage"
                                    context:CapturingStillImageContext];
}

#pragma mark Camera Handling

- (void)startPreview
{
    AVCaptureVideoPreviewLayer* preview = [[CameraHandler handler] preview];
    [preview removeFromSuperlayer];
    UIView *currentView = [self currentActiveCameraView];
    preview.frame = currentView.bounds;
    [[preview connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
    [currentView.layer addSublayer:preview];
}

- (void)reset
{
    // update UI
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self topCameraView] setBackgroundColor:[UIColor whiteColor]];
        [[self bottomCameraView] setBackgroundColor:[UIColor blackColor]];
        [[self cancelButton] setHidden:YES];
        [[self flashButton] setEnabled:YES];
        [[self forwardButton] setHidden:YES];
        [[self captureButton] setHidden:NO];
        [[self captureButton] setEnabled:YES];
    });
    
    [[CameraHandler handler] switchCamera];
    [[CameraHandler handler] restart];
    [self setForwardCaptured:NO];
    [self startPreview];
    [[self assetManagementLibrary] reset];
}

#pragma mark UI Actions

- (IBAction)captureButtonPressed:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self captureButton] setEnabled:NO];
        [[self flashButton] setEnabled:NO];
    });
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(imageCapturedReady:)
                                                 name:@"imageCaptured"
                                               object:nil];

    [[CameraHandler handler] captureImage];
    if ([self isForwardCaptured])
    {
        // Finished taking photos, move to next set of buttons
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self captureButton] setHidden:YES];
            [[self forwardButton] setEnabled:NO];
            [[self forwardButton]  setHidden:NO];
        });
    }
    [[self cancelButton] setEnabled:NO]; // disabled until ready
}

- (void) imageCapturedReady:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:@"imageCaptured"])
    {
        if (![self isForwardCaptured])
        {
            UIImage *forwardImage = [[CameraHandler handler] forwardImage];
            UIImage *croppedImage = [forwardImage cropAndResizeAspectFillWithSize:self.topCameraView.bounds.size
                                                              interpolationQuality:kCGInterpolationHigh];
            [[self assetManagementLibrary] setForwardImage:croppedImage];
            [[CameraHandler handler] setForwardImage:nil]; // clear the memory - probably not best way
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // update view
                [[self topCameraView] setBackgroundColor:[UIColor colorWithPatternImage:croppedImage]];
                [[self captureButton] setEnabled:YES];
                [[self cancelButton] setHidden:NO];
                [[self cancelButton] setEnabled:YES];
            });
            [[CameraHandler handler] switchCamera];
            [[CameraHandler handler] restart];
            [self setForwardCaptured: YES];
            [self startPreview];
        }
        else
        {
            UIImage *backwardImage = [[CameraHandler handler] backwardImage];
            // crop image
            UIImage *croppedImage = [backwardImage cropAndResizeAspectFillWithSize:self.bottomCameraView.bounds.size
                                                                                        interpolationQuality:kCGInterpolationHigh];
            [[self assetManagementLibrary] setBackwardImage:croppedImage];
            
            [[CameraHandler handler] suspend];
            [[CameraHandler handler] setBackwardImage:nil]; // clear the memory - probably not best way
        
            dispatch_async(dispatch_get_main_queue(), ^{
                // no need to update bottom view as we can use last frame of preview
                [[self cancelButton] setEnabled:YES];
                [[self forwardButton] setEnabled:YES];
            });
        }
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"imageCaptured"
                                                  object:nil];
}

- (IBAction)cancelButtonPressed:(id)sender
{
    
    UIActionSheet *cancelOptions = [[UIActionSheet alloc] initWithTitle:nil
                                                               delegate:self
                                                      cancelButtonTitle:@"Cancel"
                                                 destructiveButtonTitle:@"Delete Photo"
                                                      otherButtonTitles:@"Save Photo", nil];
    [cancelOptions showInView:[self view]];
}

- (IBAction)flashButtonPressed:(id)sender
{
    if ([sender isSelected])
    {
        [sender setSelected:NO];
        [[CameraHandler handler] setFlashOn:NO];
    }
    else
    {
        [sender setSelected:YES];
        [[CameraHandler handler] setFlashOn:YES];
    }
}

- (IBAction)forwardButtonPressed:(id)sender
{
    // create stitched image once
    if ([[self assetManagementLibrary] getStitchedImage] == nil)
    {
        [[self assetManagementLibrary] createStitchedImage];
    }

    NSString *message = @"Checkout my ForwardBackward snap!";
    NSArray *items = @[message, [[self assetManagementLibrary] getStitchedImage]];
    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:items
                                                                             applicationActivities:nil];
    
    [self presentViewController:controller animated:YES completion:^{
        // re-enable once UIActivityViewController has loaded
        [[self cancelButton] setEnabled:YES];
        [[self forwardButton] setEnabled:YES];
    }];
}

- (IBAction)focusAndExposeTap:(UITapGestureRecognizer *)gestureRecognizer
{
    CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)[[CameraHandler handler] preview] captureDevicePointOfInterestForPoint:[gestureRecognizer locationInView:[gestureRecognizer view]]];
	[[CameraHandler handler] focusWithMode:AVCaptureFocusModeAutoFocus
                            exposeWithMode:AVCaptureExposureModeAutoExpose
                             atDevicePoint:devicePoint
                  monitorSubjectAreaChange:YES];
}

// Handle the cancel button UIActionSheet callback
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        [self reset];
    }
    else if (buttonIndex == 1)
    {
        [[self assetManagementLibrary] saveStitchedImage];
        [self reset];
    }
}

- (void)runImageCaptureAnimation
{
	dispatch_async(dispatch_get_main_queue(), ^{
        [[[self currentActiveCameraView] layer] setOpacity:0.0];
		[UIView animateWithDuration:1.5 animations:^{
			[[[self currentActiveCameraView] layer] setOpacity:1.0];
		}];
	});
}

#pragma mark Utilities

- (UIView *)currentActiveCameraView
{
    return [[CameraHandler handler] isForwardCamera] ? [self topCameraView] : [self bottomCameraView];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
	if (context == CapturingStillImageContext)
	{
		BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
		if (isCapturingStillImage)
		{
			[self runImageCaptureAnimation];
		}
	}
    else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end
