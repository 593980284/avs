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
@protocol TYAVSUploaderDelegate <NSObject>

-(void)avsUploader:(TYAVSUploader *)avsUploader speechData:(NSData *)speechData;

-(void)avsUploader:(TYAVSUploader *)avsUploader directives:(NSArray<TYAVSDirectivesModel *>*)directives;

-(void)avsUploader:(TYAVSUploader *)avsUploader error:(NSError *)error;

@end

@interface TYAVSUploader : NSObject

@property (copy, nonatomic, readonly) NSString *devId;

@property (weak, nonatomic) id <TYAVSUploaderDelegate> delegate;

-(instancetype)initWithDevId:(NSString *)devId
                       token:(NSString *)token;

-(void)setupConversation;

-(void)appendData:(NSData *)data;



//-(void)downchannelStream:(NSString *)devId token:(NSString *)token;

@end

NS_ASSUME_NONNULL_END
