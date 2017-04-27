//
//  CommandAndControlViewController.h
//  kaldi-ios-poc
//
//  Created by Ognjen Todic on 11/18/16.
//  Copyright © 2016 Keen Research. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "KeenASR/KeenASR.h"


// We setup this controller to follow KIOSRecognizerDelegate protocol so we can
// receive notifications about partial and final recognition results

@interface CommandAndControlViewController : UIViewController  <KIOSRecognizerDelegate>

@end
