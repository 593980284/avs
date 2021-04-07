//
//  TYAVSUploader.m
//  Pods
//
//  Created by huchao on 2021/3/19.
//

#import "TYAVSUploader.h"
#import "AudioManager.h"
#import "RecordTool.h"
static NSString * const kEventsURL2 = @"https://avs-alexa-na.amazon.com/v20160207/events";
static NSString * const kDirectivesURL2 = @"https://avs-alexa-na.amazon.com/v20160207/directives";


#define kStreamBufferSize 1024

@interface TYAVSUploader()<NSURLSessionTaskDelegate, NSStreamDelegate>
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSInputStream *bodyStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) NSMutableData *formData;
@property (nonatomic, strong) NSMutableData *reslutData;
@property (nonatomic, strong) NSData *emptyData;
@property (nonatomic, assign) BOOL isLs;
@property (nonatomic, copy) NSString* token;
@end


@implementation TYAVSUploader
{
    NSInteger byteIndex;
}
-(instancetype)initWithDevId:(NSString *)devId
                       token:(NSString *)token{
    if (self = [super init]) {
        NSURLSessionConfiguration *config = NSURLSessionConfiguration.defaultSessionConfiguration;
        config.HTTPMaximumConnectionsPerHost = 1;
        config.timeoutIntervalForRequest = 60.0*60;
        config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        config.URLCache = nil;
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue new]];
        _formData = [NSMutableData new];
        
        NSMutableData *empty = [[NSMutableData alloc]initWithCapacity:320];
        char byte_chars[1] = {'\0'};
        if (empty.length < 320) {
            do {
                [empty appendBytes:byte_chars length:1];
            } while (empty.length < 320);
        }
        _emptyData = empty;
        
        _devId = devId;
        _token = token;
        
        [self downchannelStream];
    }
    return self;
}


-(instancetype)init{
    NSAssert(0, @"请使用initWithDevId: token:初始化");
    return nil;
}

-(void)setupConversation{
    byteIndex = 0;
    _formData = [NSMutableData new];
    _reslutData = [NSMutableData new];
    _isLs = YES;
    [_formData appendData:[TYAVSDataUtil beginData:nil]];
    // 创建上传任务
    NSURL *url = [NSURL URLWithString:kEventsURL2];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"multipart/form-data; boundary=BOUNDARY_TERM_HERE" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", _token] forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionUploadTask *uploadTask = [self.session uploadTaskWithStreamedRequest:request];
    [uploadTask resume];
    //创建流
    NSInputStream *inputStream = nil;
    NSOutputStream *outputStream = nil;
    [NSStream getBoundStreamsWithBufferSize:kStreamBufferSize inputStream:&inputStream outputStream:&outputStream];
    self.outputStream = outputStream;
    self.bodyStream = inputStream;
    self.outputStream.delegate = self;
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream open];
    
}

-(void)downchannelStream{
    
    NSURL *url = [NSURL URLWithString:kDirectivesURL2];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    [request setValue:[NSString stringWithFormat:@"Bearer %@", _token] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *downloadTask = [self.session dataTaskWithRequest:request];
    [downloadTask resume];
    
}



-(void)appendData:(NSData *)data{
    if (!_isLs) {
        return;
    }
    if ( [data isEqualToData:_emptyData]) {
        NSLog(@"无数据");
    }else{
        [_formData appendData:data];
    }
  
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
 needNewBodyStream:(void (^)(NSInputStream * _Nullable bodyStream))completionHandler{
    completionHandler(self.bodyStream);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    completionHandler(NSURLSessionResponseAllow);
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    
    NSString* url = [dataTask.originalRequest.URL absoluteString];
    
    if ([dataTask isKindOfClass:[NSURLSessionUploadTask class]]) {
        NSLog(@"NSURLSessionUploadTask");
        [_reslutData appendData:data];
    }
    
    if ([url isEqualToString:kDirectivesURL2]) {
        NSHTTPURLResponse *res = (NSHTTPURLResponse *)dataTask.response;
        NSString *contentType = res.allHeaderFields[@"Content-Type"];
        TYAVSDataModel* avsDataModel = [TYAVSDataUtil parseWithData:data withBoundary:contentType];
        [avsDataModel.directives enumerateObjectsUsingBlock:^(TYAVSDirectivesModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([obj.name isEqualToString:@"StopCapture"]){
                [_formData appendData:[TYAVSDataUtil endData]];
                self.isLs = NO;
                *stop = YES;
            }
        }];
        
        if (avsDataModel.directives.count &&
            [self.delegate respondsToSelector:@selector(avsUploader:directives:)]) {
            [self.delegate avsUploader:self directives:avsDataModel.directives];
        }
    }
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error{
    if (!error && _reslutData.length > 0) {
        NSHTTPURLResponse *res = (NSHTTPURLResponse *)task.response;
        NSString *contentType = res.allHeaderFields[@"Content-Type"];
        TYAVSDataModel* avsDataModel = [TYAVSDataUtil parseWithData:_reslutData withBoundary:contentType];
        if (avsDataModel.speechData) {
            if ([self.delegate respondsToSelector:@selector(avsUploader:speechData:)]) {
                [self.delegate avsUploader:self speechData:avsDataModel.speechData];
            }
        }
        if (avsDataModel.directives.count &&
            [self.delegate respondsToSelector:@selector(avsUploader:directives:)]) {
            [self.delegate avsUploader:self directives:avsDataModel.directives];
        }
    }else{
        if ([self.delegate respondsToSelector:@selector(avsUploader:error:)]) {
            [self.delegate avsUploader:self error:error];
        }
    }
}


- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    
    switch (eventCode) {
        case NSStreamEventNone:
            NSLog(@"NSStreamEventNone");
            break;
            
        case NSStreamEventOpenCompleted:
            NSLog(@"NSStreamEventOpenCompleted");
            break;
            
        case NSStreamEventHasBytesAvailable: {
            NSLog(@"NSStreamEventHasBytesAvailable");
        } break;
            
        case NSStreamEventHasSpaceAvailable: {
            if (aStream == self.outputStream) {
                
                NSUInteger data_len = [_formData length];
                NSUInteger remain_len = data_len - byteIndex;
                NSInteger len = MIN(remain_len, kStreamBufferSize);
                
                while (len == 0) {
                    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
                    data_len = [_formData length];
                    remain_len = data_len - byteIndex;
                    len = MIN(remain_len, kStreamBufferSize);
                }
                
                uint8_t *readBytes = (uint8_t *)[_formData mutableBytes];
                readBytes += byteIndex;
                uint8_t buf[len];
                (void)memcpy(buf, readBytes, len);
                
                len = [self.outputStream write:(const uint8_t *)buf maxLength:len];
                
                byteIndex += len;
            }
            
        } break;
            
        case NSStreamEventErrorOccurred:
        case NSStreamEventEndEncountered:
            [aStream close];
            aStream.delegate = nil;
            break;
            
        default:
            break;
    }
}
@end
