//
//  CameraPropertiesDispatcher.m
//  ISOCameraLDE-B
//
//  Created by Xcode Developer on 10/11/19.
//  Copyright © 2019 James Bush. All rights reserved.
//

#import "CameraPropertiesDispatcher.h"

@implementation CameraPropertiesDispatcher

// Exchange queue for Producer and Consumer
- (dispatch_queue_t)cameraPropertyChangesQueue
{
    __block dispatch_queue_t q = self->_cameraPropertyChangesQueue;
    if (!q)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            q = dispatch_queue_create_with_target("concurrent cameraPropertyChangesQueue", DISPATCH_QUEUE_CONCURRENT, dispatch_queue_create("serial cameraPropertyChangesQueue", DISPATCH_QUEUE_SERIAL));
            self->_cameraPropertyChangesQueue = q;
        });
    }
    
    return q;
}

// Produce
NSInteger productionCount;
- (void)cameraPropertyChanges
{
    typedef struct{
        float *value;
    } CameraPropertyValue;
    
    CameraPropertyValue *context = (CameraPropertyValue *)malloc(sizeof(CameraPropertyValue));
    if (context != NULL)
    {
        NSInteger index = productionCount++;
        const char *label = [[NSString stringWithFormat:@"%ld", (long)index] cStringUsingEncoding:NSUTF8StringEncoding];
        dispatch_queue_set_specific(self.cameraPropertyChangesQueue, label, context, NULL);
        dispatch_source_merge_data(self.cameraPropertyChangesQueueEvent, (long)index);
    }
}

// Consume
- (dispatch_source_t)cameraPropertyChangesQueueEvent
{
    __block dispatch_source_t dispatch_source = self.cameraPropertyChangesQueueEvent;
    dispatch_queue_t dispatch_queue = self.cameraPropertyChangesQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_queue);
        dispatch_source_set_event_handler(dispatch_source, ^{
            long index = dispatch_source_get_data(dispatch_source);
            const char *label = [[NSString stringWithFormat:@"%ld", index] cStringUsingEncoding:NSUTF8StringEncoding];
            dispatch_async(dispatch_queue, ^{
                
                typedef struct{
                    float *value;
                } CameraPropertyValue;
                
                CameraPropertyValue *value = (CameraPropertyValue *)dispatch_get_specific(label);
                if (value != NULL)
                {
                    // Use value here
                    //NSLog(@"Camera property changes source data (value): %f", *value);
                    // Free when finished
                    free((void *)value);
                }
            });
        });
        
        dispatch_set_target_queue(dispatch_source, dispatch_queue);
        dispatch_resume(dispatch_source);
        self->_cameraPropertyChangesQueueEvent = dispatch_source;
    });
    
    return dispatch_source;
}

@end
