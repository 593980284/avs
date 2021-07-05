//
//  RecordTool.h
//  LoginWithAmazonSample
//
//  Created by huchao on 2021/3/23.
//  Copyright © 2021 Amazon. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RecordTool : NSObject
@property (nonatomic, assign) BOOL isRecording;

+ (instancetype)shared;

//开始录音
- (void)startRecordingWithBlock:(void (^_Nullable)(NSData *_Nullable))block;

//停止录音
- (void)stopRecording;

@end

NS_ASSUME_NONNULL_END
