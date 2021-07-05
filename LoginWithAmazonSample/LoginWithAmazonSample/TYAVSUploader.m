//
//  TYAVSUploader.m
//  Pods
//
//  Created by huchao on 2021/3/19.
//

#import "TYAVSUploader.h"
#import "TYAVSApi.h"
#import <AVKit/AVKit.h>
#import "TYAVSUploadStreamManager.h"
#import "TYAVSAudioPlayer.h"
#import "TYOpusCodec.h"

@interface TYAVSUploader()<NSStreamDelegate>

@property (nonatomic, strong) NSURLSessionUploadTask *uploadTask;
@property (nonatomic, strong) NSURLSessionDataTask* downChannelTask;

@property (nonatomic, copy) NSString* token;
@property (nonatomic, copy) NSDictionary *initiator;
@property (nonatomic, assign)double expectTimeOutnterval;
@property (nonatomic, strong) TYAVSUploadStreamManager *uploadStreamManager;
//要在下行通道可以用情况下，才能语音上传
@property (nonatomic, assign) BOOL isReady;
@property (nonatomic, strong) TYAVSAudioPlayer *audioPlayer;
@property (nonatomic, strong) TYOpusCodec *opusCodec32;
@property (nonatomic, strong) NSTimer *expectTimeOutTimer;
@end


@implementation TYAVSUploader

-(instancetype)initWithDevId:(NSString *)devId{
    if (self = [super init]) {
        _devId = devId;
        _state = TYAVSDeviceStateIdle;
        _uploadStreamManager = [TYAVSUploadStreamManager new];
        _opusCodec32 = [TYOpusCodec avsOpusCodec_32bitRate];
    }
    return self;
}
-(void)setAlexaAuthToken:(NSString *)token complete:(void(^)(BOOL success)) complete{
    if (!token || token.length == 0) {
        complete(self.isReady);
        return;
    }
    if ([_token isEqualToString:token] && self.isReady) {
        if (complete) {
            complete(YES);
        }
        return;
    }
    _token = token;
    self.isReady = NO;
    
    __block typeof(complete) blockComplete = complete;
    __weak __typeof__(self) weakSelf = self;
    [self downChannelStreamWithConnectionComplete:^(BOOL success) {
        weakSelf.isReady = success;
        if (blockComplete) {
            blockComplete(success);
            blockComplete = nil;
        }
    }];
    [self capabilities];
}

-(instancetype)init{
    NSAssert(0, @"请使用initWithDevId: token:初始化");
    return nil;
}

#pragma 上传语音
-(BOOL)startSpeech:(TYAVSUploaderStartSpeechModel*)startSpeechModel{
    if (self.state == TYAVSDeviceStateListening ||
        self.state == TYAVSDeviceStateProcessing) {
        return NO;
    }
    if (!self.isReady) {
        return NO;
    }
    if (self.state == TYAVSDeviceStateSpeaking) {
        return NO;
       // [self stopSpeaking];
    }
//
    if (self.state == TYAVSDeviceStateExpect) {
        [self.expectTimeOutTimer invalidate];
    }
    
    //添加多次交互需要参数 initiator
    NSDictionary *initiator = nil;
    if (self.initiator) {
        initiator = [self.initiator copy];
    }
    self.initiator = nil;
    NSString *dialogRequestId = startSpeechModel.dialogId;
    _startSpeechModel = startSpeechModel;
    [_uploadStreamManager beginWithInitiator:initiator startSpeechModel:startSpeechModel];
    
    __weak __typeof__(self) weakSelf = self;
    _uploadTask = [[TYAVSApi share] uploadSpeechWithToken:_token stream:_uploadStreamManager.inputStream
                                                  success:^(NSHTTPURLResponse * _Nullable response,TYAVSDataModel * _Nonnull dataModel) {
        [weakSelf handleSpeechData:dataModel.speechDatas directive:dataModel.directives dialogRequestId:dialogRequestId];
    } failure:^(NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [weakSelf palyErrorAlexaEarcon];
        if ([weakSelf.delegate respondsToSelector:@selector(avsUploader:dialogRequestId:error:)]) {
            [weakSelf.delegate avsUploader:weakSelf dialogRequestId:dialogRequestId error:error];
        }
        [weakSelf changeAVSDeviceState:TYAVSDeviceStateIdle dialogRequestId:dialogRequestId];
    }];
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self changeAVSDeviceState:TYAVSDeviceStateListening dialogRequestId:dialogRequestId];
    });
    
    
  
    return YES;
    
}

#pragma 建立下行通道
//建立下行通道，回调连接状态
-(void)downChannelStreamWithConnectionComplete:(void(^)(BOOL success)) connectionComplete{
    __weak __typeof__(self) weakSelf = self;
    [self.downChannelTask cancel];
    self.downChannelTask = [[TYAVSApi share]  setUpDownChannelWithToken:_token receiveData:^(NSHTTPURLResponse * _Nullable response,TYAVSDataModel * _Nonnull dataModel) {
        BOOL isReady = response.statusCode == 200 || response.statusCode == 204;
        if (connectionComplete) {
            connectionComplete(isReady);
        }
        [weakSelf handleDirective:dataModel.directives];
    } success:^(NSHTTPURLResponse * _Nullable response,TYAVSDataModel * _Nonnull dataModel) {
        if (connectionComplete) {
            connectionComplete(NO);//get请求已经结束
        }
    } failure:^(NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (connectionComplete) {
            connectionComplete(NO);//get请求已经结束
        }
    }];
}

#pragma 每5分钟ping一下
-(void)ping{
    [[TYAVSApi share] pingWithToken:_token success:^(NSURLResponse * _Nullable response, NSDictionary * _Nullable dataDic) {
        NSLog(@"ping-%@",dataDic);
    } failure:^(NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
    }];
}

-(void)capabilities{
    [[TYAVSApi share] capabilitiesWithToken:_token success:^(NSURLResponse * _Nullable response, NSDictionary * _Nullable dataDic) {
        NSLog(@"capabilities:%@",dataDic);
    } failure:^(NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
    }];
}


-(void)handleSpeechData:(NSArray<NSData *> *)speechDatas directive:(NSArray<TYAVSDirectivesModel*> *)directives dialogRequestId:(NSString *)dialogRequestId{
    if ([self.delegate respondsToSelector:@selector(avsUploader:speechDatas:)]) {
        [self.delegate avsUploader:self speechDatas:speechDatas];
    }
   
    [self speakWithSpeechData:speechDatas directive:directives dialogRequestId:dialogRequestId];

    [self handleDirective:directives];
}

//处理指令数据
-(void)handleDirective:(NSArray<TYAVSDirectivesModel*> *)directives{
   
    //1.在发送状态
    [directives enumerateObjectsUsingBlock:^(TYAVSDirectivesModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *dialogRequestId = obj.dialogRequestId;
        NSString *directiveType = obj.name;
        NSDictionary *payload = obj.payload;
        if([directiveType isEqualToString:TYAVSDirectiveTypeStopCapture]) {
            if(self.state == TYAVSDeviceStateListening && self.uploadTask.state == NSURLSessionTaskStateRunning){
                [self changeAVSDeviceState:TYAVSDeviceStateProcessing dialogRequestId:dialogRequestId];
                [self.uploadStreamManager end];
            }
        }else if([directiveType isEqualToString:TYAVSDirectiveTypeExpectSpeech]) {
            self.initiator = [obj expectSpeech_initiator];
            self.expectTimeOutnterval = obj.expectSpeech_timeoutInMilliseconds/1000.0;
        }else if([directiveType isEqualToString:TYAVSDirectiveTypeSettingsUpdated]) {
            if (!payload) {
                return;
            }
            [self sendSettingEvent:payload];
        }
    }];
    
    //2。发送指令
     if (directives.count &&
         [self.delegate respondsToSelector:@selector(avsUploader:directives:)]) {
         [self.delegate avsUploader:self directives:directives];
     }
 
}

-(void)appendData:(NSData *)data{
    if (_state != TYAVSDeviceStateListening) {
        NSLog(@"非Listening状态下，不录入数据");
        return;
    }
    if (!data.length) {
        NSLog(@"无数据");
    }else{
        //pcm 和 20ms 32比特率 opus不用处理，alexa可以直接识别
        if (self.startSpeechModel.audioFormat== 0){
            
        }else if(self.startSpeechModel.audioFormat == 1){
            
          //  data = [self coverToOpus32:data frameSize:80];
            
        }else if(self.startSpeechModel.audioFormat== 2) {
            
            data = [self coverToOpus32:data frameSize:40];
            
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.uploadStreamManager appendAudioData:data];
        });
    }
    
}

-(NSData *)coverToOpus32:(NSData *)source frameSize:(NSInteger)frameSize{
  
//    if (source.length%frameSize != 0) {
//        NSAssert1(0, @"data.length：%ld,数据必须是帧的倍数",source.length);
//        return nil;
//    }
    //20ms 16比特率 opus 需要转化为32比特率
    NSMutableData * opus32Data = [NSMutableData new];
   
    NSInteger index = 0;
    //按帧进行转化
    while (index < source.length){
        NSData *frameData = [source subdataWithRange:NSMakeRange(index, frameSize)];
        NSData *pcm = [self.opusCodec32 decodeOpusData:frameData pcmDataFrameSize:640];
        if (!pcm) {
            NSLog(@"解码失败%ld",index);
        }
        NSData *opus32FrameData = [self.opusCodec32 encodeMonoPCMData:pcm];
        [opus32Data appendData:opus32FrameData];
        index += frameSize;
    };
    return opus32Data.copy;
}

-(void)changeAVSDeviceState:(TYAVSDeviceState)state dialogRequestId:(NSString*)dialogRequestId{
    if (_state == state) {
        return;
    }
    _state = state;
    
    if (_state == TYAVSDeviceStateListening ) {
        [self palyBeginAlexaEarcon];
    }
    if ( _state == TYAVSDeviceStateProcessing) {
        [self palyEndAlexaEarcon];
    }
    if ([self.delegate respondsToSelector:@selector(avsUploader:dialogRequestId:state:)]) {
        [self.delegate avsUploader:self dialogRequestId:dialogRequestId state:state];
    }
    
}


-(void)endSpeakingAndStartExpectWithDialogRequestId:(NSString*)dialogRequestId{
    if (self.expectTimeOutnterval && self.initiator) {
        [self changeAVSDeviceState:TYAVSDeviceStateExpect dialogRequestId:dialogRequestId];
        __weak __typeof__(self) weakSelf = self;
        self.expectTimeOutTimer = [NSTimer scheduledTimerWithTimeInterval:_expectTimeOutnterval repeats:NO block:^(NSTimer * _Nonnull timer) {
            [timer invalidate];
            weakSelf.expectTimeOutnterval = 0;
            weakSelf.initiator = nil;
            [weakSelf changeAVSDeviceState:TYAVSDeviceStateIdle dialogRequestId:dialogRequestId];
        }];
    }else{
        [self changeAVSDeviceState:TYAVSDeviceStateIdle dialogRequestId:dialogRequestId];
    }
}

-(void)stopExpect{
    [self.expectTimeOutTimer invalidate];
}

-(void)sendSpeechStartedEvent:(NSString *)speakToken{
    [self sendEvent:[TYAVSDataUtil Event_speechStartedWithToken:speakToken]];
}

-(void)sendSpeechFinishedEvent:(NSString *)speakToken{
    [self sendEvent:[TYAVSDataUtil Event_speechFinishedWithToken:speakToken]];
}
-(void)sendSpeechInterruptedEvent:(NSString *)speakToken offsetInMilliseconds:(NSInteger) offsetInMilliseconds{
    [self sendEvent:[TYAVSDataUtil Event_speechInterruptedWithToken:speakToken offsetInMilliseconds:offsetInMilliseconds]];
}

-(void)sendSettingEvent:(NSDictionary *)payload{
    [self sendEvent:[TYAVSDataUtil Event_SettingWithPayload:payload]];
}

-(void)sendEvent:(NSData *)event{
    [[TYAVSApi share] sendEventWithToken:_token event:event success:^(NSURLResponse * _Nullable response, NSDictionary * _Nullable dataDic) {
        NSLog(@"send evnet:%@",[[NSString alloc] initWithData:event encoding:NSUTF8StringEncoding]);
    } failure:^(NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"send evnet error:%@",[[NSString alloc] initWithData:event encoding:NSUTF8StringEncoding]);
    }];
}



-(void)palyBeginAlexaEarcon{
    if (!self.startSpeechModel.suppressEarcon){
        [self.audioPlayer palyBeginAlexaEarcon];
    }
}

-(void)palyEndAlexaEarcon{
    if (!self.startSpeechModel.suppressEarcon){
        [self.audioPlayer palyEndAlexaEarcon];
    }
}

-(void)palyErrorAlexaEarcon{
    if (!self.startSpeechModel.suppressEarcon){
        [self.audioPlayer palyErrorAlexaEarcon];
    }
}

-(void)speakWithSpeechData:(NSArray<NSData *> *)speechDatas directive:(NSArray<TYAVSDirectivesModel*> *)directives dialogRequestId:(NSString *)dialogRequestId{
    if (self.audioPlayer.isPlay) {
        return;
    }
    
    NSMutableArray *speaks = [NSMutableArray new];
    [directives enumerateObjectsUsingBlock:^(TYAVSDirectivesModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.name isEqualToString:TYAVSDirectiveTypeSpeak]) {
            [speaks addObject:obj];
        }
    }];
    
//    if (speechDatas.count !=  speaks.count) {
//        NSAssert(0, @"speak 指令数量和 语音数量没有对应");
//        [self changeAVSDeviceState:TYAVSDeviceStateIdle dialogRequestId:dialogRequestId];
//        return;
//    }
    
    if (!speaks.count) {
        [self changeAVSDeviceState:TYAVSDeviceStateIdle dialogRequestId:dialogRequestId];
        return;
    }
    [self changeAVSDeviceState:TYAVSDeviceStateSpeaking dialogRequestId:dialogRequestId];
    __weak __typeof__(self) weakSelf = self;
    [self.audioPlayer speakWithDirectives:speaks speechDatas:speechDatas startSpeakBlock:^(TYAVSDirectivesModel * _Nonnull directive) {
        NSString*speakToken = directive.payload[@"token"];
        if (!speakToken) {
            return;
        }
        [weakSelf sendSpeechStartedEvent:speakToken];
        NSLog(@"startSpeakBlock_%@",directive.speak_content);
    } endSpeakBlock:^(BOOL successfully, TYAVSDirectivesModel * _Nonnull directive, NSInteger offsetInMilliseconds) {
        NSString*speakToken = directive.payload[@"token"];
        if (!speakToken) {
            return;
        }
        if (successfully) {
            [weakSelf sendSpeechFinishedEvent:speakToken];
        }else{
            [weakSelf sendSpeechInterruptedEvent:speakToken offsetInMilliseconds:offsetInMilliseconds];
        }
        NSLog(@"endSpeakBlock%@",directive.speak_content);
    } completionHandler:^{
        NSLog(@"completionHandler");
        [weakSelf endSpeakingAndStartExpectWithDialogRequestId:dialogRequestId];
    }];
}

-(TYAVSAudioPlayer *)audioPlayer{
    if (!_audioPlayer) {
        _audioPlayer = [TYAVSAudioPlayer new];
    }
    return _audioPlayer;
}


-(void)dealloc{
    [self.expectTimeOutTimer invalidate];
    [self.uploadTask cancel];
    [self.downChannelTask cancel];
}

@end
