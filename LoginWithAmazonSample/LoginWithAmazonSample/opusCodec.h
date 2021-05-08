//
//  opusCodec.h
//  LoginWithAmazonSample
//
//  Created by huchao on 2021/4/19.
//  Copyright © 2021 Amazon. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface opusCodec : NSObject

-(void)opusInit;

-(NSData*)encodePCMData:(NSData*)data;

-(NSData*)decodeOpusData:(NSData*)data;

-(void)destroy;

@end

NS_ASSUME_NONNULL_END
