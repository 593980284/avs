//
//  TYAVSDataUtil.h
//  LoginWithAmazonSample
//
//  Created by huchao on 2021/4/6.
//  Copyright © 2021 Amazon. All rights reserved.
//

#import <Foundation/Foundation.h>

//Speak
//ExpectSpeech
//Recognize
//StopCapture
NS_ASSUME_NONNULL_BEGIN
@interface TYAVSDirectivesModel : NSObject

@property (nonatomic,copy) NSString *Namespace;
@property (nonatomic,copy) NSString *name;
@property (nonatomic,copy) NSString *messageId;
@property (nonatomic,copy) NSString *dialogRequestId;
@property (nonatomic,copy) NSDictionary *payload;
@property (nonatomic,copy) NSDictionary *header;


@end

@interface TYAVSDataModel : NSObject

@property (nonatomic,copy) NSArray<TYAVSDirectivesModel *> *directives;
@property (nonatomic,copy) NSData *speechData;

@end

@interface TYAVSDataUtil : NSObject

+(NSData *)beginData:(nullable NSDictionary *)initiator;

+(NSData *)endData;

+(TYAVSDataModel *)parseWithData:(NSData *)data withBoundary:(NSString *)contentType;
@end

NS_ASSUME_NONNULL_END
