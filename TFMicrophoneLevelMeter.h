#import <Foundation/Foundation.h>

@class TFMicrophoneLevelMeter;

@protocol TFMicrophoneLevelMeterDelegate
- (void)microphoneLevelMeter:(TFMicrophoneLevelMeter*)meter didMeasureLevel:(double)level decibelValue:(double)dB;
@end


@interface TFMicrophoneLevelMeter : NSObject
- (id)init;
- (void)start;
- (void)stop;

@property NSTimeInterval samplingInterval;
@property (weak) id<TFMicrophoneLevelMeterDelegate> delegate;
@end