//
//  TYOpusCodec.m
//  LoginWithAmazonSample
//
//  Created by huchao on 2021/5/12.
//  Copyright © 2021 Amazon. All rights reserved.
//

#import "TYOpusCodec.h"
#import "opus.h"
@implementation TYOpusCodec
{
    
    OpusEncoder *enc;
    
    OpusDecoder *dec;
    
}
-(instancetype)initWithSampleRate:(int32_t)sampleRate
                         channels:(int)channels
                      application:(int)application
                          bitRate:(int32_t) bitRate
                       complexity:(int32_t) complexity{
    if (self = [super init]) {
        _sampleRate = sampleRate;
        _channels = channels;
        _application = application;
        _bitRate = bitRate;
        _complexity = complexity;
        [self opusInit];
    }
    return self;
}

+(instancetype)avsOpusCodec_16bitRate{
    return [[self alloc]initWithSampleRate:16000 channels:1 application:OPUS_APPLICATION_RESTRICTED_LOWDELAY bitRate:16000 complexity:4];
}

+(instancetype)avsOpusCodec_32bitRate{
    return [[self alloc]initWithSampleRate:16000 channels:1 application:OPUS_APPLICATION_RESTRICTED_LOWDELAY bitRate:32000 complexity:4];
}

-(void)opusInit

{
    
    int error;
    
    enc = opus_encoder_create(_sampleRate, _channels, _application, &error);//(采样率，声道数,,)
    
    dec = opus_decoder_create(_sampleRate, _channels, &error);
    
    opus_encoder_ctl(enc, OPUS_SET_VBR(0));
    
    opus_encoder_ctl(enc, OPUS_SET_BITRATE(_bitRate));//比特率
    
    opus_encoder_ctl(enc,OPUS_SET_APPLICATION(_application));
    
    opus_encoder_ctl(enc, OPUS_SET_COMPLEXITY(_complexity));//录制质量 1-10
    
    opus_encoder_ctl(enc, OPUS_SET_SIGNAL(OPUS_SIGNAL_VOICE));//信号
    
}

-(NSData*)encodeMonoPCMData:(NSData*)data{
    return [self encodePCMData:data channels:1];
}

-(NSData*)encodeStereoPCMData:(NSData*)data{
    return  [self encodePCMData:data channels:2];
}

-(NSData*)encodePCMData:(NSData*)data channels:(int)channels{
    NSInteger pcmLen = data.length;
    int frame_size = (int)pcmLen / sizeof(short)/channels;
    short input_pcm_frame[frame_size];
    opus_int32 max_data_bytes = 2 * frame_size ;//随便设大,此时为原始PCM大小
    memcpy(input_pcm_frame, [data bytes], pcmLen);
    
    unsigned char out_opus_frame[frame_size];
    int outLen = opus_encode(enc, input_pcm_frame, frame_size, out_opus_frame, max_data_bytes);
    
    if (outLen > 0){
        NSData *decodedData = [NSData dataWithBytes:out_opus_frame length:outLen];
        return decodedData;
    }
    return nil;
    
}

-(NSData*)decodeOpusData:(NSData*)data pcmDataFrameSize:(int)pcmDataFrameSize{
    int opusLength = (int)[data length];
    
    uint8_t opusData[opusLength];
    memcpy(opusData, [data bytes], opusLength);
    
    int shortFrameSize = pcmDataFrameSize/sizeof(short);
    short decodeData[shortFrameSize*_channels];
    
    int pcmDataLength = opus_decode(dec, opusData, opusLength, decodeData, shortFrameSize, 0);
    
    return [NSData dataWithBytes:decodeData length:pcmDataLength*sizeof(short)];
    
}

-(void)destroy

{
    
    opus_encoder_destroy(enc);
    
    opus_decoder_destroy(dec);
    
}

-(void)dealloc{
    [self destroy];
}
@end
