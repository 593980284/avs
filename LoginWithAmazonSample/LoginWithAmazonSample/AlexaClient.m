//
//  AlexaClient.m
//  LoginWithAmazonSample
//
//  Created by huchao on 2021/3/23.
//  Copyright © 2021 Amazon. All rights reserved.
//

#import "AlexaClient.h"

//:method = POST
//:scheme = https
//:path = /{{API version}}/events
//authorization = Bearer {{YOUR_ACCESS_TOKEN}}
//content-type = multipart/form-data;  boundary={{BOUNDARY_TERM_HERE}}
static NSString * const kEventsURL = @"https://avs-alexa-na.amazon.com/v20160207/events";
NSString * const kContentTypeJSON = @"application/json";
NSString * const kContentTypeAudio = @"application/octet-stream";

@interface AlexaClient() <NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSession *session;

@end

static id client;

@implementation AlexaClient

+ (AlexaClient *)shareClient {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        client = [[super alloc] init];
    });
    return client;
}


- (instancetype)init {
    if (self = [super init]) {
        NSURLSessionConfiguration *config = NSURLSessionConfiguration.defaultSessionConfiguration;
        config.HTTPMaximumConnectionsPerHost = 1;
        config.timeoutIntervalForRequest = 30.0f;
        config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        config.URLCache = nil;
        self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    return self;
}

- (NSData *)JSONHeaders {
    NSMutableData *mutdata = [NSMutableData data];
    [mutdata appendData: [@"Content-Disposition: form-data; name=\"metadata\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [mutdata appendData: [@"Content-Type: application/json; charset=UTF-8\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [mutdata appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    return mutdata;
}

- (NSData *)JSONContent {
    NSString *content = @"{\"context\": [{\"header\": {\"namespace\": \"SpeechRecognizer\", \"name\": \"RecognizerState\"}, \"payload\": {\"wakeword\": \"ALEXA\"} } ], \"event\": {\"header\": {\"namespace\": \"SpeechRecognizer\", \"name\": \"Recognize\", \"messageId\": \"$messageId\", \"dialogRequestId\": \"$dialogRequestId\"}, \"payload\": {\"profile\": \"NEAR_FIELD\", \"format\": \"AUDIO_L16_RATE_16000_CHANNELS_1\"} } }";
    
    //{\"header\": {\"namespace\": \"SpeechSynthesizer\", \"name\": \"SpeechState\"}, \"payload\": {\"token\": \"zxcv8523\", \"offsetInMilliseconds\": \"0\", \"playerActivity\": \"FINISHED\"} }
    /*
     {"context":
        [{"header":
            {"namespace": "SpeechRecognizer","name": "RecognizerState"},
          "payload":
             {"wakeword": "ALEXA"} }
        ],
     "event":
        {"header":
            {"namespace": "SpeechRecognizer", "name": "Recognize", "messageId": "$messageId", "dialogRequestId": "$dialogRequestId"},
         "payload": {"profile": "NEAR_FIELD", "format": "AUDIO_L16_RATE_16000_CHANNELS_1"}
        }
     }
     */
    content = [content stringByReplacingOccurrencesOfString:@"$messageId" withString: [NSUUID.UUID UUIDString]];
    content = [content stringByReplacingOccurrencesOfString:@"$dialogRequestId" withString: [NSUUID.UUID UUIDString]];
    
    NSMutableData *mutdata = [NSMutableData data];
    [mutdata appendData:[content dataUsingEncoding:NSUTF8StringEncoding]];
    [mutdata appendData:[@"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    return mutdata;
}

- (NSData *)binaryAudioHeaders {
    NSMutableData *mutdata = [NSMutableData data];
    [mutdata appendData: [@"Content-Disposition: form-data; name=\"audio\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [mutdata appendData: [@"Content-Type: application/octet-stream\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [mutdata appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    return mutdata;
}

- (NSData *)binaryAudioContent:(NSData *)data {
    NSMutableData *mutdata = [NSMutableData data];
    [mutdata appendData:data];
    [mutdata appendData:[@"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    return mutdata;
}

- (NSData *)eventBodyWithAudioData:(NSData *)audioData {
    NSMutableData *body = [NSMutableData data];
    [body appendData:[@"--BOUNDARY_TERM_HERE\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[self JSONHeaders]];
    [body appendData:[self JSONContent]];
    [body appendData:[@"--BOUNDARY_TERM_HERE\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[self binaryAudioHeaders]];
    [body appendData:[self binaryAudioContent: audioData]];
    [body appendData:[@"--BOUNDARY_TERM_HERE--\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    return body;
}

- (NSUInteger)skipContiguousNewlineCharacterInData:(NSData *)data withIndex:(NSUInteger)index {
    const char *bytes = data.bytes;
    NSUInteger newIdx = index;
    while (newIdx < data.length - 1) {
        if (bytes[newIdx] == 0x0D && bytes[newIdx + 1] == 0x0A) {
            newIdx += 2;
            while (bytes[newIdx] == 0x0D && bytes[newIdx + 1] == 0x0A) {
                newIdx += 2;
            }
            return newIdx;
        } else {
            newIdx++;
        }
    }
    return newIdx;
}

- (nullable NSArray<NSString *> *)matchesInString:(nonnull NSString *)string withRegExpPattern:(nonnull NSString *)regExp {
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


- (NSArray<NSDictionary *> *)splitData:(NSData *)data withBoundary:(NSString *)boundary {
    NSData *head_boundaryData = [[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *inner_boundaryData = [[NSString stringWithFormat:@"\r\n--%@", boundary] dataUsingEncoding:NSUTF8StringEncoding];
    //    NSData *tail_boundaryData = [[NSString stringWithFormat:@"\r\n--%@--", boundary] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *blankLineData = [@"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableArray *dictArr = [NSMutableArray array];
    
    NSUInteger curIdx = 0;
    while (curIdx < data.length) {
        NSRange head_boundaryRange = [data rangeOfData:head_boundaryData
                                               options:kNilOptions
                                                 range:NSMakeRange(curIdx, data.length-curIdx)];
        if (head_boundaryRange.length == 0) { break; }
        
        curIdx = NSMaxRange(head_boundaryRange);
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

- (NSArray *)parseDirectivesInData:(NSData *)data withBoundary:(NSString *)boundary {
    NSMutableArray *directives = [NSMutableArray array];
    
    NSArray *dictArr = [self splitData:data withBoundary:boundary];
    for (NSDictionary *dict in dictArr) {
        NSString *header = [[NSString alloc] initWithData:dict[@"header"] encoding:NSUTF8StringEncoding];
        if ([header containsString:kContentTypeJSON]) {
            NSJSONSerialization *contentJSON = [NSJSONSerialization JSONObjectWithData:dict[@"content"] options:kNilOptions error:nil];
            [directives addObject:@{@"type": kContentTypeJSON, @"content": contentJSON}];
        } else if ([header containsString:kContentTypeAudio]) {
            [directives addObject:@{@"type": kContentTypeAudio, @"content": dict[@"content"]}];
        } else {
            NSLog(@"⚠️Unknown Content-Type: %@", header);
        }
    }
    
    return directives.count > 0 ? directives : nil;
}


#pragma mark - Public Method

- (void)speechRecognize:(NSData *)audioData withCompleteHandler:(AlexaSpeechRecognizeHandler)handler {
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kEventsURL]];
    request.HTTPMethod = @"POST";
    [request setValue:@"multipart/form-data; boundary=BOUNDARY_TERM_HERE" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", _authorization.token] forHTTPHeaderField:@"Authorization"];
    
    NSData *body = [self eventBodyWithAudioData:audioData];
    NSLog(@"request %@",request);
    [[_session uploadTaskWithRequest:request fromData:body completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"recognizeSpeech: %@", response);
        NSLog(@"data: %@", [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]);
        NSLog(@"error: %@", error);
        NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
        if (res.statusCode == 200 || res.statusCode == 204) {
            NSString *contentType = res.allHeaderFields[@"Content-Type"];
            if (contentType != nil) {
                NSString *boundary = [[self matchesInString:contentType withRegExpPattern:@"boundary=(.*?);"] objectAtIndex:1];
                NSArray *directives = [self parseDirectivesInData:data withBoundary:boundary];
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSError *err = [NSError errorWithDomain:@"AlexaClient-SpeechRecognizer"
                                                       code:-1
                                                   userInfo:@{NSLocalizedDescriptionKey: @"Can't found any directive."}];
                    handler(directives, directives ? nil : err);
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSError *err = [NSError errorWithDomain:@"AlexaClient-SpeechRecognizer"
                                                       code:-2
                                                   userInfo:@{NSLocalizedDescriptionKey: @"Not found `Content-Type` field."}];
                    handler(nil, err);
                });
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *err = error ? error : [NSError errorWithDomain:@"AlexaClient-SpeechRecognizer"
                                                                   code:-3
                                                               userInfo:@{NSLocalizedDescriptionKey: response.description}];
                handler(nil, err);
            });
        }
    }] resume] ;
}

@end
