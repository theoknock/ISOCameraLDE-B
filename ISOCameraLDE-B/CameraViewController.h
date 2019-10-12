//
//  CameraViewController.h
//  ISOCameraLDE
//
//  Created by Xcode Developer on 6/17/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>
#import "CameraControlsView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CameraViewController : UIViewController <CameraControlsDelegate>

@property (strong, nonatomic) __block AVCaptureDevice *videoDevice;

- (void)autoExposureWithCompletionHandler:(void (^)(double ISO))completionHandler;

- (void)autoFocusWithCompletionHandler:(void (^)(double focus))completionHandler;

- (void)toggleRecordingWithCompletionHandler:(void (^)(BOOL isRunning, NSError *error))completionHandler;
- (void)targetExposureDuration:(CMTime)exposureDuration withCompletionHandler:(void (^)(CMTime currentExposureDuration))completionHandler;
- (void)toggleTorchWithCompletionHandler:(void (^)(BOOL isTorchActive))completionHandler;

- (void)setTorchLevel:(float)torchLevel;

- (void)scrollSliderControlToItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)lockDevice;
- (SetCameraPropertyValueBlock)setCameraPropertyBlock;
- (float)valueForCameraProperty:(CameraProperty)cameraProperty;

@property (nonatomic, getter=videoZoomFactor, setter=setVideoZoomFactor:) float videoZoomFactor;

@end

NS_ASSUME_NONNULL_END
