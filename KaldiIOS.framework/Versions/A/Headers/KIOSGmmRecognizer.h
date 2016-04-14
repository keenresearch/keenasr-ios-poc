//
//  KIOSGmmRecognizer.h
//  KaldiIOS
//
//  Created by Ognjen Todic on 2/9/16.
//  Copyright © 2016 Keen Research. All rights reserved.
//

#ifndef KIOSGmmRecognizer_h
#define KIOSGmmRecognizer_h

#import <Foundation/Foundation.h>

#include "KIOSRecognizer.h"


@interface KIOSGmmRecognizer : KIOSRecognizer

@property(nonatomic, weak) id<KIOSRecognizerDelegate> delegate;
@property(assign, readonly) BOOL listening;

- (id)initWithBundle:(NSString *)pathToASRBundle;

- (BOOL)startListening;
- (BOOL)stopListening;
- (BOOL)stopListeningWithDelay:(float)delay;

// Resets adaptation state for the recognizer. Returns true if successful, false
// otherwise.
//
// Call this method only when recognizer is not listening. It will fail to reset
// the state if the recognizer is listening
- (BOOL)resetAdaptationState;

@end




#endif /* KIOSOGmmRecognizer_h */
