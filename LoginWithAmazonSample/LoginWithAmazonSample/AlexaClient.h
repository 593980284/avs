//
//  AlexaClient.h
//  LoginWithAmazonSample
//
//  Created by huchao on 2021/3/23.
//  Copyright © 2021 Amazon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LoginWithAmazon/LoginWithAmazon.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kContentTypeJSON;
extern NSString * const kContentTypeAudio;

@interface AlexaClient : NSObject
typedef void (^AlexaSpeechRecognizeHandler)(NSArray * _Nullable directives, NSError * _Nullable error);

- (void)speechRecognize:(NSData *)data withCompleteHandler:(AlexaSpeechRecognizeHandler)handler;

@property (nonatomic, strong, nullable) AMZNAuthorizeResult *authorization;

@property (class, readonly, strong, null_unspecified) AlexaClient *shareClient;

@end

NS_ASSUME_NONNULL_END
