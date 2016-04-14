//
//  KIOSRecognizer.h
//  KIOS
//
//  Created by Ognjen Todic on 2/29/16.
//  Copyright © 2016 Keen Research. All rights reserved.
//

#ifndef KIOSRecognizer_h
#define KIOSRecognizer_h

@class KIOSOnlineGmmRecognizer;
@class KIOSOnlineNNetRecognizer;

/** These constants indicate the type of recognizers you are creating.*/
typedef NS_ENUM(NSInteger, KIOSRecognizerType) {
  /** Gaussian Mixture Model Kaldi Recognizer */
  KIOSRecognizerTypeGMM,
  /** NNet2 Kaldi Recognizer */
  KIOSRecognizerTypeNNet
};

/** KIOSResult manages results of the recognition.*/
@interface KIOSResult : NSObject

/** recognition result text */
@property(nonatomic, readonly) NSString *text;
/** recognition result clean text; all tokens of <TOKEN> are removed 
 (e.g. <spoken_noise>, etc.)  */
@property(nonatomic, readonly) NSString *cleanText;
/** Confidence of the overall result (TODO - more details on the method) */
@property(nonatomic, readonly) NSNumber *confidence;

/** Returns TRUE if recognition result is empty, FALSE otherwise */
- (BOOL)isEmpty; // is result empty

- (id)initWithText:(NSString*)text andConfidence:(NSNumber *)confidence;

@end



/** The KIOSRecognizer class manages recognizer resources. You typically initiate
 the recognizer at the startup time using initWithType method and then call
 sharedInstance method whenever you need to access the recognizer.
 
 KIOSRecognizer delegate methods, defined by KIOSRecognizerDelegate allow an 
 object to receive recognition results via callbacks.
 
 @warning Only a single instance of the recognizer can exist at any given time.
 
 @warning When initializing the recognizer, make sure that the bundle folder
 contains all the necessary resources needed for the specific recognizer type
 
 @warning Language model (HCLG.fst file) is currently assumed to exist in the
 bundle folder. Future releases will allow changing the model, as well as provide
 methods to dynamically create it.
 */
@interface KIOSRecognizer : NSObject

// set to true if you want to keep audio recordings
@property(nonatomic, assign) BOOL createAudioRecordings;
@property(nonatomic, copy) NSString *recordingsDir;
@property(nonatomic, readonly) NSString *lastRecordingFilename;


/** Initialize ASR engine with the specific recognizer type. This method needs
 to be called first, before any other work can be performed.
 
 @param recognizerType one of KIOSRecognizerType
 @param bundle folder containing all the resources necessary for the specific
 recognizer type. This will typically include all acoustic model related files
 and HCLG.fst file. Bundle should have a decode.conf configuration file.
 You can extend decode.conf file with additional Kaldi-specific config params.
 Currently, that is the only way to pass various settings to Kaldi.
 
 @return TRUE if succesful, FALSE otherwise.
 
 @warning
 
 @warning Currently, there is no mechanism to initialize a different recognizer 
 once this method is called.
 */
+ (BOOL)initWithType:(KIOSRecognizerType)recognizerType andBundle:(NSString *)bundle;


//+ (instancetype) alloc  __attribute__((unavailable("alloc not available, call sharedInstance instead")));
//- (instancetype) init   __attribute__((unavailable("init not available, call sharedInstance instead")));
+ (instancetype) new    __attribute__((unavailable("new not available, call sharedInstance instead")));

/** Returns shared instance of the recognizer
 
 @return The shared recognizer instance (KIOSGMMRecognizer or KIOSNNetRecognizer)
 
 @warning if initWithType has not been called, this method will return nil
 */
+ (instancetype)sharedInstance;


/** Start processing incoming audio.
 @return TRUE if successful, FALSE otherwise
*/
- (BOOL)startListening;

/** Stop the recognizer from processing incoming audio.
 @return TRUE if successful, FALSE otherwise
 @warning Currently, calling this method will not trigger recognizerFinalResult
 delegate call
 */
- (BOOL)stopListening;

// TODO
//- (BOOL)stopListeningWithDelay:(float)delay;


/** The most recent signal input level in dB

 @return signal input level in dB
 */
- (float)inputLevel;

@end



/** The KIOSRecognizerDelegate protocal defines optional methods implemented by
 delegates of the KIOSRecognizer class.
 */
@protocol KIOSRecognizerDelegate <NSObject>

@optional
/** This method is called whenever recognizer has new (different than before)
 partial recognition result. 
 
 @param recognizer recognizer that produced the result
 @param partial result result of the recognition
 
 */
- (void)recognizerPartialResult:(KIOSRecognizer *)recognizer result:(KIOSResult *)result;


/** This method is called when recognizer has finished the recognition on its 
 own because one of the VAD rules has triggered. 

 @param recognizer recognizer that produced the result
 @param result final result of the recognition
 */
- (void)recognizerFinalResult:(KIOSRecognizer *)recognizer result:(KIOSResult *)result;

@end




#endif /* KIOSRecognizer_h */
