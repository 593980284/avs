//
//  AudioManager.h
//  wuge
//
//  Created by wuge on 2020/9/7.
//  Copyright © 2020年 wuge. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioManager : NSObject

+ (instancetype)shareManager;

// Recording
- (void)recordStartWithProcess:(void (^)(float peakPower))processHandler failed:(void (^)(NSError *error))failedHandler completed:(void (^)(NSData *data))completedHandler;
- (void)recordStop;
- (BOOL)isRecording;

// Playing
- (void)playAudioData:(NSData *)data completionHandler:(void (^)(BOOL successfully))handler;
- (BOOL)isPlaying;

@end

