//
//  TYImageAESCoder.m
//  Bolts
//
//  Created by 傅浪 on 2019/5/29.
//

#import "TYImageAESCoder.h"
#import <CommonCrypto/CommonCrypto.h>

typedef struct {
    uint version;
    Byte iv[16];
    uint size;
    char reserve[40];
} TY_AES_PIC_INFO_S;

@implementation TYImageAESCoder

+ (UIImage *)decryptImageWithData:(NSData *)data encryptKey:(NSString *)encryptKey {
    return [[UIImage alloc] initWithData:[self decryptWithData:data encryptKey:encryptKey]];
}
+ (NSData *)decryptWithData:(NSData *)data encryptKey:(NSString *)encryptKey{
    TY_AES_PIC_INFO_S info;
    [data getBytes:&info length:64];
    NSData *keyData = [encryptKey dataUsingEncoding:NSUTF8StringEncoding];
    data = [data subdataWithRange:NSMakeRange(64, data.length - 64)];
    NSData *ivData = [NSData dataWithBytes:info.iv length:16];
   return [self ty_aesOperation:kCCDecrypt data:data keyData:keyData ivData:ivData];
}

+ (NSData *)encryptImageWithImage:(UIImage *)image encryptKey:(NSString *)encryptKey {
    NSData *imageData = [image yy_imageDataRepresentation];
    return [self encryptData:imageData encryptKey:encryptKey];
}

+ (NSData *)encryptData:(NSData *)data encryptKey:(NSString *)encryptKey {
    NSData *keyData = [encryptKey dataUsingEncoding:NSUTF8StringEncoding];
    NSData *ivData = [self randomIV];
    NSData *encryptData = [self ty_aesOperation:kCCEncrypt data:data keyData:keyData ivData:ivData];
    TY_AES_PIC_INFO_S info;
    [ivData getBytes:info.iv length:16];
    info.size = (uint)data.length;
    NSData *infoData = [NSData dataWithBytes:&info length:64];
    NSMutableData *mdata = [NSMutableData new];
    [mdata appendData:infoData];
    [mdata appendData:encryptData];
    return [mdata copy];
}

+ (NSData *)randomIV {
    srand((unsigned int)time(NULL));
    uint8_t iv[16];
    for (int i = 0; i < 16; i++) {
        uint8_t r = rand() % 16;
        iv[i] = r;
    }
    return [NSData dataWithBytes:iv length:16];
}

+ (NSData *)ty_aesOperation:(CCOperation)operation data:(NSData *)data keyData:(NSData *)keyData ivData:(NSData *)ivData {
    if (!data || data.length == 0 ||
        !keyData || keyData.length == 0 ||
        !ivData || ivData.length == 0) {
        return nil;
    }
    if (keyData.length > kCCKeySizeAES256) {
        return nil;
    }
    int aesKeySize = keyData.length > kCCKeySizeAES128 ? kCCKeySizeAES256 : kCCKeySizeAES128;
    char keyPtr[aesKeySize + 1];
    bzero(keyPtr, sizeof(keyPtr));

    [keyData getBytes:keyPtr length:MIN(keyData.length, sizeof(keyPtr))];
    
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(operation,
                                          kCCAlgorithmAES,
                                          kCCOptionPKCS7Padding,
                                          keyPtr,
                                          aesKeySize,
                                          [ivData bytes],
                                          [data bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    free(buffer);
    return nil;
}

+ (NSString *)encryptKeyForImagePath:(NSString *)imagePath {
    if (imagePath.length == 0) {
        return nil;
    }
    return [[self encryptKeyMap] objectForKey:imagePath];
}

+ (void)setEncryptKey:(NSString *)encryptKey forImagePath:(NSString *)imagePath {
    if (imagePath.length == 0) return;
    [[self encryptKeyMap] setObject:encryptKey forKeyedSubscript:imagePath];
}

+ (NSMutableDictionary *)encryptKeyMap {
    static NSMutableDictionary *_map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _map = [NSMutableDictionary new];
    });
    return _map;
}

@end
