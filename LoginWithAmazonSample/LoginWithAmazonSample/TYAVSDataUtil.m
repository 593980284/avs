//
//  TYAVSDataUtil.m
//  LoginWithAmazonSample
//
//  Created by huchao on 2021/4/6.
//  Copyright © 2021 Amazon. All rights reserved.
//

#import "TYAVSDataUtil.h"
#import "YYModel.h"

#define kContentTypeJSON @"application/json"
#define kContentTypeAudio @"application/octet-stream"

#define kPCM @"AUDIO_L16_RATE_16000_CHANNELS_1"
#define kOPUS @"OPUS"

@interface TYAVSDirectivesModel()
@property (nonatomic, strong) NSArray *speakParseArr;//{begin: end: content}
@end

@implementation TYAVSDirectivesModel
-(NSString *)Namespace{
    return _header[@"namespace"];
}
-(NSString *)name{
    return _header[@"name"];
}
-(NSString *)messageId{
    return _header[@"messageId"];
}
-(NSString *)dialogRequestId{
    return _header[@"dialogRequestId"];
}

-(CGFloat)expectSpeech_timeoutInMilliseconds{
    NSAssert([self.name isEqualToString:TYAVSDirectiveTypeExpectSpeech], @"Expected Speech timeout time that exists only in ExpectSpeech directive");
    NSNumber *timeoutInMilliseconds = _payload[@"timeoutInMilliseconds"];
    if (![timeoutInMilliseconds isKindOfClass:[NSNumber class]]) {
        return 0.0;
    }
    
    if (![timeoutInMilliseconds isKindOfClass:[NSNumber class]]) {
        NSAssert1(0, @"expectSpeech_initiator type should be NSNumber! %@", timeoutInMilliseconds);
        return 0.0;
    }
    return timeoutInMilliseconds.floatValue;
}

-(NSDictionary *)expectSpeech_initiator{
    NSAssert([self.name isEqualToString:TYAVSDirectiveTypeExpectSpeech], @"Initiator that exists only in ExpectSpeech directive");
    NSDictionary *initiator = _payload[@"initiator"];
    if (!initiator) {
        return nil;
    }
    
    if (![initiator isKindOfClass:[NSDictionary class]]) {
        NSAssert1(0, @"expectSpeech_initiator type should be NSDictionary! %@", initiator);
        return nil;
    }
    return initiator;
}

-(NSString *)speak_content{
    if (!self.speakParseArr) {
        [self parseWEBVTT];
    }
    NSString *speak_content = @"";
    for (NSDictionary* item in self.speakParseArr) {
        NSString *content = item[@"content"];
        if (content) {
            speak_content = [NSString stringWithFormat:@"%@%@",speak_content,content];
        }
    }
    
    return speak_content;
}

-(CGFloat)speak_duration{
    if (!self.speakParseArr) {
        [self parseWEBVTT];
    }
    NSDictionary* dic = self.speakParseArr.lastObject;
    if (!dic) {
        return 0.0;
    }
    NSString *end = dic[@"end"];
    if (!end) {
        return 0.0;
    }
    NSArray*times = [end componentsSeparatedByString:@":"];
    NSString*min = times[0];
    NSString*s = times[1];
    return min.intValue*60+s.floatValue;
}

-(void)parseWEBVTT{
    NSString *webvtt = [self speak_WEBVTT];
    if (!webvtt) {
        return;
    }
    NSMutableArray *array = [NSMutableArray new];
    NSString* line_split = @"\n\n";
    NSString* item_split = @"\n";
    NSString* item_time_split = @"-->";
    
    NSArray<NSString *>* lineArr = [webvtt componentsSeparatedByString:line_split];
    for (NSString* line in lineArr) {
        NSArray<NSString *>* itemArr = [line componentsSeparatedByString:item_split];
        if (itemArr.count != 3) {
            continue;
        }
        NSString *timeString = itemArr[1];
        NSArray<NSString *>* time_arr = [timeString componentsSeparatedByString:item_time_split];
        if (time_arr.count !=2) {
            continue;
        }
        NSString *begin = time_arr[0];
        NSString *end = time_arr[1];
        NSString *content = itemArr[2];
        [array addObject:@{@"begin":begin,@"end":end,@"content":content}];
    }
    self.speakParseArr = [array copy];
}

-(NSString *)speak_WEBVTT{
    NSAssert([self.name isEqualToString:TYAVSDirectiveTypeSpeak], @"Speak_content that exists only in speak directive");
    NSDictionary *caption = _payload[@"caption"];
    NSString* content = caption[@"content"];
    if (!content) {
        return nil;
    }
    if (![content isKindOfClass:[NSString class]]) {
        NSAssert1(0, @"speak_content type should be NSString! %@", content);
        return nil;
    }
    return content;
}

@end

@implementation TYAVSUploaderStartSpeechModel

@end

@implementation TYAVSDataModel
+ (nullable NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass{
    return @{@"directives"  : [TYAVSDirectivesModel class]};
}

@end

@implementation TYAVSDataUtil
+ (NSData *)JSONHeaders {
    NSMutableData *mutdata = [NSMutableData data];
    [mutdata appendData: [@"Content-Disposition: form-data; name=\"metadata\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [mutdata appendData: [@"Content-Type: application/json; charset=UTF-8\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [mutdata appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    return mutdata;
}

+ (NSData *)JSONContent:(NSDictionary *)initiator startSpeechModel:(TYAVSUploaderStartSpeechModel*)startSpeechModel{
    NSString *profile = @"NEAR_FIELD";
    NSString *dialogRequestId = startSpeechModel.dialogId;
    BOOL isPcm = startSpeechModel.audioFormat == TYAVSAudioFormatPCM_L16_16KHZ_MONO;
    switch (startSpeechModel.audioProfile) {
        case TYAVSProfileCLOSE_TALK:
            profile = @"CLOSE_TALK";
            break;
        case TYAVSProfileNEAR_FIELD:
            profile = @"NEAR_FIELD";
            break;
        case TYAVSProfileFAR_FIELD:
            profile = @"FAR_FIELD";
            break;
        default:
            NSAssert(0, @"profile should be 0-2");
            break;
    }
    NSMutableDictionary* contentDic = @{@"context": @[], @"event": @{
                                                @"header":@{@"namespace": @"SpeechRecognizer",
                                                            @"name":@"Recognize",
                                                            @"messageId": [NSUUID.UUID UUIDString],
                                                            @"dialogRequestId":dialogRequestId?:@"dialogRequestId-123"},
                                                @"payload":@{@"profile": profile,@"format": isPcm?kPCM:kOPUS}}}.mutableCopy;
    if (initiator) {
        [contentDic setObject:initiator forKey:@"initiator"];
    }
    NSLog(@"____请求参数:%@",contentDic);
    NSData *contentData = [NSJSONSerialization dataWithJSONObject:contentDic options:0 error:nil];
    NSMutableData *mutdata = [NSMutableData data];
    [mutdata appendData:contentData];
    [mutdata appendData:[@"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    return mutdata;
}

+ (NSData *)binaryAudioHeaders {
    NSMutableData *mutdata = [NSMutableData data];
    [mutdata appendData: [@"Content-Disposition: form-data; name=\"audio\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [mutdata appendData: [@"Content-Type: application/octet-stream\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [mutdata appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    return mutdata;
}


+(NSData *)beginData:(nullable NSDictionary *)initiator
    startSpeechModel:(TYAVSUploaderStartSpeechModel*)startSpeechModel{
    NSMutableData *body = [NSMutableData data];
    [body appendData:[@"--BOUNDARY_TERM_HERE\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[self JSONHeaders]];
    [body appendData:[self JSONContent: initiator startSpeechModel: startSpeechModel]];
    [body appendData:[@"--BOUNDARY_TERM_HERE\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[self binaryAudioHeaders]];
    return body;
}

+(NSData *)endData{
    return [@"--BOUNDARY_TERM_HERE--\r\n" dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSArray<NSDictionary *> *)splitData:(NSData *)data withBoundary:(NSString *)contentType {
    if (!contentType) {
        return nil;
    }
    NSArray *boundaryArr = [self matchesInString:contentType withRegExpPattern:@"boundary=(.*?);"];
    if(!boundaryArr || boundaryArr.count < 2){
        return nil;
    }
    NSString *boundary = [boundaryArr objectAtIndex:1];
   
    NSData *head_boundaryData = [[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *inner_boundaryData = [[NSString stringWithFormat:@"\r\n--%@", boundary] dataUsingEncoding:NSUTF8StringEncoding];

    NSData *blankLineData = [@"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableArray *dictArr = [NSMutableArray array];
    
    NSUInteger curIdx = 0;
    while (curIdx < data.length) {
        NSRange head_boundaryRange = [data rangeOfData:head_boundaryData
                                               options:kNilOptions
                                                 range:NSMakeRange(curIdx, data.length-curIdx)];
    
        if (curIdx == 0 && head_boundaryRange.location != 0) {
            curIdx = 0;
        }else{
           if (head_boundaryRange.length == 0) { break; }
            curIdx = NSMaxRange(head_boundaryRange);
        }
        NSRange paddingRange = [data rangeOfData:blankLineData
                                         options:kNilOptions
                                           range:NSMakeRange(curIdx, data.length-curIdx)];
        if (paddingRange.length == 0) { break; }
        NSData *headerData = [data subdataWithRange:NSMakeRange(curIdx, paddingRange.location-curIdx)];
        
        curIdx = NSMaxRange(paddingRange);
        NSRange inner_boundaryRange = [data rangeOfData:inner_boundaryData
                                                options:kNilOptions
                                                  range:NSMakeRange(curIdx, data.length-curIdx)];
        NSData *contentData = nil;
        if (inner_boundaryRange.length == 0) {
            contentData = [data subdataWithRange:NSMakeRange(curIdx,data.length-curIdx)];
            curIdx = data.length;
        }else{
            contentData = [data subdataWithRange:NSMakeRange(curIdx, inner_boundaryRange.location-curIdx)];
            curIdx = inner_boundaryRange.location;
        }
        
        
        [dictArr addObject: @{@"header": headerData, @"content": contentData}];
        
       
    }
    
    return dictArr;
}

+ (nullable NSArray<NSString *> *)matchesInString:(nonnull NSString *)string withRegExpPattern:(nonnull NSString *)regExp {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regExp options:0 error:nil];
    if (regex != nil) {
        NSTextCheckingResult *firstMatch=[regex firstMatchInString:string options:0 range:NSMakeRange(0, [string length])];
        if (firstMatch.numberOfRanges > 0) {
            NSLog(@"firstMatch:%@",firstMatch);
            NSMutableArray<NSString *> *arr = [NSMutableArray array];
            for (int i=0; i<firstMatch.numberOfRanges; i++) {
                NSRange resultRange = [firstMatch rangeAtIndex:i];
                [arr addObject:[string substringWithRange:resultRange]];
            }
            return arr;
        }
    }
    return nil;
}

+ (TYAVSDataModel *)parseWithData:(NSData *)data withBoundary:(NSString *)contentType {
    NSMutableArray *directives = [NSMutableArray array];
    NSMutableArray *speechDatas = [NSMutableArray array];
    NSMutableDictionary *dic = [NSMutableDictionary new];
    [dic setObject:directives forKey:@"directives"];
    [dic setObject:speechDatas forKey:@"speechDatas"];
    NSArray *dictArr = [self splitData:data withBoundary:contentType];
    for (NSDictionary *dict in dictArr) {
        NSString *header = [[NSString alloc] initWithData:dict[@"header"] encoding:NSUTF8StringEncoding];
        if ([header containsString:kContentTypeJSON]) {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:dict[@"content"] options:kNilOptions error:NULL];
            if(dic[@"directive"]){
                [directives addObject:dic[@"directive"]];
            }
        } else if ([header containsString:kContentTypeAudio]) {
            if (dict[@"content"]) {
                [speechDatas addObject:dict[@"content"]];
            }
        } else {
            NSLog(@"⚠️Unknown Content-Type: %@", header);
        }
    }
    
    
    return [TYAVSDataModel yy_modelWithDictionary:dic];
}
#pragma event
+(NSData *)Event_speechStartedWithToken:(NSString *)token{
  
    return [self EventWithNamespace:TYAVSDirectiveNamespaceSpeechSynthesizer name:@"SpeechStarted" payload:token?@{@"token":token}:@{}];
}

+(NSData *)Event_speechFinishedWithToken:(NSString *)token{
    return [self EventWithNamespace:TYAVSDirectiveNamespaceSpeechSynthesizer name:@"SpeechFinished" payload:token?@{@"token":token}:@{}];
}
/// @param offsetInMilliseconds 毫秒
+(NSData *)Event_speechInterruptedWithToken:(NSString *)token offsetInMilliseconds:(NSInteger)offsetInMilliseconds{
   
    return [self EventWithNamespace:TYAVSDirectiveNamespaceSpeechSynthesizer name:@"SpeechInterrupted" payload:@{@"token":token?:token, @"offsetInMilliseconds":@(offsetInMilliseconds)}];
}

+(NSData *)Event_SettingWithPayload:(NSDictionary *)payload{
   return [self EventWithNamespace:TYAVSDirectiveNamespaceSetting name:TYAVSDirectiveTypeSettingsUpdated payload:payload];
}


+(NSData*)EventWithNamespace:(NSString *)namespace name:(NSString *)name payload:(NSDictionary *)payload{
    NSDictionary *event = @{
        @"context": @[],
        @"event": @{
                @"header": @{
                        @"namespace": namespace,
                        @"name": name,
                        @"messageId": [NSUUID.UUID UUIDString],
                },
                @"payload":payload?:@{}
        }
    };
    NSMutableData *body = [NSMutableData new];
    [body appendData:[@"--BOUNDARY_TERM_HERE\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[self JSONHeaders]];
    [body appendData:[NSJSONSerialization dataWithJSONObject:event options:0 error:nil]];
    [body appendData:[@"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"--BOUNDARY_TERM_HERE\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    return [body copy];
}
    
  
@end
