//
//  TYAVSApi.h
//  LoginWithAmazonSample
//
//  Created by huchao on 2021/4/9.
//  Copyright © 2021 Amazon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TYAVSDataUtil.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^TYAVSFailureBlock)(NSURLResponse * _Nullable response, NSError * _Nullable error);

typedef void(^TYAVSSuccessBlock)(NSURLResponse * _Nullable response, NSDictionary * _Nullable dataDic);

typedef void(^TYAVSDataModelBlock)(NSHTTPURLResponse * _Nullable response, TYAVSDataModel * dataModel);

//typedef void(^TYAVSReceiveDataHandler)(NSData * data);


@interface TYAVSApi : NSObject

+(TYAVSApi *)share;
//语音上传
-(NSURLSessionUploadTask *)uploadSpeechWithToken:(NSString*)token
                                          stream:(NSInputStream *)inputStream
                                         success:(TYAVSDataModelBlock)successModelBlock
                                         failure:(TYAVSFailureBlock)failureBlock;

/// 建立60分钟的get请求，收到数据时候，会回调receiveModelBlock。alexa指令，都会从这个get下发。
/// **要保证这个get请求要一直处于连接状态**
/// @param token token
/// @param receiveModelBlock 收到指令回调，会被多次调用
/// @param successModelBlock 成功回调。意味get已经结束，在开启语音请求前，需要重新建立这个连接
/// @param failureBlock 失败回调。意味get已经结束，在开启语音请求前，需要重新建立这个连接
-(NSURLSessionDataTask *)setUpDownChannelWithToken:(NSString*)token
                                       receiveData:(TYAVSDataModelBlock)receiveModelBlock
                                           success:(TYAVSDataModelBlock)successModelBlock
                                           failure:(TYAVSFailureBlock)failureBlock;
//ping
-(NSURLSessionDataTask *)pingWithToken:(NSString*)token
                               success:(TYAVSSuccessBlock)successBlock
                               failure:(TYAVSFailureBlock)failureBlock;
//能力版本号指定
-(NSURLSessionDataTask *)capabilitiesWithToken:(NSString*)token
                                       success:(TYAVSSuccessBlock)successBlock
                                       failure:(TYAVSFailureBlock)failureBlock;

-(NSURLSessionDataTask *)sendEventWithToken:(NSString*)token
                                      event:(NSData*)event
                                    success:(TYAVSSuccessBlock)successBlock
                                    failure:(TYAVSFailureBlock)failureBlock;

@end

NS_ASSUME_NONNULL_END
