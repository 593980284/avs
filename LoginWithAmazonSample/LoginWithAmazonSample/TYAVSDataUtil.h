//
//  TYAVSDataUtil.h
//  LoginWithAmazonSample
//
//  Created by huchao on 2021/4/6.
//  Copyright © 2021 Amazon. All rights reserved.
//  语音上传数据封装、收到数据解析

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, TYAVSDeviceState) {
    TYAVSDeviceStateIdle,
    TYAVSDeviceStateListening,
    TYAVSDeviceStateProcessing,
    TYAVSDeviceStateSpeaking,
    TYAVSDeviceStateExpect = 99
};

typedef NS_ENUM(NSUInteger, TYAVSProfile) {
    TYAVSProfileCLOSE_TALK,
    TYAVSProfileNEAR_FIELD,
    TYAVSProfileFAR_FIELD
};


typedef NS_ENUM(NSUInteger, TYAVSAudioFormat) {
    TYAVSAudioFormatPCM_L16_16KHZ_MONO,
    TYAVSAudioFormatOPUS_16KHZ_32KBPS_CBR_0_20MS,
    TYAVSAudioFormatOPUS_16KHZ_16KBPS_CBR_0_20MS,
    TYAVSAudioFormatMSBC
};


#define TYAVSDirectiveNamespaceSetting @"SettingsUpdated"
#define TYAVSDirectiveNamespaceSpeechSynthesizer @"SpeechSynthesizer"

#define TYAVSDirectiveTypeSpeak @"Speak"
#define TYAVSDirectiveTypeExpectSpeech @"ExpectSpeech"
#define TYAVSDirectiveTypeRecognize @"Recognize"
#define TYAVSDirectiveTypeStopCapture @"StopCapture"
#define TYAVSDirectiveTypeSettingsUpdated @"SettingsUpdated"


NS_ASSUME_NONNULL_BEGIN
@interface TYAVSDirectivesModel : NSObject

@property (nonatomic,copy) NSString *Namespace;
@property (nonatomic,copy) NSString *name;
@property (nonatomic,copy) NSString *messageId;
@property (nonatomic,copy) NSString *dialogRequestId;
@property (nonatomic,copy) NSDictionary *payload;
@property (nonatomic,copy) NSDictionary *header;

-(CGFloat)expectSpeech_timeoutInMilliseconds;
-(NSDictionary *)expectSpeech_initiator;

/// speak
-(CGFloat)speak_duration;
-(NSString *)speak_content;
-(NSString *)speak_WEBVTT;
@end

@interface TYAVSDataModel : NSObject

@property (nonatomic,copy) NSArray<TYAVSDirectivesModel *> *directives;
@property (nonatomic,copy) NSArray<NSData*> *speechDatas;

@end


//audio format :
//0 – PCM_L16_16KHZ_MONO ;
//1 – OPUS_16KHZ_32KBPS_CBR_0_20MS ;
//71 / 109
//2 – OPUS_16KHZ_16KBPS_CBR_0_20MS ;
//3 – MSBC ;
//audio profile：
//0 – CLOSE_TALK ;
//1 – NEAR_FIELD;
//2 – FAR_FIELD ;
//suppressEarcon：耳标抑制，0 – 播放；1 – 不播放。
// dialog id ：对话 id，4 字节，从 0 开始。
//play voice：是否语音播放识别结果，0 – 不播放；1 – 播放（如果播放则不需要发

@interface TYAVSUploaderStartSpeechModel : NSObject

@property (nonatomic,assign) TYAVSAudioFormat audioFormat;
@property (nonatomic,assign) TYAVSProfile audioProfile;
@property (nonatomic,assign) BOOL suppressEarcon;
@property (nonatomic,copy) NSString* dialogId;
@property (nonatomic,assign) BOOL playVoice;

@end

@interface TYAVSDataUtil : NSObject
+(NSData *)beginData:(nullable NSDictionary *)initiator
    startSpeechModel:(TYAVSUploaderStartSpeechModel*)startSpeechModel;



+(NSData *)endData;

+(TYAVSDataModel *)parseWithData:(NSData *)data withBoundary:(NSString *)contentType;

+(NSData *)Event_speechStartedWithToken:(NSString *)token;
+(NSData *)Event_speechFinishedWithToken:(NSString *)token;
/// @param offsetInMilliseconds 毫秒 已经播放了多久
+(NSData *)Event_speechInterruptedWithToken:(NSString *)token offsetInMilliseconds:(NSInteger)offsetInMilliseconds;
+(NSData *)Event_SettingWithPayload:(NSDictionary *)payload;
+(NSData*)EventWithNamespace:(NSString *)Namespace name:(NSString *)name payload:(NSDictionary *)payload;
@end

NS_ASSUME_NONNULL_END
