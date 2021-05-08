//
//  TYAVSUploader.h
//  Pods
//
//  Created by huchao on 2021/3/19.
//

#import <Foundation/Foundation.h>
#import "TYAVSDataUtil.h"

NS_ASSUME_NONNULL_BEGIN


@class TYAVSUploader;
@class TYAVSUploaderStartSpeechModel;
@protocol TYAVSUploaderDelegate <NSObject>

-(void)avsUploader:(TYAVSUploader *)avsUploader speechData:(NSData *)speechData;

-(void)avsUploader:(TYAVSUploader *)avsUploader directives:(NSArray<TYAVSDirectivesModel *>*)directives;

-(void)avsUploader:(TYAVSUploader *)avsUploader dialogRequestId:(NSString*)dialogRequestId error:(NSError *)error;

-(void)avsUploader:(TYAVSUploader *)avsUploader dialogRequestId:(NSString*)dialogRequestId state:(TYAVSDeviceState)state;

@end

@interface TYAVSUploader : NSObject

@property (copy, nonatomic, readonly) NSString *devId;

@property (assign, nonatomic, readonly) TYAVSDeviceState state;

@property (weak, nonatomic) id <TYAVSUploaderDelegate> delegate;

@property (copy, nonatomic, readonly)TYAVSUploaderStartSpeechModel *startSpeechModel;

-(instancetype)initWithDevId:(NSString *)devId;

-(void)setAlexaAuthToken:(NSString *)token complete:(void(^)(BOOL success)) complete;

-(BOOL)startSpeech:(TYAVSUploaderStartSpeechModel*)startSpeechModel;

-(void)appendData:(NSData *)data;

@end


NS_ASSUME_NONNULL_END

