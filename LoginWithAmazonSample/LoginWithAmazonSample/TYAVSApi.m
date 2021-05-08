//
//  TYAVSApi.m
//  LoginWithAmazonSample
//
//  Created by huchao on 2021/4/9.
//  Copyright © 2021 Amazon. All rights reserved.
//

#import "TYAVSApi.h"

#define kEventsURL        @"https://avs-alexa-na.amazon.com/v20160207/events"
#define kDirectivesURL    @"https://avs-alexa-na.amazon.com/v20160207/directives"
#define kPingURL          @"https://avs-alexa-na.amazon.com/ping"
#define kCapabilitiesURL  @"https://api.amazonalexa.com/v1/devices/@self/capabilities"

#define kKeepAliveTimeoutInterval 3600
#define kRequesttimeoutInterval 30

@interface TYAVSApiDelegate : NSObject
@property (nonatomic, copy)TYAVSSuccessBlock successBlock;
@property (nonatomic, copy)TYAVSFailureBlock failureBlock;
//@property (nonatomic, copy)TYAVSReceiveDataHandler receiveDataHandle;
@property (nonatomic, copy)TYAVSDataModelBlock successModelBlock;
@property (nonatomic, copy)TYAVSDataModelBlock receiveModelBlock;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSInputStream *inputStream;
@end

@implementation TYAVSApiDelegate
-(NSMutableData *)data{
    if (!_data) {
        _data = [NSMutableData new];
    }
    return _data;
}
@end

@interface TYAVSApi()<NSURLSessionTaskDelegate>
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMutableDictionary<NSURLSessionTask*, TYAVSApiDelegate*> *avsApiDelegateDic;
@end

static TYAVSApi *_tyAVSApi;

@implementation TYAVSApi

+(TYAVSApi *)share {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _tyAVSApi = [[super alloc] init];
        
    });
    return _tyAVSApi;
}

-(instancetype)init{
    if (self = [super init]) {
        NSURLSessionConfiguration *config = NSURLSessionConfiguration.defaultSessionConfiguration;
        config.HTTPMaximumConnectionsPerHost = 1;
        config.timeoutIntervalForRequest = kRequesttimeoutInterval;
        config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        config.URLCache = nil;
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue new]];
        _avsApiDelegateDic = [NSMutableDictionary new];
    }
    return self;
}

-(NSURLSessionUploadTask *)uploadSpeechWithToken:(NSString*)token
                                          stream:(NSInputStream *)inputStream
                                         success:(TYAVSDataModelBlock)successModelBlock
                                         failure:(TYAVSFailureBlock)failureBlock{
    NSURL *url = [NSURL URLWithString:kEventsURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = kKeepAliveTimeoutInterval;
    [request setValue:@"multipart/form-data; boundary=BOUNDARY_TERM_HERE" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionUploadTask *uploadTask = [self.session uploadTaskWithStreamedRequest:request];
    
    TYAVSApiDelegate *delegate = [TYAVSApiDelegate new];
    delegate.inputStream = inputStream;
    delegate.failureBlock = failureBlock;
    delegate.successModelBlock = successModelBlock;
    [self addDelegate:delegate withTask:uploadTask];
    
    [uploadTask resume];
    
    return uploadTask;
}


-(NSURLSessionDataTask *)setUpDownChannelWithToken:(NSString*)token
                                       receiveData:(TYAVSDataModelBlock)receiveDataHandle
                                           success:(TYAVSDataModelBlock)successBlock
                                           failure:(TYAVSFailureBlock)failureBlock{
    NSURL *url = [NSURL URLWithString:kDirectivesURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = kKeepAliveTimeoutInterval;
    [request setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request];
    
    TYAVSApiDelegate *delegate = [TYAVSApiDelegate new];
    delegate.receiveModelBlock = receiveDataHandle;
    delegate.failureBlock = failureBlock;
    delegate.successModelBlock = successBlock;
    [self addDelegate:delegate withTask:dataTask];
    
    [dataTask resume];
    
    return dataTask;
}

-(NSURLSessionDataTask *)pingWithToken:(NSString*)token
                               success:(TYAVSSuccessBlock)successBlock
                               failure:(TYAVSFailureBlock)failureBlock{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kPingURL]];
    request.HTTPMethod = @"GET";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *task = [self request:request body:nil success:successBlock failure:failureBlock];
    return task;
}

-(NSURLSessionDataTask *)sendEventWithToken:(NSString*)token
                                  event:(NSDictionary*)event
                               success:(TYAVSSuccessBlock)successBlock
                                        failure:(TYAVSFailureBlock)failureBlock{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kEventsURL]];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *task = [self request:request body:event success:successBlock failure:failureBlock];
    return task;
}

-(NSURLSessionDataTask *)capabilitiesWithToken:(NSString*)token
                                       success:(TYAVSSuccessBlock)successBlock
                                       failure:(TYAVSFailureBlock)failureBlock{
    NSDictionary* capabilities = @{
        @"envelopeVersion": @"20160207",
        @"capabilities": @[@{@"type": @"AlexaInterface",
                             @"interface": @"SpeechRecognizer",
                             @"version": @"2.3"},
                           @{@"type": @"AlexaInterface",
                             @"interface": @"SpeechSynthesizer",
                             @"version": @"1.3"}
        ]};
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kCapabilitiesURL]];
    request.HTTPMethod = @"PUT";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *task = [self request:request body:capabilities success:successBlock failure:failureBlock];
    return task;
    
}

-(NSURLSessionDataTask *)request:(NSMutableURLRequest *)request
                            body:(NSDictionary *)body
                         success:(TYAVSSuccessBlock)successBlock
                         failure:(TYAVSFailureBlock)failureBlock{
    if (body) {
        NSData *bodyData = [NSJSONSerialization dataWithJSONObject:body options:NSJSONWritingPrettyPrinted error:nil];
        if (bodyData.length > 0) {
            [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)bodyData.length] forHTTPHeaderField:@"Content-Length"];
            [request setHTTPBody:bodyData];
        }
    }
    
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request];
    TYAVSApiDelegate *delegate = [TYAVSApiDelegate new];
    delegate.failureBlock = failureBlock;
    delegate.successBlock = successBlock;
    [self addDelegate:delegate withTask:dataTask];
    
    [dataTask resume];
    
    return dataTask;
}


-(void)addDelegate:(TYAVSApiDelegate *)delegate withTask:(NSURLSessionTask*)task{
    [self.avsApiDelegateDic setObject:delegate forKey:task];
}



#pragma NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
 needNewBodyStream:(void (^)(NSInputStream * _Nullable bodyStream))completionHandler{
    completionHandler(self.avsApiDelegateDic[task].inputStream);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
//    NSHTTPURLResponse *res = (NSHTTPURLResponse *)dataTask.response;
//    if (res.statusCode>=200 && res.statusCode < 400) {
        completionHandler(NSURLSessionResponseAllow);
//    }else{
//        completionHandler(NSURLSessionResponseCancel);
//    }
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    TYAVSApiDelegate *apiDelgate = self.avsApiDelegateDic[dataTask];
    //    TYAVSReceiveDataHandler receiveDataHandle = apiDelgate.receiveDataHandle;
    TYAVSDataModelBlock receiveModelBlock = apiDelgate.receiveModelBlock;
    
    NSHTTPURLResponse *res = (NSHTTPURLResponse *)dataTask.response;
    NSInteger code = res.statusCode;
    NSLog(@"____code:%ld,%@",code,dataTask.currentRequest.URL);
    TYAVSDataModel *model = nil;
    if(code == 200){
        NSString *contentType = res.allHeaderFields[@"Content-Type"];
        [apiDelgate.data appendData:data];
        if (receiveModelBlock) {
            model = [TYAVSDataUtil parseWithData:data withBoundary:contentType];
            dispatch_async(dispatch_get_main_queue(), ^{
                receiveModelBlock(res,model);
            });
        }
        
    }
    

    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error{
    TYAVSApiDelegate *apiDelgate = self.avsApiDelegateDic[task];
    TYAVSSuccessBlock successBlock = apiDelgate.successBlock;
    TYAVSFailureBlock failureBlock = apiDelgate.failureBlock;
    TYAVSDataModelBlock successModelBlock = apiDelgate.successModelBlock;
    NSHTTPURLResponse *res = (NSHTTPURLResponse *)task.response;
    NSInteger code = res.statusCode;
    NSLog(@"____code:%ld,%@",code,task.currentRequest.URL);
    
    if (code == 200 || code == 204) {
        if (successBlock) {
            NSDictionary* dataDic = [NSJSONSerialization JSONObjectWithData:[apiDelgate.data copy] options:0 error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(task.response, dataDic);
            });
        }
        
        if (successModelBlock) {
            NSString *contentType = res.allHeaderFields[@"Content-Type"];
            TYAVSDataModel *model = [TYAVSDataUtil parseWithData:[apiDelgate.data copy] withBoundary:contentType];
            dispatch_async(dispatch_get_main_queue(), ^{
                successModelBlock(res,model);
            });
        }
    }else{
        if (!error) {
            error = [[NSError alloc]initWithDomain:@"TYAVSApi" code:code userInfo:nil];
        }
        if (failureBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(task.response, error);
            });
        }
    }
    
    [self.avsApiDelegateDic removeObjectForKey:task];
}

@end
