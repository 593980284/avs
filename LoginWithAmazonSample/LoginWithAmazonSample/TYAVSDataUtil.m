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

+ (NSData *)JSONContent:(NSDictionary *)initiator {
    NSMutableDictionary* contentDic = @{@"context": @[], @"event": @{
                                                @"header":@{@"namespace": @"SpeechRecognizer",
                                                            @"name":@"Recognize",
                                                            @"messageId": [NSUUID.UUID UUIDString],
                                                            @"dialogRequestId":@"dialogRequestId-123"},
                                                @"payload":@{@"profile": @"NEAR_FIELD",@"format": @"AUDIO_L16_RATE_16000_CHANNELS_1"}}}.mutableCopy;
    if (initiator) {
        [contentDic setObject:initiator forKey:@"initiator"];
    }
    //@"initiator": @{
    //                     @"type": @"{{STRING}}",
    //                     @"payload": @{
    //                             @"token": @"{{STRING}}"
    
    //    NSString *content = @"{\"context\": [], \"event\": {\"header\": {\"namespace\": \"SpeechRecognizer\", \"name\": \"Recognize\", \"messageId\": \"$messageId\", \"dialogRequestId\": \"$dialogRequestId\"}, \"payload\": {\"profile\": \"NEAR_FIELD\", \"format\": \"AUDIO_L16_RATE_16000_CHANNELS_1\"} } }";
    
    //    content = [content stringByReplacingOccurrencesOfString:@"$messageId" withString: [NSUUID.UUID UUIDString]];
    //    content = [content stringByReplacingOccurrencesOfString:@"$dialogRequestId" withString: @"dialogRequestId-123"];
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


+(NSData *)beginData:(NSDictionary *)initiator{
    NSMutableData *body = [NSMutableData data];
    [body appendData:[@"--BOUNDARY_TERM_HERE\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[self JSONHeaders]];
    [body appendData:[self JSONContent: initiator]];
    [body appendData:[@"--BOUNDARY_TERM_HERE\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[self binaryAudioHeaders]];
    return body;
}

+(NSData *)endData{
    return [@"--BOUNDARY_TERM_HERE--\r\n" dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSArray<NSDictionary *> *)splitData:(NSData *)data withBoundary:(NSString *)contentType {
    NSString *boundary = [[self matchesInString:contentType withRegExpPattern:@"boundary=(.*?);"] objectAtIndex:1];
    if (!boundary) {
        return nil;
    }
    NSData *head_boundaryData = [[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *inner_boundaryData = [[NSString stringWithFormat:@"\r\n--%@", boundary] dataUsingEncoding:NSUTF8StringEncoding];

    NSData *blankLineData = [@"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableArray *dictArr = [NSMutableArray array];
    
    NSUInteger curIdx = 0;
    while (curIdx < data.length) {
        NSRange head_boundaryRange = [data rangeOfData:head_boundaryData
                                               options:kNilOptions
                                                 range:NSMakeRange(curIdx, data.length-curIdx)];
        if (head_boundaryRange.length == 0) { break; }
        if (curIdx == 0 && head_boundaryRange.location != 0) {
            curIdx = 0;
        }else{
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
        if (inner_boundaryRange.length == 0) { break; }
        NSData *contentData = [data subdataWithRange:NSMakeRange(curIdx, inner_boundaryRange.location-curIdx)];
        
        [dictArr addObject: @{@"header": headerData, @"content": contentData}];
        
        curIdx = inner_boundaryRange.location;
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
    NSMutableDictionary *dic = [NSMutableDictionary new];
    [dic setObject:directives forKey:@"directives"];
    NSArray *dictArr = [self splitData:data withBoundary:contentType];
    for (NSDictionary *dict in dictArr) {
        NSString *header = [[NSString alloc] initWithData:dict[@"header"] encoding:NSUTF8StringEncoding];
        if ([header containsString:kContentTypeJSON]) {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:dict[@"content"] options:kNilOptions error:NULL];
            if(dic[@"directive"]){
                [directives addObject:dic[@"directive"]];
            }
        } else if ([header containsString:kContentTypeAudio]) {
            [dic setObject:dict[@"content"] forKey:@"speechData"];
        } else {
            NSLog(@"⚠️Unknown Content-Type: %@", header);
        }
    }
    
    
    return [TYAVSDataModel yy_modelWithDictionary:dic];
}

@end
