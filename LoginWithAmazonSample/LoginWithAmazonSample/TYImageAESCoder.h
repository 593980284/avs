//
//  TYImageAESCoder.h
//  Bolts
//
//  Created by TuyaInc on 2019/5/29.
//


#import <Foundation/Foundation.h>

@interface TYImageAESCoder : NSObject

+ (UIImage *)decryptImageWithData:(NSData *)data encryptKey:(NSString *)encryptKey;

+ (NSData *)decryptWithData:(NSData *)data encryptKey:(NSString *)encryptKey;

+ (NSData *)encryptImageWithImage:(UIImage *)image encryptKey:(NSString *)encryptKey;

+ (NSData *)encryptData:(NSData *)data encryptKey:(NSString *)encryptKey;

+ (NSString *)encryptKeyForImagePath:(NSString *)imagePath;

+ (void)setEncryptKey:(NSString *)encryptKey forImagePath:(NSString *)imagePath;

@end
