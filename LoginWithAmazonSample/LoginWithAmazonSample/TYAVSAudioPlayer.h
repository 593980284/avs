//
//  TYAVSAudioPlayer.h
//  TuyaAVSKit
//
//  Created by huchao on 2021/4/29.
//

#import <Foundation/Foundation.h>
#import "TYAVSDataUtil.h"

NS_ASSUME_NONNULL_BEGIN

@interface TYAVSAudioPlayer : NSObject
@property (nonatomic,assign) BOOL playVoice;
@property (nonatomic,assign) BOOL isPlay;
-(void)palyBeginAlexaEarcon;
-(void)palyEndAlexaEarcon;
-(void)palyErrorAlexaEarcon;

- (void)playAudioDatas:(NSArray<NSData*> *)datas completionHandler:(void (^)(BOOL successfully, NSInteger offsetInMilliseconds))handler;

- (void)speakWithDirectives:(NSArray<TYAVSDirectivesModel*> *)directives
                speechDatas:(NSArray<NSData*> *)speechDatas
            startSpeakBlock:(void (^)(TYAVSDirectivesModel* directive))startSpeakBlock
              endSpeakBlock:(void (^)(BOOL successfully,TYAVSDirectivesModel* directive, NSInteger offsetInMilliseconds))endSpeakBlock
          completionHandler:(void (^)(void))completionHandler;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
