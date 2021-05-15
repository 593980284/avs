//
//  TYAVSAudioPlayer.m
//  TuyaAVSKit
//
//  Created by huchao on 2021/4/29.
//

#import "TYAVSAudioPlayer.h"
#import <AVKit/AVKit.h>
@interface TYAVSAudioPlayer()<AVAudioPlayerDelegate>
@property (nonatomic, strong) AVAudioPlayer *alexaBeginEarconPlay;
@property (nonatomic, strong) AVAudioPlayer *alexaEndEarconPlay;
@property (nonatomic, strong) AVAudioPlayer *alexaErrorEarconPlay;

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, assign) NSInteger offsetInMilliseconds;
@property (nonatomic, strong) NSMutableArray *audioDatas;
@property (nonatomic, strong) NSMutableArray<TYAVSDirectivesModel*> *directives;
@property (nonatomic, strong) NSMutableArray *speechDatas;

@property (copy, nonatomic) void (^palyCompletedHandler)(BOOL successfully, NSInteger offsetInMilliseconds);
@property (copy, nonatomic) void (^completionHandler)(void);
@property (copy, nonatomic) void (^startSpeakBlock)(TYAVSDirectivesModel* directive);
@property (copy, nonatomic) void (^endSpeakBlock)(BOOL successfully,TYAVSDirectivesModel* directive, NSInteger offsetInMilliseconds);

@end
@implementation TYAVSAudioPlayer

- (AVAudioPlayer *)alexaBeginEarconPlay {
if (!_alexaBeginEarconPlay) {
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"TuyaAVSKit.bundle/begin" ofType:@"wav"];
    NSURL *soundUrl = [NSURL fileURLWithPath:soundPath];
    AVAudioPlayer *audioPlay = [[AVAudioPlayer alloc]initWithContentsOfURL:soundUrl error:nil];
    audioPlay.numberOfLoops = 1;
    _alexaBeginEarconPlay = audioPlay;
}
    
    return _alexaBeginEarconPlay;
}

- (AVAudioPlayer *)alexaEndEarconPlay {
    if (!_alexaEndEarconPlay) {
        NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"TuyaAVSKit.bundle/end" ofType:@"wav"];
        NSURL *soundUrl = [NSURL fileURLWithPath:soundPath];
        AVAudioPlayer *audioPlay = [[AVAudioPlayer alloc]initWithContentsOfURL:soundUrl error:nil];
        audioPlay.numberOfLoops = 1;
        _alexaEndEarconPlay = audioPlay;
    }
    
    return _alexaEndEarconPlay;
}

- (AVAudioPlayer *)alexaErrorEarconPlay {
    if (!_alexaErrorEarconPlay) {
        NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"TuyaAVSKit.bundle/error" ofType:@"wav"];
        NSURL *soundUrl = [NSURL fileURLWithPath:soundPath];
        AVAudioPlayer *audioPlay = [[AVAudioPlayer alloc]initWithContentsOfURL:soundUrl error:nil];
        audioPlay.numberOfLoops = 1;
        _alexaErrorEarconPlay = audioPlay;
    }
    
    return _alexaErrorEarconPlay;
}

-(void)palyBeginAlexaEarcon{
    [self.alexaBeginEarconPlay play];
}

-(void)palyEndAlexaEarcon{
    [self.alexaEndEarconPlay play];
}

-(void)palyErrorAlexaEarcon{
    [self.alexaErrorEarconPlay play];
}


- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error{
    
}


- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player{
    
}

/* audioPlayerEndInterruption:withOptions: is called when the audio session interruption has ended and this player had been interrupted while playing. */
/* Currently the only flag is AVAudioSessionInterruptionFlags_ShouldResume. */
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withOptions:(NSUInteger)flags{
       [player play];
}


//- (BOOL)isPlaying {
//    return _audioPlayer.isPlaying;
//}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSInteger offsetInMilliseconds = (NSInteger)(player.currentTime*1000);
    
    if (flag) {
        if(self.endSpeakBlock){
            self.endSpeakBlock(YES, self.directives.firstObject, offsetInMilliseconds);
        }
        [self.directives removeObjectAtIndex:0];
        [self.speechDatas removeObjectAtIndex:0];
        [self speakSpeechDatas];
    }else{
        if(self.endSpeakBlock){
            self.endSpeakBlock(NO, self.directives.firstObject, offsetInMilliseconds);
        }
        _isPlay = NO;
        if (self.completionHandler) {
            self.completionHandler();
        }
    }
    
   
}

- (void)speakSpeechDatas{
    NSData *data = self.speechDatas.firstObject;
    if(data){
        if (self.startSpeakBlock) {
            self.startSpeakBlock(self.directives.firstObject);
        }
        self.audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
        self.audioPlayer.delegate = self;
        [self.audioPlayer play];
    }else{
        _isPlay = NO;
        if (self.completionHandler) {
            self.completionHandler();
        }
    }
}


- (void)stop{
  //  [self.audioPlayer stop];
}

- (void)speakWithDirectives:(NSArray<TYAVSDirectivesModel*> *)directives
                speechDatas:(NSArray<NSData*> *)speechDatas
            startSpeakBlock:(void (^)(TYAVSDirectivesModel* directive))startSpeakBlock
              endSpeakBlock:(void (^)(BOOL successfully,TYAVSDirectivesModel* directive, NSInteger offsetInMilliseconds))endSpeakBlock
          completionHandler:(void (^)(void))completionHandler{
    self.startSpeakBlock = startSpeakBlock;
    self.endSpeakBlock = endSpeakBlock;
    self.completionHandler = completionHandler;
    _isPlay = YES;
    if (!self.playVoice) {
        self.directives = [directives mutableCopy];
        [self speakDirectives];
    }else{
        self.speechDatas = [speechDatas mutableCopy];
        self.directives = [directives mutableCopy];
        [self speakSpeechDatas];
    }
}

-(void)speakDirectives{
    TYAVSDirectivesModel *directive = self.directives.firstObject;
    if(directive){
        __weak __typeof__(self) weakSelf = self;
        if (self.startSpeakBlock) {
            self.startSpeakBlock(directive);
        }
        [NSTimer scheduledTimerWithTimeInterval:directive.speak_duration repeats:NO block:^(NSTimer * _Nonnull timer) {
            if(weakSelf.endSpeakBlock){
                weakSelf.endSpeakBlock(YES, directive, directive.speak_duration);
            }
            [weakSelf.directives removeObjectAtIndex:0];
            [weakSelf speakDirectives];
        }];
    }else{
        _isPlay = NO;
        if (self.completionHandler) {
            self.completionHandler();
        }
    }
    
}



@end
