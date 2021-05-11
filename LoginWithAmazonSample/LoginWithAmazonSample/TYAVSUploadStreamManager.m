//
//  TYAVSUploadStream.m
//  TuyaAVSKit
//
//  Created by huchao on 2021/4/28.
//

#import "TYAVSUploadStreamManager.h"
#define kStreamBufferSize 1024
@interface TYAVSUploadStreamManager()<NSStreamDelegate>
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) NSMutableData *formData;
@property (nonatomic, assign) BOOL outputStreamSpaceAvailable;
@end

@implementation TYAVSUploadStreamManager
{
    NSInteger byteIndex;
}
-(void)beginWithInitiator:(NSDictionary *)initiator startSpeechModel:(TYAVSUploaderStartSpeechModel *)startSpeechModel{
    NSAssert([NSThread currentThread].isMainThread, @"请在主线程调用");
    byteIndex = 0;
    _outputStreamSpaceAvailable = NO;
    [self.outputStream close];
    _formData = [NSMutableData new];
    
    [_formData appendData:[TYAVSDataUtil beginData:initiator startSpeechModel:startSpeechModel]];
    
    //创建流
    NSInputStream *inputStream = nil;
    NSOutputStream *outputStream = nil;
    [NSStream getBoundStreamsWithBufferSize:kStreamBufferSize inputStream:&inputStream outputStream:&outputStream];
    self.outputStream = outputStream;
    self.outputStream.delegate = self;
    _inputStream = inputStream;
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream open];
}

-(void)appendAudioData:(NSData *)data{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.formData appendData:data];
        if (self.outputStreamSpaceAvailable) {
            [self writeToOutputStream];
        }
    });
}

-(void)end{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.formData appendData:[TYAVSDataUtil endData]];
        if (self.outputStreamSpaceAvailable) {
            [self writeToOutputStream];
        }
    });
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
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self writeToOutputStream];
                });
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

-(void)writeToOutputStream{
    if(!_formData){
        return;
    }
    NSInteger len = 0;
    NSUInteger data_len = [_formData length];
    NSUInteger remain_len = data_len - byteIndex;
    len = MIN(remain_len, kStreamBufferSize);
    if (!len) {
        self.outputStreamSpaceAvailable = YES;
        return;
    }
    uint8_t *readBytes = (uint8_t *)[_formData mutableBytes];
    readBytes += byteIndex;
    uint8_t buf[len];
    (void)memcpy(buf, readBytes, len);

    len = [self.outputStream write:(const uint8_t *)buf maxLength:len];
    byteIndex += len;
    NSLog(@"____数据写入流");
    self.outputStreamSpaceAvailable = NO;
}

-(void)dealloc{
    [self.outputStream close];
}

@end
