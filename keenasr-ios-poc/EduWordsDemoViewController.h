//
//  EduWordsDemoViewController.h
//  kaldi-ios-poc
//
//  Created by Ognjen Todic on 6/27/16.
//  Copyright © 2016 Keen Research. All rights reserved.
//
// In this demo, ~1000 most frequent words used by children are used to create a
// decoding graph. The app helps kids learn spelling of those words, by letting
// them say the word ("spell mouse", "how do you spell mouse", "mouse"). See
// the controller source code for details on how partial results are used for
// "keyword spotting".
//
// UX in this demo is non-existant; real app should have much better visual cues
// for kids to make clear distiction when the app is listening, processing, etc.
//



#import <UIKit/UIKit.h>

#import "KeenASR/KeenASR.h"

// We setup this controller to follow KIOSRecognizerDelegate protocol so we can
// receive notifications about partial and final recognition results

@interface EduWordsDemoViewController : UIViewController  <KIOSRecognizerDelegate>

@end
