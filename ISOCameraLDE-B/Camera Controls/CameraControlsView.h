
@import CoreMedia;
@import CoreText;
@import AVFoundation;
@import ObjectiveC;
#import "ScaleSliderOverlayView.h"


typedef enum : NSUInteger {
    ExposureDurationModeDefault,
    ExposureDurationModeLong,
} ExposureDurationMode;

typedef enum : NSUInteger {
    CameraPropertyInvalid,
    CameraPropertyRecord,
    CameraPropertyExposureDuration,
    CameraPropertyISO,
    CameraPropertyLensPosition,
    CameraPropertyTorchLevel,
    CameraPropertyVideoZoomFactor,
} CameraProperty;

typedef void (^SetCameraPropertyValueBlock)(CameraProperty property, float value);

// Camera properties function pointers and related structure

@protocol CameraControlsDelegate <NSObject>

@required

@property (nonatomic, getter=videoZoomFactor, setter=setVideoZoomFactor:) float videoZoomFactor;
@property (nonatomic, getter=ISO, setter=setISO:) float ISO;

@property (nonatomic) AVCaptureDevice * _Nonnull videoDevice;

- (void)configureCameraForHighestFrameRate:(AVCaptureDevice *_Nonnull)device;

- (void)targetExposureDuration:(CMTime)exposureDuration withCompletionHandler:(void (^_Nonnull)(CMTime currentExposureDuration))completionHandler;

- (void)autoExposureWithCompletionHandler:(void (^_Nonnull)(double ISO))completionHandler;

- (void)autoFocusWithCompletionHandler:(void (^_Nonnull)(double focus))completionHandler;

- (void)setTorchLevel:(float)torchLevel;

- (void)toggleRecordingWithCompletionHandler:(void (^_Nonnull)(BOOL isRunning, NSError * _Nonnull error))completionHandler;

- (void)toggleTorchWithCompletionHandler:(void (^_Nonnull)(BOOL isTorchActive))completionHandler;

- (void)scrollSliderControlToItemAtIndexPath:(NSIndexPath *_Nonnull)indexPath;

- (BOOL)lockDevice;
//- (void (^_Nonnull)(CameraProperty property, float value))setCameraPropertyToValue:(float(^_Nonnull)(CGRect scrollViewFrame, CGFloat contentOffsetX, float scaleMinimum, float scaleMaximum))scaleSliderValue;
- (SetCameraPropertyValueBlock)setCameraPropertyBlock;

- (float)valueForCameraProperty:(CameraProperty)cameraProperty;

@end

//struct CameraProperties;
//
//typedef void (*CameraPropertyFunctions)(struct CameraProperties *);
//typedef double (*CameraPropertyFunc)(id<CameraControlsDelegate>, CameraProperty);

//struct CameraProperties {
//    ExposureDurationMode exposureDurationMode;
//    double ISO;
//    double lensPosition;
//    double torchLevel;
//    double videoZoomFactor;
//};


//void initCameraProperties(id<CameraControlsDelegate> delegate, struct CameraProperties *cameraProperties)
//{
//    cameraProperties->exposureDurationMode = cameraPropertyFunc(delegate, CameraPropertyExposureDuration);
//    cameraProperties->ISO              = cameraPropertyFunc(delegate, CameraPropertyISO);
//    cameraProperties->lensPosition     = cameraPropertyFunc(delegate, CameraPropertyLensPosition);
//    cameraProperties->torchLevel       = cameraPropertyFunc(delegate, CameraPropertyTorchLevel);
//    cameraProperties->videoZoomFactor  = cameraPropertyFunc(delegate, CameraPropertyVideoZoomFactor);
//}

// -------------------------------------------


@interface CameraControlsView : UIView <CALayerDelegate, UIScrollViewDelegate, ScaleSliderOverlayViewDelegate, UIGestureRecognizerDelegate>

//+ (nonnull CameraControlsView *)cameraControls;

@property (nonatomic, assign, nullable) id<CameraControlsDelegate> delegate;

//@property (nonatomic, nullable) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, nullable) UITapGestureRecognizer *tapGestureRecognizer; // !!!!!!!! ------- RECONNECT

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray * cameraPropertyButtons;
@property (weak, nonatomic) IBOutlet UIView * _Nullable scaleSliderControlView;
@property (weak, nonatomic) IBOutlet UIScrollView * _Nullable scaleSliderScrollView;
@property (weak, nonatomic) IBOutlet UIStackView * _Nullable cameraControlButtonsStackView;
@property (weak, nonatomic) IBOutlet ScaleSliderOverlayView * _Nullable scaleSliderOverlayView;
@property (strong, nonatomic) CATextLayer * _Nullable textLayer;


@end
