//
//  TYOpusCodec.h
//  LoginWithAmazonSample
//
//  Created by huchao on 2021/5/12.
//  Copyright © 2021 Amazon. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
//固定比特率 
@interface TYOpusCodec : NSObject
//alexa 语音服务用的opus编码器16000比特率
+(instancetype)avsOpusCodec_16bitRate;
//alexa 语音服务用的opus编码器,32000比特率
+(instancetype)avsOpusCodec_32bitRate;

-(instancetype)initWithSampleRate:(int32_t)sampleRate
                         channels:(int)channels
                      application:(int)application
                          bitRate:(int32_t) bitRate
                       complexity:(int32_t) complexity;
//采样频率
@property (nonatomic,assign,readonly) int32_t sampleRate;
//声道数 1 或者 2
@property (nonatomic,assign,readonly) int channels;
//#define OPUS_APPLICATION_VOIP                2048
///** Best for broadcast/high-fidelity application where the decoded audio should be as close as possible to the input
// * @hideinitializer */
//#define OPUS_APPLICATION_AUDIO               2049
///** Only use when lowest-achievable latency is what matters most. Voice-optimized modes cannot be used.
// * @hideinitializer */
//#define OPUS_APPLICATION_RESTRICTED_LOWDELAY 2051
@property (nonatomic,assign,readonly) int application;
//比特率
@property (nonatomic,assign,readonly) int32_t bitRate;
//录音质量1-10
@property (nonatomic,assign,readonly) int32_t complexity;

//编码
-(NSData*)encodeMonoPCMData:(NSData*)data;
-(NSData*)encodeStereoPCMData:(NSData*)data;

/// 解码
/// @param data pcm data
/// @param pcmDataFrameSize 每一个channels 的FrameSize
-(NSData*)decodeOpusData:(NSData*)data pcmDataFrameSize:(int)pcmDataFrameSize;
@end

NS_ASSUME_NONNULL_END
