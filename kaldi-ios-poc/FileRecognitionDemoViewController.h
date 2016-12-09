//
//  FileRecognitionDemoViewController.h
//  kaldi-ios-poc
//
//  Created by Ognjen Todic on 10/24/16.
//  Copyright © 2016 Keen Research. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KaldiIOS/KaldiIOS.h"

// We setup this controller to follow KIOSRecognizerDelegate protocol so we can
// receive notifications about partial and final recognition results

@interface FileRecognitionDemoViewController : UIViewController <KIOSRecognizerDelegate>

@end
