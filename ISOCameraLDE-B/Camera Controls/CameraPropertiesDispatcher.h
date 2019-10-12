//
//  CameraPropertiesDispatcher.h
//  ISOCameraLDE-B
//
//  Created by Xcode Developer on 10/11/19.
//  Copyright © 2019 James Bush. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CameraPropertiesDispatcher : NSObject

@property (nonatomic, strong) __block dispatch_queue_t cameraPropertyChangesQueue;
@property (nonatomic, strong) __block dispatch_source_t cameraPropertyChangesQueueEvent;

@end

NS_ASSUME_NONNULL_END
