//
//  RecordTool.m
//  LoginWithAmazonSample
//
//  Created by huchao on 2021/3/23.
//  Copyright © 2021 Amazon. All rights reserved.
//

#import "RecordTool.h"
#import <AudioToolbox/AudioToolbox.h>
#define QUEUE_BUFFER_SIZE 3      // 输出音频队列缓冲个数
#define kDefaultBufferDurationSeconds 0.02//调整这个值使得录音的缓冲区大小，0.01对应310好像是
#define kDefaultSampleRate 16000   //定义采样率为16000

extern NSString * const ESAIntercomNotifationRecordString;
static BOOL isRecording = NO;

@interface RecordTool(){
    AudioQueueRef _audioQueue;                          //输出音频播放队列
    AudioStreamBasicDescription _recordFormat;
    AudioQueueBufferRef _audioBuffers[QUEUE_BUFFER_SIZE]; //输出音频缓存
}
@property (nonatomic, copy) void(^block)(NSData *);

@end

@implementation RecordTool

+ (instancetype)shared {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc]init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        //重置下
        memset(&_recordFormat, 0, sizeof(_recordFormat));
        _recordFormat.mSampleRate = kDefaultSampleRate;
        _recordFormat.mChannelsPerFrame = 1;
        _recordFormat.mFormatID = kAudioFormatLinearPCM;
        
        _recordFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        _recordFormat.mBitsPerChannel = 16;
        _recordFormat.mBytesPerPacket = _recordFormat.mBytesPerFrame = (_recordFormat.mBitsPerChannel / 8) * _recordFormat.mChannelsPerFrame;
        _recordFormat.mFramesPerPacket = 1;
        
//        //初始化音频输入队列
//        AudioQueueNewInput(&_recordFormat, inputBufferHandler, (__bridge void *)(self), NULL, NULL, 0, &_audioQueue);
//
//        //计算估算的缓存区大小
//        int frames = (int)ceil(kDefaultBufferDurationSeconds * _recordFormat.mSampleRate);
//        int bufferByteSize = frames * _recordFormat.mBytesPerFrame;
//
//        NSLog(@"缓存区大小%d",bufferByteSize);
//
//        //创建缓冲器
//        for (int i = 0; i < QUEUE_BUFFER_SIZE; i++){
//            AudioQueueAllocateBuffer(_audioQueue, bufferByteSize, &_audioBuffers[i]);
//            AudioQueueEnqueueBuffer(_audioQueue, _audioBuffers[i], 0, NULL);
//        }
    }
    return self;
}

- (void)startRecordingWithBlock:(void (^_Nullable)(NSData *_Nullable))block {
    // 开始录音
    //初始化音频输入队列
    AudioQueueNewInput(&_recordFormat, inputBufferHandler, (__bridge void *)(self), NULL, NULL, 0, &_audioQueue);
    
    //计算估算的缓存区大小
    int frames = (int)ceil(kDefaultBufferDurationSeconds * _recordFormat.mSampleRate);
    int bufferByteSize = frames * _recordFormat.mBytesPerFrame;
    
    NSLog(@"缓存区大小%d",bufferByteSize);
    
    //创建缓冲器
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++){
        AudioQueueAllocateBuffer(_audioQueue, bufferByteSize, &_audioBuffers[i]);
        AudioQueueEnqueueBuffer(_audioQueue, _audioBuffers[i], 0, NULL);
    }
    
    self.block = block;
    AudioQueueStart(_audioQueue, NULL);
    isRecording = YES;
    self.isRecording = YES;
    count = 0;
  
}

void inputBufferHandler(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime,UInt32 inNumPackets, const AudioStreamPacketDescription *inPacketDesc)
{
    if (inNumPackets > 0) {
        RecordTool *recorder = (__bridge RecordTool*)inUserData;
        [recorder processAudioBuffer:inBuffer withQueue:inAQ];
    }
    
    if (isRecording) {
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    }
}

static int count = 0;
- (void)processAudioBuffer:(AudioQueueBufferRef )audioQueueBufferRef withQueue:(AudioQueueRef )audioQueueRef
{
    NSMutableData * dataM = [NSMutableData dataWithBytes:audioQueueBufferRef->mAudioData length:audioQueueBufferRef->mAudioDataByteSize];
    
    //此处是发通知将dataM 传递出去
    if (isRecording) {
        self.block(dataM);
    } else {
        // 结束标记置NO之后，依然会有数据进行发送，这里我只取了一条（一般会出现3条。最后的基本是没有用的数据，并不是说话的内容）
        // 这样当isRecording置NO之后，就会把最后一条数据返回到调用方，用来作为结束
//        count++;
//        if (count == 1) {
//            self.block(dataM);
//        }
    }
}

-(void)stopRecording
{
    if (isRecording)
    {
        isRecording = NO;
        self.isRecording = NO;
        
        //停止录音队列和移除缓冲区,以及关闭session，这里无需考虑成功与否
        AudioQueueStop(_audioQueue, true);
        
        //移除缓冲区,true代表立即结束录制，false代表将缓冲区处理完再结束
        AudioQueueDispose(_audioQueue, true);
    }
}
@end
