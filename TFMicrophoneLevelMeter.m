#import "TFMicrophoneLevelMeter.h"

@import AudioToolbox;
@import AVFoundation;


void audioDataCallback(void *userData, AudioQueueRef aq, AudioQueueBufferRef buffer, const AudioTimeStamp *time, UInt32 numDescs, const AudioStreamPacketDescription *descs) {
	// We don't actually need the audio data. Just re-use the buffer.
	AudioQueueEnqueueBuffer(aq, buffer, 0, NULL);
}

@interface TFMicrophoneLevelMeter ()
@property AudioQueueRef audioQueue;
@property AudioQueueBufferRef audioBuffer;
@property(weak) NSTimer *timer;
@end


@implementation TFMicrophoneLevelMeter

- (id)init {
	if(!(self = [super init])) return nil;
    
    AVAudioSession *sharedAudioSession = [AVAudioSession sharedInstance];
    [sharedAudioSession setActive:YES error:nil];
    [sharedAudioSession setCategory:AVAudioSessionCategoryRecord error:nil];
	
	const int sampleSize = sizeof(AudioSampleType);
	
	AudioStreamBasicDescription desc = {
		.mSampleRate = 44100,
		.mFormatID = kAudioFormatLinearPCM,
		.mFormatFlags = kAudioFormatFlagsCanonical,
		.mBitsPerChannel = 8 * sampleSize,
		.mChannelsPerFrame = 1,
		.mFramesPerPacket = 1,
		.mBytesPerPacket = sampleSize,
		.mBytesPerFrame = sampleSize,
	};
	
	float bufferDuration = 0.5;
	UInt32 bufferSize = desc.mBytesPerPacket * desc.mSampleRate * bufferDuration;
	
	AudioQueueRef queue;
	AudioQueueNewInput(&desc, audioDataCallback, NULL, NULL, NULL, 0, &queue);
	self.audioQueue = queue;
	
	AudioQueueBufferRef buffer;
	AudioQueueAllocateBuffer(self.audioQueue, bufferSize, &buffer);
	self.audioBuffer = buffer;
	AudioQueueEnqueueBuffer(self.audioQueue, self.audioBuffer, 0, NULL);
	
	UInt32 on = 1;
	AudioQueueSetProperty(self.audioQueue, kAudioQueueProperty_EnableLevelMetering, &on, sizeof(on));

	self.samplingInterval = 1/30.0;
	return self;
}


- (void)dealloc {
	AudioQueueStop(self.audioQueue, true);
	AudioQueueFreeBuffer(self.audioQueue, self.audioBuffer);
	AudioQueueDispose(self.audioQueue, true);
}


- (void)start {
	AudioQueueStart(self.audioQueue, NULL);
	self.timer = [NSTimer scheduledTimerWithTimeInterval:self.samplingInterval target:self selector:@selector(sample) userInfo:nil repeats:YES];
}


- (void)stop {
	AudioQueueStop(self.audioQueue, true);
	[self.timer invalidate];
}


- (void)sample {
	AudioQueueLevelMeterState meterState;
	UInt32 size = sizeof(meterState);
	
	AudioQueueGetProperty(self.audioQueue, kAudioQueueProperty_CurrentLevelMeter, &meterState, &size);
	float level = meterState.mAveragePower;
	
	AudioQueueGetProperty(self.audioQueue, kAudioQueueProperty_CurrentLevelMeterDB, &meterState, &size);
	float dB = meterState.mAveragePower;
	
	[self.delegate microphoneLevelMeter:self didMeasureLevel:level decibelValue:dB];
}


@end