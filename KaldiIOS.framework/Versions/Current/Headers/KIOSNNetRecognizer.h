//
//  KIOSNNetRecognizer.h
//  KaldiIOS
//
//  Created by Ognjen Todic on 2/9/16.
//  Copyright © 2016 Keen Research. All rights reserved.
//

#ifndef KIOSNNetRecognizer_h
#define KIOSNNetRecognizer_h

#import <Foundation/Foundation.h>

#include "KIOSRecognizer.h"


@interface KIOSNNetRecognizer : KIOSRecognizer

@property(nonatomic, weak) id<KIOSRecognizerDelegate> delegate;
@property(assign, readonly) BOOL listening;

- (id)initWithBundle:(NSString *)pathToASRBundle;

- (BOOL)startListening;
- (BOOL)stopListening;

@end




#endif /* KIOSNNetRecognizer_h */
