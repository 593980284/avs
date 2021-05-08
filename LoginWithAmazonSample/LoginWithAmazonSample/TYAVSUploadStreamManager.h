//
//  TYAVSUploadStream.h
//  TuyaAVSKit
//
//  Created by huchao on 2021/4/28.
//

#import <Foundation/Foundation.h>
#import "TYAVSDataUtil.h"
NS_ASSUME_NONNULL_BEGIN

@interface TYAVSUploadStreamManager : NSObject
@property (nonatomic, strong, readonly) NSInputStream *inputStream;

-(void)beginWithInitiator:(NSDictionary *)initiator startSpeechModel:(TYAVSUploaderStartSpeechModel *)startSpeechModel;

-(void)appendAudioData:(NSData *)data;

-(void)end;
@end

NS_ASSUME_NONNULL_END
