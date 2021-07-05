/**
 * Copyright 2012-2015 Amazon.com, Inc. or its affiliates. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the License. A copy
 * of the License is located at
 *
 * http://aws.amazon.com/apache2.0/
 *
 * or in the "license" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 */

#import <LoginWithAmazon/LoginWithAmazon.h>

#import "AMZNLoginController.h"
#import "AlexaClient.h"
#import "AudioManager.h"
#import "RecordTool.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "TYAVSAudioPlayer.h"
#import "TYOpusCodec.h"

//[avsDataModel.directives enumerateObjectsUsingBlock:^(TYAVSDirectivesModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//    NSLog(@"指令：%@,payload：%@",obj.name,obj.payload);
//}];

@interface A : NSObject

@property (nonatomic,assign) int i;
@property (nonatomic, strong) opusCodec *codes;
@property (nonatomic, strong) A *next;

@end

@implementation A


-(instancetype)init{
    if (self = [super init]) {
//        __weak __typeof__(self) weakSelf = self;
//        NSTimer *timr = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
//            NSLog(@"__1");
//
//        }];
//
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [timr invalidate];
//        });
        
    }
    return self;
}

-(void)dealloc{
    NSLog(@"222");
}
@end

@implementation AMZNLoginController
{
    TYAVSUploader *uploader;
    TYOpusCodec* OpusCodec16;
    TYOpusCodec* OpusCodec32;
}

@synthesize userProfile, navigationItem, logoutButton, loginButton, infoField;

NSString* userLoggedOutMessage = @"Welcome to Login with Amazon!\nIf this is your first time logging in, you will be asked to give permission for this application to access your profile data.";
NSString* userLoggedInMessage = @"Welcome, %@ \n Your email is %@.";
BOOL isUserSignedIn;
-(NSMutableData *)mdata{
    if (!_mdata) {
        _mdata = [NSMutableData new];
    }
    return _mdata;
}

-(opusCodec *)codes{
    if (!_codes) {
        _codes = [opusCodec new];
        [_codes opusInit];
    }
    return  _codes;
}
- (IBAction)strbtntap:(id)sender {
    
    TYAVSUploaderStartSpeechModel * startSpeechModel = [TYAVSUploaderStartSpeechModel new];
    startSpeechModel.dialogId = @"22";
    startSpeechModel.suppressEarcon = YES;
    startSpeechModel.playVoice = YES;
    startSpeechModel.audioFormat = 1;
    startSpeechModel.audioProfile = 1;
    [uploader startSpeech:startSpeechModel ];
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString* ss = [self.audioTextView.text stringByReplacingOccurrencesOfString:@" " withString:@""];
        ss = [ss stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        ss = [ss stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        NSData *audata = [self convertHexStrToData:ss];
//        NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"pcm" ofType:@"raw"];
//        NSData *audata = [[NSData alloc]initWithContentsOfFile:soundPath];
        [self->uploader appendData:audata];
    });
    
  
    
}
- (IBAction)strDen:(id)sender {
    TYAVSUploaderStartSpeechModel * startSpeechModel = [TYAVSUploaderStartSpeechModel new];
    startSpeechModel.dialogId = @"22";
    startSpeechModel.suppressEarcon = YES;
    startSpeechModel.playVoice = YES;
    startSpeechModel.audioFormat = 1;
    startSpeechModel.audioProfile = 1;
    [uploader startSpeech:startSpeechModel];
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString* ss = [self.audioTextView.text stringByReplacingOccurrencesOfString:@" " withString:@""];
        ss = [ss stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        ss = [ss stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        NSData *audata = [self convertHexStrToData:ss];
        audata = [self->uploader coverToOpus32:audata frameSize:80];
//        NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"pcm" ofType:@"raw"];
//        NSData *audata = [[NSData alloc]initWithContentsOfFile:soundPath];
        [self->uploader appendData:audata];
    });
    
}

- (IBAction)btntap:(id)sender {
   
  //  [[TYAVSUploader shareInstance] appendData:nil devId:@"1"];
    
    BOOL isRecording = [[RecordTool shared] isRecording];
    NSLog(@"%@",self.mdata);
    
    if (isRecording) {
        [self.btn2 setTitle:@"开始录音" forState:0];
        [[RecordTool shared] stopRecording];
        
        //[uploader appendData:self.mdata];
       // [[TYAVSUploader shareInstance] appendData:self.mdata devId:@"1"];
    }else{
        [self.btn2 setTitle:@"录音中。。" forState:0];
        self.mdata = [NSMutableData new];
        TYAVSUploaderStartSpeechModel * startSpeechModel = [TYAVSUploaderStartSpeechModel new];
        startSpeechModel.dialogId = @"22";
        startSpeechModel.suppressEarcon = YES;
        startSpeechModel.playVoice = YES;
        startSpeechModel.audioFormat = 1;
        startSpeechModel.audioProfile = 1;
        [uploader startSpeech:startSpeechModel ];
        
        //__block typeof(uploader) _uploader = uploader;
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [[NSBundle mainBundle]pathForResource:@"opus" ofType:nil];
//            NSData *data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"opus" ofType:nil]];
//            [uploader appendData:data];
//            NSLog(@"清楚self");
//            self->uploader = nil;
//        });
        __weak typeof(uploader) _uploader2 = uploader;
        self.mdata = [NSMutableData new];
        if(!OpusCodec16){
            OpusCodec16 = [TYOpusCodec avsOpusCodec_16bitRate];
            OpusCodec32 = [TYOpusCodec avsOpusCodec_32bitRate];
        }
                
     
        [[RecordTool shared] startRecordingWithBlock:^(NSData * _Nullable data) {
//        NSData* opus16 =  [OpusCodec16 encodeMonoPCMData:data];
//        NSData* pcm =  [OpusCodec32 decodeOpusData:opus16 pcmDataFrameSize:640];
        NSData *opus32 = [OpusCodec32 encodeMonoPCMData:data];

          //NSLog(@"%ld,%ld,%ld",opus16.length,pcm.length,opus32.length);
            [self->uploader appendData:opus32];
            [self.mdata appendData:opus32];
        }];
//        [[AudioManager shareManager]  recordStartWithProcess:^(float peakPower) {
//
//        } failed:^(NSError *error) {
//
//        } completed:^(NSData *data) {
//              [[TYAVSUploader shareInstance] appendData:data devId:@"1"];
////            [AlexaClient.shareClient speechRecognize:data withCompleteHandler:^(NSArray * _Nullable directives, NSError * _Nullable error) {
////                if (error) {
////                    [self showAlertTitle:@""
////                                 message:[NSString stringWithFormat:@"failed: %@", error.userInfo[NSLocalizedDescriptionKey]]
////                                btnTitle:@"OK"];
////                } else if (directives) {
////                    [directives enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
////                        NSLog(@"____%@",obj);
////                        if ([obj[@"type"] isEqualToString:kContentTypeAudio]) {
//////                            self.speaker.hidden = false;
////                            [AudioManager.shareManager playAudioData:obj[@"content"] completionHandler:^(BOOL successfully) {
////
////                            }];
////                            return;
////                        } else {
////                          //  self.directivesTextView.text = [self.directivesTextView.text stringByAppendingString:obj.description];
////                            NSLog(@"%@",obj.description);
////                        }
////                    }];
////                }
////            }];
//        }];
    }
}

- (IBAction)onLogInButtonClicked:(id)sender {
    // Make authorize call to SDK to get authorization from the user. While making the call you can specify the scopes for which the user authorization is needed.
    
    // Build an authorize request.
    AMZNAuthorizeRequest *request = [[AMZNAuthorizeRequest alloc] init];
    
    NSDictionary *scopeData = @{@"productID": @"product_code_test",
                                @"productInstanceAttributes": @{@"deviceSerialNumber": @"12345"}};

    id alexaAllScope = [AMZNScopeFactory scopeWithName:@"alexa:all" data:scopeData];
    
    // Requesting 'profile' scopes for the current user.
    request.scopes = @[[AMZNProfileScope profile], alexaAllScope];
    
    // Make an Authorize call to the Login with Amazon SDK.
    [[AMZNAuthorizationManager sharedManager] authorize:request
                                            withHandler:[self requestHandler]];
}

- (IBAction)logoutButtonClicked:(id)sender {
    [[AMZNAuthorizationManager sharedManager] signOut:^(NSError * _Nullable error) {
        // Your additional logic after the user authorization state is cleared.

        [self showLogInPage];
    }];
}

- (BOOL)shouldAutorotate {
    return NO;
}

#pragma mark View controller specific functions
- (void)checkIsUserSignedIn {
    // Make authorize call to SDK using AMZNInteractiveStrategyNever to detect whether there is an authenticated user. While making this call you can specify scopes for which user authorization is needed. If this call returns error, it means either there is no authenticated user, or at least of the requested scopes are not authorized. In both case you should show sign in page again.
    
    // Build an authorize request.
    AMZNAuthorizeRequest *request = [[AMZNAuthorizeRequest alloc] init];
    
    NSDictionary *scopeData = @{@"productID": @"product_code_test",
                                @"productInstanceAttributes": @{@"deviceSerialNumber": @"12345"}};

    id alexaAllScope = [AMZNScopeFactory scopeWithName:@"alexa:all" data:scopeData];
    
    // Requesting 'profile' scopes for the current user.
    request.scopes = @[[AMZNProfileScope profile], alexaAllScope];
    
    // Set interactive strategy as 'AMZNInteractiveStrategyNever'.
    request.interactiveStrategy = AMZNInteractiveStrategyNever;
    
    [[AMZNAuthorizationManager sharedManager] authorize:request
                                            withHandler:[self requestHandler]];
}

- (AMZNAuthorizationRequestHandler)requestHandler
{
    AMZNAuthorizationRequestHandler requestHandler = ^(AMZNAuthorizeResult * result, BOOL userDidCancel, NSError * error) {
        if (error) {
            // If error code = kAIApplicationNotAuthorized, allow user to log in again.
            if(error.code == 0) {
                // Show authorize user button.
                [self showLogInPage];
            } else {
                // Handle other errors
                NSString *errorMessage = error.userInfo[@"AMZNLWAErrorNonLocalizedDescription"];
                [[[[UIAlertView alloc] initWithTitle:@"" message:[NSString stringWithFormat:@"Error occured with message: %@", errorMessage] delegate:nil cancelButtonTitle:@"OK"otherButtonTitles:nil] autorelease] show];
            }
        } else if (userDidCancel) {
            // Your code to handle user cancel scenario.
            
        } else {
            // Authentication was successful. Obtain the user profile data.
            AlexaClient.shareClient.authorization = result;
            AMZNUser *user = result.user;
            self.userProfile = user.profileData;
            [self loadSignedInUser];
        }
    };
    
    return [requestHandler copy];
}

- (void)loadSignedInUser {
    if (!isUserSignedIn) {
        [uploader setAlexaAuthToken:AlexaClient.shareClient.authorization.token complete:^(BOOL success) {
            NSLog(@"success:%ld",success);
        }];
    }
    isUserSignedIn = true;
    self.loginButton.hidden = true;
    self.navigationItem.rightBarButtonItem = self.logoutButton;
    self.infoField.text = [NSString stringWithFormat:@"Welcome, %@ \n Your email is %@.", [userProfile objectForKey:@"name"], [userProfile objectForKey:@"email"]];
    self.infoField.hidden = false;

}

- (void)showLogInPage {
    isUserSignedIn = false;
    self.loginButton.hidden = false;
    self.navigationItem.rightBarButtonItem = nil;
    self.infoField.text = userLoggedOutMessage;
    self.infoField.hidden = false;
}

- (void)viewDidLoad {
    
    double latitude = 30.302710400534167;
    NSString *lat = [[NSNumber alloc]initWithDouble:latitude].stringValue;
    NSString *lat2 = [NSString stringWithFormat:@"%.10f", latitude];
    NSString *lat3 = [NSString stringWithFormat:@"%g", latitude];
  
   [A new];
    uploader = [[TYAVSUploader alloc]initWithDevId:@""];
  
    uploader.delegate = self;
    
    if (isUserSignedIn)
        [self loadSignedInUser];
    else
        [self showLogInPage];
    float systemVersion=[[[UIDevice currentDevice] systemVersion] floatValue];
    if(systemVersion>=7.0f)
    {
        CGRect tempRect;
        for(UIView *sub in [[self view] subviews])
        {
            tempRect = [sub frame];
            tempRect.origin.y += 20.0f; //Height of status bar
            [sub setFrame:tempRect];
        }
    }
    
    self.llll = [UILabel new];
    [self.view addSubview:self.llll];
    self.llll.frame = CGRectMake(100, 64, 300, 40);
    
    self.llll2 = [UILabel new];
    self.llll2.font = [UIFont systemFontOfSize:12];
    self.llll2.numberOfLines = 0;
    [self.view addSubview:self.llll2];
    self.llll2.frame = CGRectMake(100, 64+50, 200, 100);
//    NSString* ID = [[NSUUID UUID] UUIDString];
//    long long datatemplength = CFSwapInt64BigToHost((uint32_t)ID.hash);  //大小端不一样，需要转化
//    NSData *idData = [NSData dataWithBytes: &datatemplength length: sizeof(datatemplength)];
//    NSLog(@"%@",idData);
    
    self.audioTextView = [UITextView new];
   
    NSData *data = [[NSData alloc]initWithContentsOfFile:[NSURL fileURLWithPath: [[NSBundle mainBundle]pathForResource:@"222" ofType:@"txt"]]];
    [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
//    self.audioTextView.text = [self convertDataToHexStr:data];
    self.audioTextView.text =[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    self.audioTextView.backgroundColor = [UIColor redColor];
    self.audioTextView.editable = YES;
    [self.view addSubview:self.audioTextView];
    self.audioTextView.frame = CGRectMake(0,100, 50, 100);
    
    _thread = [[NSThread alloc] initWithTarget:self selector:@selector(readData) object:nil];
    _thread.name = @"P2PAlbumReadData";
    [_thread start];
    
//    NSString *ss = @"B8 70 61 D2 ED CE F8 72 72 8C AE 7F F6 5B DE 51 B3 6B 0E 2F 98 CE CD 8D 32 A5 C5 BF 10 44 EB F4 F6 BA 8F EF 7F 11 B5 89 37 C4 BF 87 1C 2E 00 B5 D4 3D 92 E7 BA 5D 68 3F EB E8 B4 C0 3E 84 CF 35 98 89 DB 2F E0 FF AA B3 1C 7E 97 62 2E BB FC F5 ";
//    ss = [ss stringByReplacingOccurrencesOfString:@" " withString:@""];
//    NSData *da  = [self convertHexStrToData:ss];
//
//    if(!OpusCodec16){
//        OpusCodec16 = [TYOpusCodec avsOpusCodec_16bitRate];
//        OpusCodec32 = [TYOpusCodec avsOpusCodec_32bitRate];
//    }
//
//    NSData *pcmData =  [OpusCodec32 decodeOpusData:da pcmDataFrameSize:640];
//    pcmData= [OpusCodec32 encodeMonoPCMData:pcmData];
//    NSLog(@"%@",pcmData);
    
}


- (void)dealloc {
    [_btn2 release];
    [super dealloc];
}

-(void)readData{
//    while (1 &&![NSThread currentThread].isCancelled) {
//        NSLog(@"222222");
//    }
}


-(NSString*)encodeString:(NSString*)unencodedString{
// CharactersToBeEscaped = @":/?&=;+!@#$()~',*";
// CharactersToLeaveUnescaped = @"[].";
NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
(CFStringRef)unencodedString,
NULL,
(CFStringRef)@"!*'();:@&=+$,/?%#[]",
kCFStringEncodingUTF8));
return encodedString;
}


-(void)avsUploader:(TYAVSUploader *)avsUploader speechData:(NSData *)speechData{
    double duration = [[AVAudioPlayer alloc] initWithData:speechData error:nil].duration;
    NSLog(@"%lf",duration);
//    [AudioManager.shareManager playAudioData:speechData completionHandler:^(BOOL successfully) {
//        
//    }];
}

-(void)avsUploader:(TYAVSUploader *)avsUploader directives:(NSArray<TYAVSDirectivesModel *>*)directives{
    
    [directives enumerateObjectsUsingBlock:^(TYAVSDirectivesModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.name isEqualToString:TYAVSDirectiveTypeSpeak]) {
            if (obj.speak_content) {
                NSLog(@"%@",obj.speak_content);
                self.llll2.text = obj.speak_content;
                //发送文字
            }

        }else if([obj.name isEqualToString:TYAVSDirectiveTypeStopCapture]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.btn2 setTitle:@"开始录音" forState:0];
                [[RecordTool shared] stopRecording];
            });
        }else if([obj.name isEqualToString:TYAVSDirectiveTypeExpectSpeech]) {
            
        }
    }];
}


-(void)avsUploader:(TYAVSUploader *)avsUploader dialogRequestId:(NSString*)dialogRequestId error:(NSError *)error{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.btn2 setTitle:@"开始录音" forState:0];
        [[RecordTool shared] stopRecording];
        self.llll2.text = [NSString stringWithFormat:@"失败： %@",error];
    });
}

-(void)avsUploader:(TYAVSUploader *)avsUploader dialogRequestId:(NSString*)dialogRequestId state:(TYAVSDeviceState)state{
    if (state == TYAVSDeviceStateExpect) {
        self.llll.text = @"期待";
    }else{
        self.llll.text = @[@"空闲",@"监听中",@"识别",@"播放"][state];
    }
    if (state != 3 && state != 0) {
        self.llll2.text = @"";
    }
}

-(NSString *)convertDataToHexStr:(NSData *)data
{
    if (!data || [data length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    return string;
}

- (NSData *)convertHexStrToData:(NSString *)str
{
    if (!str || [str length] == 0) {
        return nil;
    }
    
    NSMutableData *hexData = [[NSMutableData alloc] initWithCapacity:20];
    NSRange range;
    if ([str length] % 2 == 0) {
        range = NSMakeRange(0, 2);
    } else {
        range = NSMakeRange(0, 1);
    }
    for (NSInteger i = range.location; i < [str length]; i += 2) {
        unsigned int anInt;
        NSString *hexCharStr = [str substringWithRange:range];
        NSScanner *scanner = [[NSScanner alloc] initWithString:hexCharStr];
        
        [scanner scanHexInt:&anInt];
        NSData *entity = [[NSData alloc] initWithBytes:&anInt length:1];
        [hexData appendData:entity];
        
        range.location += range.length;
        range.length = 2;
    }
    return hexData;
}


@end
