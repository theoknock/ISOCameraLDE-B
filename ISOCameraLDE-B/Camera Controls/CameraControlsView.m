//
//  CameraControlsView.m
//  ISOCameraLDE
//
//  Created by Xcode Developer on 9/5/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "CameraControlsView.h"
#import "KeyValueObserver.h"
#import "ScaleSliderLayer.h"


static NSString * const LensPositionContext     = @"4";
static NSString * const ISOContext              = @"3";
static NSString * const TorchContext            = @"5";
static NSString * const VideoZoomFactorContext  = @"6";
static NSString * const ExposureDurationContext = @"2";

@interface CameraControlsView ()
{
//    struct CameraProperties cameraProperties;
    ScaleSliderLayer *scaleSliderLayer;
    __block SetCameraPropertyValueBlock setCameraPropertyValueBlock;
    dispatch_source_t timer[6];
}

@end

@implementation CameraControlsView

@synthesize delegate = _delegate;

- (void)setDelegate:(id<CameraControlsDelegate>)delegate
{
     _delegate = delegate;
    setCameraPropertyValueBlock = [delegate setCameraPropertyBlock];
//    setCameraPropertyValueBlock = [_delegate setCameraProperty:[self selectedCameraProperty]];
//    [self addObserver:self forKeyPath:@"delegate.session.running" options:NSKeyValueObservingOptionNew context:SessionRunningContext];
    [self addObserver:self forKeyPath:@"delegate.videoDevice.lensPosition" options:NSKeyValueObservingOptionNew context:CFBridgingRetain(LensPositionContext)];
    [self addObserver:self forKeyPath:@"delegate.ISO" options:NSKeyValueObservingOptionNew context:CFBridgingRetain(ISOContext)];
    [self addObserver:self forKeyPath:@"delegate.videoDevice.torchLevel" options:NSKeyValueObservingOptionNew context:CFBridgingRetain(TorchContext)];
    [self addObserver:self forKeyPath:@"delegate.videoZoomFactor" options:NSKeyValueObservingOptionNew context:CFBridgingRetain(VideoZoomFactorContext)];
    [self addObserver:self forKeyPath:@"delegate.videoDevice.exposureDuration" options:NSKeyValueObservingOptionNew context:(__bridge void * _Nullable)(ExposureDurationContext)];
}

- (id<CameraControlsDelegate>)delegate
{
    return _delegate;
}

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
//{
//    
//    NSNumber * value = change[NSKeyValueChangeNewKey];
//    if (value && value != [NSNull null]) {
//        float valueForTitle = ((NSNumber *)value).floatValue;
//            CameraProperty property = (CameraProperty)( context == LensPositionContext ) ? CameraPropertyLensPosition :
//                               ( context == ISOContext ) ? CameraPropertyISO :
//                               ( context == TorchContext ) ? CameraPropertyTorchLevel :
//                               ( context == VideoZoomFactorContext ) ? CameraPropertyVideoZoomFactor :
//            ( context == ExposureDurationContext ) ? CameraPropertyExposureDuration : CameraPropertyInvalid;
//            NSString *buttonTitle = [NSString stringWithFormat:@"%.1f", valueForTitle];
//            UIButton *button = (UIButton *)[self viewWithTag:property];
//        dispatch_async(dispatch_get_main_queue(), ^ {
//            [button setTitle:buttonTitle forState:UIControlStateNormal];
//        });
//    }
//    
//    
//    //    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
//}

- (NSNumberFormatter *)cameraPropertyNumberFormatter
{
    NSNumberFormatter * formatter = [[ NSNumberFormatter alloc ] init ] ;
    [ formatter setFormatWidth:1 ] ;
    [ formatter setPaddingCharacter:@" " ] ;
    [ formatter setFormatterBehavior:NSNumberFormatterBehavior10_4 ] ;
    [ formatter setNumberStyle:NSNumberFormatterNoStyle ] ;
    
    return formatter;
}

float normalize(float unscaledNum, float minAllowed, float maxAllowed, float min, float max) {
    return (maxAllowed - minAllowed) * (unscaledNum - min) / (max - min) + minAllowed;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    __block UIButton *button;
    CameraProperty cameraProperty = (CameraProperty)[[self cameraPropertyNumberFormatter] numberFromString:(__bridge NSString * _Nonnull)(context)];
    dispatch_async( dispatch_get_main_queue(), ^{
        button = (UIButton *)[self viewWithTag:cameraProperty];
    });
//    if (cameraProperty == CameraPropertyLensPosition || cameraProperty == CameraPropertyTorchLevel || cameraProperty == CameraPropertyVideoZoomFactor) {
        id newValue = change[NSKeyValueChangeNewKey];
            if ( newValue && newValue != [NSNull null] ) {
                float newFloatValue;
                if ([(NSObject *)newValue isKindOfClass:[NSNumber class]])
                {
                    CMTime newExposureDuration = [newValue CMTimeValue];
                    newFloatValue = newExposureDuration.timescale;
                } else {
                    if (cameraProperty == CameraPropertyISO)
                    {
                        newFloatValue = [newValue floatValue];
                        float maxISO = self.delegate.videoDevice.activeFormat.maxISO;
                        float minISO = self.delegate.videoDevice.activeFormat.minISO;
                        newFloatValue = minISO + (newFloatValue * (maxISO - minISO));
                        newFloatValue = normalize(newFloatValue, 0.0, 1.0, minISO, maxISO);
                    } else {
                        newFloatValue = ([(NSObject *)newValue isKindOfClass:[NSNumber class]]) ? [newValue floatValue] : ([newValue CMTimeValue].timescale);
                    }
                }
                dispatch_async( dispatch_get_main_queue(), ^{
                    [button setTitle:[NSString stringWithFormat:@"%.1f", newFloatValue] forState:UIControlStateNormal];
                    [button setTintColor:[UIColor systemBlueColor]];
                } );
        }
    
    dispatch_async( dispatch_get_main_queue(), ^{
        [button setTintColor:[UIColor systemBlueColor]];
    } );

    if (!(cameraProperty > 0) && !(cameraProperty < 7))
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        NSLog(@"Something else observed.");
    }

    NSLog(@"Context: %lu", cameraProperty);
    [self displayValuesForCameraControlProperties];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.textLayer = [CATextLayer layer];
    [self.layer addSublayer:self.textLayer];
    [(ScaleSliderOverlayView *)self.scaleSliderOverlayView setDelegate:(id<ScaleSliderOverlayViewDelegate> _Nullable)self];
    
    //    [self.scaleSliderControlView addObserver:self forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew context:nil];
    
    CGFloat frameMinX  = -(CGRectGetMidX(self.scaleSliderScrollView.frame));
    CGFloat frameMaxX  =  CGRectGetMaxX(self.scaleSliderScrollView.frame) + fabs(CGRectGetMidX(self.scaleSliderScrollView.frame));
    CGFloat insetMin = fabs(CGRectGetMidX(self.scaleSliderScrollView.frame) - CGRectGetMinX(self.scaleSliderScrollView.frame));
    CGFloat insetMax = (CGRectGetMaxX(self.scaleSliderScrollView.frame) - CGRectGetMidX(self.scaleSliderScrollView.frame)) * 0.5;
    [self.scaleSliderScrollView setContentInset:UIEdgeInsetsMake(CGRectGetMinY(self.scaleSliderScrollView.frame), insetMin, CGRectGetMaxY(self.scaleSliderScrollView.frame), insetMin)];
    [self.scaleSliderScrollView setFrame:self.frame];
    
    //    [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    //    [self setOpaque:FALSE];
    //    [self setBackgroundColor:[UIColor clearColor]];
    //
//    [self setupGestureRecognizers];
    
    //    scrollLayer = [CAScrollLayer new];
    //    [scrollLayer setFrame:[self viewWithTag:6].bounds];
    ////    [scrollLayer setPosition:CGPointMake(self.bounds.size.width/2, self .bounds.size.height/2)]; // 10
    //    [scrollLayer setScrollMode:kCAScrollHorizontally];
    //
    //
    //
    //    scaleSliderLayer = [ScaleSliderLayer new];
    //    CGRect frame = CGRectMake(scrollLayer.frame.origin.x, scrollLayer.frame.origin.y, scrollLayer.frame.size.width * 2.0, scrollLayer.frame.size.height);
    //    [scaleSliderLayer setFrame:frame];
    //    [scrollLayer addSublayer:scaleSliderLayer];
    //     [[[self viewWithTag:6] layer] addSublayer:scrollLayer];
    ////
    //    [self.layer setPosition:scaleSliderLayer.frame.origin];
    //
    //    [scrollLayer setNeedsDisplay];
    //    [scaleSliderLayer setNeedsDisplay];
    //    [self.layer setNeedsDisplay];
    
    [self displayValuesForCameraControlProperties];
}

- (void)setupGestureRecognizers
{
    //    [self setUserInteractionEnabled:TRUE];
    //    [self setMultipleTouchEnabled:TRUE];
    //    [self setExclusiveTouch:TRUE];
    //
    ////    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    ////    [self.panGestureRecognizer setMaximumNumberOfTouches:1];
    ////    [self.panGestureRecognizer setMinimumNumberOfTouches:1];
    ////    self.panGestureRecognizer.delegate = self;
    ////    [self addGestureRecognizer:self.panGestureRecognizer];
    //
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self.tapGestureRecognizer setNumberOfTapsRequired:1];
    [self.tapGestureRecognizer setNumberOfTouchesRequired:1];
    self.tapGestureRecognizer.delegate = self;
    [self addGestureRecognizer:self.tapGestureRecognizer];

    self.gestureRecognizers = @[self.tapGestureRecognizer];
}

//NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
//f.numberStyle = NSNumberFormatterDecimalStyle;
//NSNumber *myNumber = [f numberFromString:@"42"];


- (NSNumberFormatter *)numberFormatter
{
    NSNumberFormatter * formatter = [[ NSNumberFormatter alloc ] init ] ;
    [ formatter setFormatWidth:1 ] ;
    [ formatter setPaddingCharacter:@" " ] ;
    [ formatter setFormatterBehavior:NSNumberFormatterBehavior10_4 ] ;
    [ formatter setNumberStyle:NSNumberFormatterDecimalStyle ] ;
    [ formatter setMinimumFractionDigits:2 ] ;
    [ formatter setMaximumFractionDigits:2 ] ;
    
    return formatter;
}

//- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
//{
//    dispatch_async(dispatch_get_main_queue(), ^{
//    if ([object isEqual:self.scaleSliderControlView]) {
//        if ([keyPath isEqualToString:@"hidden"]) {
//            if ([self.scaleSliderControlView isHidden]) {
//                [self.cameraControlButtonsStackView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//                    if ([obj isKindOfClass:[UIButton class]])
//                    {
////                        NSLog(@"button %lu", [obj tag]);
//                        UIImage *large_symbol = [[(UIButton *)obj currentImage] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithTextStyle:UIFontTextStyleLargeTitle]];
//                        [(UIButton *)obj setImage:large_symbol forState:UIControlStateNormal];
//                        [self setMeasuringUnit:[NSString stringWithFormat:@"%@", @""]];
//                    }
//                }];
//                    [self cameraControlAction:(UIButton *)[self viewWithTag:[self selectedCameraProperty]]];
//            } else {
//                float value = [self.delegate valueForCameraProperty:[self selectedCameraProperty]];
//                NSLog(@"Value out: %f", value);
////                CGRect scrollRect = CGRectMake(-CGRectGetMidX(self.scaleSliderScrollView.frame) + (CGRectGetWidth(self.scaleSliderScrollView.frame) * value), self.scaleSliderScrollView.frame.origin.y, (CGRectGetMaxX(self.scaleSliderScrollView.frame)) + fabs(CGRectGetMidX(self.scaleSliderScrollView.frame)),  CGRectGetHeight(self.scaleSliderScrollView.frame));
//                [self.scaleSliderScrollView setContentOffset:CGPointMake(-CGRectGetMidX(self.scaleSliderScrollView.frame) + (self.scaleSliderScrollView.contentSize.width * value), 0.0) animated:TRUE];//  scrollRectToVisible:scrollRect animated:FALSE];
//                [self setMeasuringUnit:[[self numberFormatter] stringFromNumber:[NSNumber numberWithFloat:(value * 10)]]];
//            }
//        }
//    }
//    });
//}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    //    NSUInteger index = [[touch gestureRecognizers] indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    //        BOOL isTapGesture = ([(UIGestureRecognizer *)obj isKindOfClass:[UITapGestureRecognizer class]]) ? TRUE : FALSE;
    //        *stop = isTapGesture;
    //
    //        if ([[touch view] isKindOfClass:[UIButton class]])
    //        {
    //            NSLog(@"UIButton tapped");
    //        }
    //
    //        return isTapGesture;
    //    }];
    //    NSLog(@"Index %lu", index);
    //    return (index != NSNotFound) ? TRUE : FALSE;
    return TRUE;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (!self.scaleSliderControlView.isHidden)
    {
        [self.cameraPropertyButtons enumerateObjectsUsingBlock:^(UIButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
            BOOL isPointInsideButtonRect = CGRectContainsPoint([button frame], point); //([button pointInside:[self convertPoint:point toView:button] withEvent:event]) ? TRUE : FALSE;
            if (isPointInsideButtonRect)
                   {
//                       CameraProperty selectedCameraProperty = [self selectedCameraProperty];
//                       CameraProperty buttonTag = (CameraProperty)[button tag];
//                       BOOL buttonCameraPropertiesIdentical = (selectedCameraProperty = buttonTag) ? TRUE : FALSE;
//                       if (!buttonCameraPropertiesIdentical && ![button isSelected] )
                       [button sendAction:@selector(cameraControlAction:) to:self forEvent:event];
                   } else {
                       switch ((CameraProperty)[button tag]) {
                           case CameraPropertyRecord:
                           {
                               [button sendAction:@selector(recordActionHandler:) to:self forEvent:event];
                               break;
                           }
                               
                           default:
                               break;
                       }
                   }
            *stop = isPointInsideButtonRect;
        }];
    }
    
       
    
    return TRUE;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

//- (void)handlePanGesture:(UIPanGestureRecognizer *)sender {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if (sender.state == UIGestureRecognizerStateBegan || sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateChanged) {
//            CGFloat location = [sender locationOfTouch:nil inView:sender.view.superview].x / CGRectGetWidth(self.superview.frame);
//            setCameraPropertyBlock = (!setCameraPropertyBlock) ? [self.delegate setCameraProperty] : setCameraPropertyBlock;
//            setCameraPropertyBlock((sender.state == UIGestureRecognizerStateEnded) ? FALSE : TRUE, [self selectedCameraProperty], location);
//        }
//    });
//}

- (void)handleTapGesture:(UITapGestureRecognizer *)sender {

}

static float(^scaleSliderValue)(CGRect, CGFloat, float, float) = ^float(CGRect scrollViewFrame, CGFloat contentOffsetX, float scaleMinimum, float scaleMaximum)
{
    CGFloat frameMinX  = -(CGRectGetMidX(scrollViewFrame));
    CGFloat frameMaxX  =  CGRectGetMaxX(scrollViewFrame) + fabs(CGRectGetMidX(scrollViewFrame));
    contentOffsetX     =  (contentOffsetX < frameMinX) ? frameMinX : ((contentOffsetX > frameMaxX) ? frameMaxX : contentOffsetX);
    float slider_value =  normalize(contentOffsetX, 0.0, 1.0, frameMinX, frameMaxX);
    slider_value       =  (slider_value < 0.0) ? 0.0 : (slider_value > 1.0) ? 1.0 : slider_value;
    
    return slider_value;
};

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ((scrollView.isDragging || scrollView.isTracking || scrollView.isDecelerating))
        {
            float value = scaleSliderValue(scrollView.frame, scrollView.contentOffset.x, 0.0, 1.0);
            CameraProperty cameraProperty = [self selectedCameraProperty];
            if (cameraProperty == CameraPropertyISO) NSLog(@"ISO %f", value);
            self->setCameraPropertyValueBlock(cameraProperty, value);
            [self setValue:value forCameraControlProperty:cameraProperty];
            [(UIButton *)[self viewWithTag:cameraProperty] setTintColor:[UIColor systemRedColor]];
        }
    });
}

//- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
//{
//    [self.scaleSliderControlView setHidden:TRUE];
//}


- (CameraProperty)selectedCameraProperty
{
    NSUInteger index = [self.cameraPropertyButtons indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        *stop = [obj isSelected];
        return [obj isSelected];
    }];
    NSLog(@"index %lu", index);
    CameraProperty cameraProperty = (index != NSNotFound) ? (CameraProperty)[[self.cameraPropertyButtons objectAtIndex:index] tag] : NSNotFound;
    
    return cameraProperty;
}

//- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
//    //    NSLog(@"%s", __PRETTY_FUNCTION__);
//    dispatch_async(dispatch_get_main_queue(), ^{
//        //        CGRect scrollRect = ((UICollectionView *)[self viewWithTag:6]).frame;
//        if ([(UIButton *)[self viewWithTag:ControlButtonTagFocus] isSelected])
//        {
//            [self.delegate autoFocusWithCompletionHandler:^(double focus) {
//                //                [self.delegate scrollSliderControlToItemAtIndexPath:[NSIndexPath indexPathForItem:(long)(focus) * 10.0 inSection:0]];
//            }];
//        } else if ([(UIButton *)[self viewWithTag:ControlButtonTagISO] isSelected] && ![(UIButton *)[self viewWithTag:ControlButtonTagExposureDuration] isSelected])
//        {
//            [self.delegate autoExposureWithCompletionHandler:^(double ISO) {
//                //                if ([(UIButton *)[self viewWithTag:ControlButtonTagExposureDuration] isSelected]) [self.delegate setISO:ISO];
//                //                [self.delegate scrollSliderControlToItemAtIndexPath:[NSIndexPath indexPathForItem:(long)(ISO) * 10.0 inSection:0]];
//            }];
//        }
//
//    });
//}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    //    NSLog(@"forwardingTargetForSelector");
    return self.delegate;
}

- (IBAction)recordActionHandler:(UIButton *)sender {
    [self.delegate toggleRecordingWithCompletionHandler:^(BOOL isRunning, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [(UIButton *)sender setSelected:isRunning];
            [(UIButton *)sender setHighlighted:isRunning];
        });
    }];
}

static CMTime (^exposureDurationForMode)(ExposureDurationMode) = ^CMTime(ExposureDurationMode exposureDurationMode)
{
    switch (exposureDurationMode) {
        case ExposureDurationModeDefault:
            return CMTimeMakeWithSeconds(1.0/30.0, 1000*1000*1000);
            break;
            
        case ExposureDurationModeLong:
            return CMTimeMakeWithSeconds(1.0/3.0, 1000*1000*1000);
            break;
            
//        case ExposureDurationModeShort:
//            return kCMTimeInvalid;
//            break;
            
        default:
            return kCMTimeInvalid;
            break;
    }
};

- (IBAction)exposureDurationMode:(UIButton *)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [sender setEnabled:FALSE];
        BOOL shouldSelectExposureDurationModeButton = ![sender isSelected];
        [sender setSelected:shouldSelectExposureDurationModeButton];
        [sender setHighlighted:shouldSelectExposureDurationModeButton];
        
        ExposureDurationMode targetExposureDurationMode = (shouldSelectExposureDurationModeButton) ? ExposureDurationModeDefault : ExposureDurationModeLong;
        CMTime targetExposureDuration = exposureDurationForMode(targetExposureDurationMode);
        [self.delegate targetExposureDuration:targetExposureDuration withCompletionHandler:^(CMTime currentExposureDuration) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [sender setEnabled:TRUE];
            });
        }];
    });
}

- (IBAction)cameraControlAction:(UIButton *)sender
{
    if (!self.scaleSliderScrollView.isDragging && !self.scaleSliderScrollView.isTracking && !self.scaleSliderScrollView.isDecelerating)
    dispatch_async(dispatch_get_main_queue(), ^{
        CameraProperty selectedButtonCameraProperty = [self selectedCameraProperty];
        CameraProperty senderButtonCameraProperty = (CameraProperty)[sender tag];
        BOOL cameraPropertiesIdentical = (senderButtonCameraProperty == selectedButtonCameraProperty) ? TRUE : FALSE;
        NSLog(@"cameraProperty %@ cameraPropertyButtons", ((selectedButtonCameraProperty < self.cameraPropertyButtons.count) ? @"<" : @">"));
        [self deselectCameraControlButtonForCameraProperty:selectedButtonCameraProperty];
        [self selectCameraControlButtonForCameraProperty:(cameraPropertiesIdentical) ? nil : senderButtonCameraProperty];
            //    dispatch_async(dispatch_get_main_queue(), ^{
            //        // Hide the slider? TRUE if the sender button is selected || if the sender button is not selected && if the slider is showing (TRUE)
            //        [self.scaleSliderControlView setHidden:([(UIButton *)sender isSelected] && !(self.scaleSliderControlView.isHidden))]; // is the sender is not already selected (and, therefore, displaying the slider,
            //        [self.cameraControlButtons enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            //            dispatch_async(dispatch_get_main_queue(), ^{
            //                BOOL shouldSelect = ([sender isEqual:obj]) ? TRUE : FALSE; // if the enumerated button and the sender button are the same AND the sender button is not already selected...
            //                [obj setSelected:shouldSelect];
            //                [obj setHighlighted:shouldSelect];
            //                UIImage *symbol = (shouldSelect) ? [[(UIButton *)obj currentImage] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithTextStyle:UIFontTextStyleTitle2 /* configurationWithScale:UIImageSymbolScaleSmall*/]] : [[(UIButton *)obj currentImage] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithTextStyle:UIFontTextStyleLargeTitle]];
            //                [(UIButton *)obj setImage:symbol forState:UIControlStateNormal];
            //                if (shouldSelect)
            //                {
            //                    //                    [self.scaleSliderControlView setHidden:(!shouldSelect)];
            //                    [self.scaleSliderOverlayView setSelectedCameraPropertyValue:[self selectedCameraPropertyFrame]];
            //                    [self.scaleSliderOverlayView setNeedsDisplay];
            //
            //                    float value = [self.delegate valueForCameraProperty:(CameraProperty)[(UIButton *)obj tag]];
            //                    [self.scaleSliderScrollView setContentOffset:CGPointMake(-CGRectGetMidX(self.scaleSliderScrollView.frame) + (self.scaleSliderScrollView.contentSize.width * value), 0.0) animated:TRUE];//  scrollRectToVisible:scrollRect animated:FALSE];
            //                    [self setMeasuringUnit:[[self numberFormatter] stringFromNumber:[NSNumber numberWithFloat:(value * 10)]]];
            //                    //                    NSLog(@"origin x (1): %f", ((UIButton *)obj).frame.origin.x);
            //                }
            //            });
            //        }];
    });
}

- (void)selectCameraControlButtonForCameraProperty:(CameraProperty)cameraProperty
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (cameraProperty)
        {
            UIButton *selectedButton = (UIButton *)[self viewWithTag:cameraProperty];
            // if the enumerated button and the sender button are the same AND the sender button is not already selected...
            [selectedButton setSelected:TRUE];
            [selectedButton setHighlighted:TRUE];
            UIImage *symbol = [[(UIButton *)selectedButton currentImage] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithTextStyle:UIFontTextStyleCaption1]];
            [(UIButton *)selectedButton setImage:symbol forState:UIControlStateNormal];
            [self.scaleSliderControlView setHidden:FALSE];
            [self.scaleSliderOverlayView setSelectedCameraPropertyValue:[self cameraControlButtonRectForCameraProperty:cameraProperty]];
            [self.scaleSliderOverlayView setNeedsDisplay];
            
            float value = [self.delegate valueForCameraProperty:cameraProperty];
            CGFloat frameMinX  = -(CGRectGetMidX(self.scaleSliderScrollView.frame));
            CGFloat frameMaxX  =  CGRectGetMaxX(self.scaleSliderScrollView.frame) + fabs(CGRectGetMidX(self.scaleSliderScrollView.frame));
            [self.scaleSliderScrollView setContentOffset:CGPointMake(-CGRectGetMidX(self.scaleSliderScrollView.frame) + ((frameMaxX + frameMinX) * value), 0.0) animated:TRUE];
            [self setValue:value forCameraControlProperty:cameraProperty];
        }
    });
}

- (void)deselectCameraControlButtonForCameraProperty:(CameraProperty)cameraProperty
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (cameraProperty)
        {
            UIButton *selectedButton = (UIButton *)[self viewWithTag:(!cameraProperty) ? cameraProperty : [self selectedCameraProperty]];
            // if the enumerated button and the sender button are the same AND the sender button is not already selected...
            [selectedButton setSelected:FALSE];
            [selectedButton setHighlighted:FALSE];
            UIImage *symbol = [[(UIButton *)selectedButton currentImage] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithTextStyle:UIFontTextStyleLargeTitle]];
            [(UIButton *)selectedButton setImage:symbol forState:UIControlStateNormal];
        }
        [self.scaleSliderControlView setHidden:TRUE];
        [self.scaleSliderOverlayView setNeedsDisplay];
    });
}

// all values returned from delegate must be validated and then normalized between 0 and 10 using the min and max range of the property
double (cameraPropertyFunc)(id<CameraControlsDelegate> delegate, CameraProperty cameraProperty)
{
    double cameraPropertyValue;
    switch (cameraProperty) {
        case CameraPropertyExposureDuration:
        {
            cameraPropertyValue = (double)delegate.videoDevice.exposureDuration.value;
            break;
        }
        case CameraPropertyISO:
        {
            cameraPropertyValue = (double)delegate.videoDevice.ISO;
            break;
        }
        case CameraPropertyLensPosition:
        {
            cameraPropertyValue = (double)delegate.videoDevice.lensPosition;
            break;
        }
        case CameraPropertyTorchLevel:
        {
            cameraPropertyValue = (double)delegate.videoDevice.torchLevel;
            break;
        }
        case CameraPropertyVideoZoomFactor:
        {
            cameraPropertyValue = (double)delegate.videoDevice.videoZoomFactor;
            break;
        }
            
        default:
        {
            cameraPropertyValue = 5.0;
            break;
        }
    }
    
    return cameraPropertyValue;
}

- (void)displayValuesForCameraControlProperties
{
//    struct CameraProperties cameraProperties;
//    initCameraProperties(self.delegate, &cameraProperties);
    
    [self.cameraPropertyButtons enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_async(dispatch_get_main_queue(), ^{
            double value = cameraPropertyFunc(self.delegate, (CameraProperty)[obj tag]);
            NSString *title = [[self numberFormatter] stringFromNumber:[NSNumber numberWithFloat:value]];
            [obj setTitle:title forState:UIControlStateNormal];
            [obj setTintColor:[UIColor systemBlueColor]];
        });
    }];
}

- (void)setValue:(float)value forCameraControlProperty:(CameraProperty)cameraProperty
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        self.layer.sublayers = nil;
    //    });
    
    NSMutableParagraphStyle *centerAlignedParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    centerAlignedParagraphStyle.alignment                = NSTextAlignmentCenter;
    NSDictionary *centerAlignedTextAttributes            = @{NSForegroundColorAttributeName:[UIColor systemYellowColor],
                                                             NSFontAttributeName:[UIFont systemFontOfSize:14.0],
                                                             NSParagraphStyleAttributeName:centerAlignedParagraphStyle};
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:[[self numberFormatter] stringFromNumber:[NSNumber numberWithFloat:value]]
                                                                           attributes:centerAlignedTextAttributes];
        [self.textLayer setOpaque:FALSE];
        [self.textLayer setAlignmentMode:kCAAlignmentCenter];
        [self.textLayer setWrapped:TRUE];
        self.textLayer.string = attributedString;
        
        CGSize textLayerframeSize = [self suggestFrameSizeWithConstraints:self.layer.bounds.size forAttributedString:attributedString]; // this creates the right size frame now (so work it back in)
        CGRect buttonFrame = [[self cameraControlButtonRectForCameraProperty:cameraProperty] CGRectValue];
        CGRect buttonFrameInSuperView = [self convertRect:buttonFrame toView:self];
        
        CGRect frame = CGRectMake(CGRectGetMidX(buttonFrameInSuperView) - (textLayerframeSize.width / 2.0), textLayerframeSize.height * 1.25, textLayerframeSize.width, textLayerframeSize.height);
        //        CGRect frame = CGRectMake(CGRectGetMidX([[self viewWithTag:[self selectedCameraProperty]] convertRect:[[self selectedCameraPropertyFrame] CGRectValue] toView:self]), /*(CGRectGetMidX([[self selectedCameraPropertyFrame] CGRectValue]).origin.x - ([[self selectedCameraPropertyFrame] CGRectValue].size.width / 2.0)) + 83.0*/, ((((CGRectGetMinY(self.bounds) + CGRectGetMidY(self.bounds)) / 2.0) + 6.0) + textLayerFrameY), 48.0, textLayerframeSize.height);
        
       self.textLayer.frame = frame;
        //        [textLayer setBackgroundColor:[UIColor redColor].CGColor];
        
        
    });
    
}

- (CGSize)suggestFrameSizeWithConstraints:(CGSize)size forAttributedString:(NSAttributedString *)attributedString
{
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFMutableAttributedStringRef)attributedString);
    CFRange attributedStringRange = CFRangeMake(0, attributedString.length);
    CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, attributedStringRange, NULL, size, NULL);
    CFRelease(framesetter);
    
    return suggestedSize;
}

- (NSValue *)cameraControlButtonRectForCameraProperty:(CameraProperty)cameraProperty
{
    CGRect cameraControlButtonRect = (CGRect)[(UIButton *)[self viewWithTag:cameraProperty] frame];
    /*CGRectMake(CGRectGetMinX( (CGRect)[(UIButton *)[self viewWithTag:cameraProperty] frame]),
                                                    CGRectGetMinY( (CGRect)[(UIButton *)[self viewWithTag:[self selectedCameraProperty]] frame]),
                                                    CGRectGetWidth((CGRect)[(UIButton *)[self viewWithTag:[self selectedCameraProperty]] frame]),
                                                    CGRectGetHeight((CGRect)[(UIButton *)[self viewWithTag:[self selectedCameraProperty]] frame]));*/
    
    NSValue *selectedCameraPropertyValue = [NSValue valueWithCGRect:cameraControlButtonRect];
    //    NSLog(@"selectedCameraPropertyFrame (2): %f", selectedCameraPropertyFrame.origin.x);
    
    return selectedCameraPropertyValue;
}

- (UIButton *)selectedCameraControlButton
{
    UIButton *selectedCameraControlButton = (UIButton *)[self viewWithTag:[self selectedCameraProperty]];
    
    return selectedCameraControlButton;
}
   

@end
