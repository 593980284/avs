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

@interface TYAVSUploader()<NSStreamDelegate>

@property (nonatomic, strong) NSURLSessionUploadTask *uploadTask;
@property (nonatomic, strong) NSURLSessionDataTask* downChannelTask;

@property (nonatomic, copy) NSString* token;
@property (nonatomic, copy) NSDictionary *initiator;
@property (nonatomic, strong)NSDate *initiatorExpiredDate;
@property (nonatomic, strong) TYAVSUploadStreamManager *uploadStreamManager;
//要在下行通道可以用情况下，才能语音上传
@property (nonatomic, assign) BOOL isReady;
@property (nonatomic, strong) TYAVSAudioPlayer *audioPlayer;
@end


@implementation TYAVSUploader

-(instancetype)initWithDevId:(NSString *)devId{
    if (self = [super init]) {
        _devId = devId;
        _state = TYAVSDeviceStateIdle;
        _uploadStreamManager = [TYAVSUploadStreamManager new];
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
    
    [self.audioPlayer stop];
   
    //添加多次交互需要参数 initiator
    NSDictionary *initiator = nil;
    if (self.initiator) {
        initiator = [self.initiator copy];
    }
//    if (self.initiator &&
//        self.initiatorExpiredDate &&
//        self.initiatorExpiredDate.timeIntervalSinceNow >=0) {
//        initiator = [self.initiator copy];
//    }
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


-(void)handleSpeechData:(NSArray<NSData *> *)speechDatas directive:(NSArray<TYAVSDirectivesModel*> *)directives dialogRequestId:(NSString *)dialogRequestId{
    if ([self.delegate respondsToSelector:@selector(avsUploader:speechDatas:)]) {
        [self.delegate avsUploader:self speechDatas:speechDatas];
    }
    //如果是播放声音，就实际播放为speaking状态。如果是发送文字，speaking的持续时间，解析字幕里面的时长
    if(self.startSpeechModel.playVoice){
        if (speechDatas.count) {
            [self play:speechDatas dialogRequestId:dialogRequestId];
        }else{
            [self changeAVSDeviceState:TYAVSDeviceStateIdle dialogRequestId:dialogRequestId];
        }
       
    }else{
        __block NSInteger speak_duration = 0;
        [directives enumerateObjectsUsingBlock:^(TYAVSDirectivesModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.name isEqualToString:TYAVSDirectiveTypeSpeak]) {
                speak_duration += obj.speak_duration;
            }
        }];
        if (speak_duration) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(speak_duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self changeAVSDeviceState:TYAVSDeviceStateIdle dialogRequestId:dialogRequestId];
            });
        }else{
            [self changeAVSDeviceState:TYAVSDeviceStateIdle dialogRequestId:dialogRequestId];
        }
    }
    
    [self handleDirective:directives];

   
}

//处理指令数据
-(void)handleDirective:(NSArray<TYAVSDirectivesModel*> *)directives{
   
    //1.在发送状态
    [directives enumerateObjectsUsingBlock:^(TYAVSDirectivesModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *dialogRequestId = obj.dialogRequestId;
        if([obj.name isEqualToString:TYAVSDirectiveTypeStopCapture]) {
            if(self.state == TYAVSDeviceStateListening && self.uploadTask.state == NSURLSessionTaskStateRunning){
                [self changeAVSDeviceState:TYAVSDeviceStateProcessing dialogRequestId:dialogRequestId];
                [self.uploadStreamManager end];
            }
        }else if([obj.name isEqualToString:TYAVSDirectiveTypeExpectSpeech]) {
            self.initiator = [obj expectSpeech_initiator];
            self.initiatorExpiredDate = [NSDate dateWithTimeIntervalSinceNow:obj.expectSpeech_timeoutInMilliseconds/1000.0];
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
        
        if (self.startSpeechModel.audioFormat== 0 || self.startSpeechModel.audioFormat == 1){
           
        }else if(self.startSpeechModel.audioFormat== 2) {
            
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.uploadStreamManager appendAudioData:data];
        });
    }
    
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

-(void)sendSpeechStartedEvent{
    [[TYAVSApi share] sendEventWithToken:_token event:[TYAVSDataUtil Event_speechStartedWithToken:_token] success:^(NSURLResponse * _Nullable response, NSDictionary * _Nullable dataDic) {
            
        } failure:^(NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
    }];
}

-(void)sendSpeechFinishedEvent{
    [[TYAVSApi share] sendEventWithToken:_token event:[TYAVSDataUtil Event_speechFinishedWithToken:_token] success:^(NSURLResponse * _Nullable response, NSDictionary * _Nullable dataDic) {
            
        } failure:^(NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
    }];
}

-(void)sendSpeechInterruptedEvent:(NSInteger) offsetInMilliseconds{
    [[TYAVSApi share] sendEventWithToken:_token event:[TYAVSDataUtil Event_speechInterruptedWithToken:_token offsetInMilliseconds:offsetInMilliseconds] success:^(NSURLResponse * _Nullable response, NSDictionary * _Nullable dataDic) {
            
        } failure:^(NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
    }];
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

-(void)dealloc{
   // [super dealloc];
    [self.uploadTask cancel];
    [self.downChannelTask cancel];
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

-(void)play:(NSArray<NSData *>*)datas dialogRequestId:(NSString *)dialogRequestId{
    __weak __typeof__(self) weakSelf = self;
//    [self sendSpeechStartedEvent];
    [self changeAVSDeviceState:TYAVSDeviceStateSpeaking dialogRequestId:dialogRequestId];
    [self.audioPlayer playAudioDatas:datas completionHandler:^(BOOL successfully, NSInteger offsetInMilliseconds) {
        [weakSelf changeAVSDeviceState:TYAVSDeviceStateIdle dialogRequestId:dialogRequestId];
//        if (successfully) {
//            [weakSelf sendSpeechFinishedEvent];
//        }else{
//            [weakSelf sendSpeechInterruptedEvent:offsetInMilliseconds];
//        }
    }];
}

-(TYAVSAudioPlayer *)audioPlayer{
    if (!_audioPlayer) {
        _audioPlayer = [TYAVSAudioPlayer new];
    }
    return _audioPlayer;
}

@end
