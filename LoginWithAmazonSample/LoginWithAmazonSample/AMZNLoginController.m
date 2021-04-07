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
//[avsDataModel.directives enumerateObjectsUsingBlock:^(TYAVSDirectivesModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//    NSLog(@"指令：%@,payload：%@",obj.name,obj.payload);
//}];

@interface A : NSObject

@property (nonatomic,assign) int i;

@end

@implementation A

@end

@implementation AMZNLoginController
{
    TYAVSUploader *uploader;
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
- (IBAction)btntap:(id)sender {
   
  //  [[TYAVSUploader shareInstance] appendData:nil devId:@"1"];
    
    BOOL isRecording = [[RecordTool shared] isRecording];
    if (isRecording) {
        [self.btn2 setTitle:@"开始录音" forState:0];
        [[RecordTool shared] stopRecording];
       // [[TYAVSUploader shareInstance] appendData:self.mdata devId:@"1"];
    }else{
        [self.btn2 setTitle:@"录音中。。" forState:0];
     
        [uploader setupConversation];
        
        [[RecordTool shared] startRecordingWithBlock:^(NSData * _Nullable data) {
            [uploader appendData:data];
//            [self.mdata appendData:data];
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
        uploader = [[TYAVSUploader alloc]initWithDevId:@"" token:AlexaClient.shareClient.authorization.token];
        uploader.delegate = self;
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
}

- (void)dealloc {
    [_btn2 release];
    [super dealloc];
}


-(void)avsUploader:(TYAVSUploader *)avsUploader speechData:(NSData *)speechData{
    [AudioManager.shareManager playAudioData:speechData completionHandler:^(BOOL successfully) {
        
    }];
}

-(void)avsUploader:(TYAVSUploader *)avsUploader directives:(NSArray<TYAVSDirectivesModel *>*)directives{
    [directives enumerateObjectsUsingBlock:^(TYAVSDirectivesModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"指令：%@,payload：%@",obj.name,obj.payload);
        if ([obj.name isEqualToString:@"StopCapture"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.btn2 setTitle:@"开始录音" forState:0];
                [[RecordTool shared] stopRecording];
            });
        }
    }];
}

-(void)avsUploader:(TYAVSUploader *)avsUploader error:(NSError *)error{
    
}
@end
