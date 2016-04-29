//
//  KIOSRecognizer.h
//  KIOS
//
//  Created by Ognjen Todic on 2/29/16.
//  Copyright © 2016 Keen Research. All rights reserved.
//

#ifndef KIOSRecognizer_h
#define KIOSRecognizer_h

@class KIOSRecognizer;



/** These constants indicate the type of recognizers you are creating.*/
typedef NS_ENUM(NSInteger, KIOSRecognizerType) {
  /** Gaussian Mixture Model Kaldi Recognizer */
  KIOSRecognizerTypeGMM,
  /** NNet2 Kaldi Recognizer */
  KIOSRecognizerTypeNNet
};


/*  ################## KIOSResult #############*/


/**  An instance of the KIOSResult class, called recognition results, provides
 results of the recognition.*/
@interface KIOSResult : NSObject

/** recognition result text */
@property(nonatomic, readonly) NSString *text;
/** recognition result clean text; all tokens of type \<TOKEN\> are removed
 (e.g. <spoken_noise>, etc.)  */
@property(nonatomic, readonly) NSString *cleanText;
/** Confidence of the overall result (TODO - more details on the method) */
@property(nonatomic, readonly) NSNumber *confidence;

/** Returns TRUE if recognition result is empty, FALSE otherwise */
- (BOOL)isEmpty; // is result empty

- (id)initWithText:(NSString*)text andConfidence:(NSNumber *)confidence;

@end



/*  ################## KIOSRecognizerDelegate #############*/


/** The KIOSRecognizerDelegate protocol defines optional methods implemented by
 delegates of the KIOSRecognizer class.
 
 Partial recognition result is a result that's reported while recognition is still
 in progress.
 
 Final recognition result is a result that's reported after the engine determined
 that there hasn't been any voice activity for a predefined duration of time 
 (2sec). TODO - future releases will allow dynamic configuration of the end timeout 
 VAD property.
 
 */
@protocol KIOSRecognizerDelegate <NSObject>

@optional
/** This method is called whenever recognizer has a new (different than before)
 partial recognition result. Internal timer that runs every 100ms checks for the 
 partial results and calls this method if result is different than before.
 
 @param result partial result of the recognition
 @param recognizer recognizer that produced the result
 
 */
- (void)recognizerPartialResult:(KIOSResult *)result
                  forRecognizer:(KIOSRecognizer *)recognizer;


/** This method is called when recognizer has finished the recognition on its
 own because one of the VAD rules has triggered.
 
 @param result final result of the recognition
 @param recognizer recognizer that produced the result
 */
- (void)recognizerFinalResult:(KIOSResult *)result
                forRecognizer:(KIOSRecognizer *)recognizer;

@end



/*  ################## KIOSRecognizer #############*/

/** An instance of the KIOSRecognizer class, called recognizer, manages recognizer resources and provides speech recognition capabilities in your application.
 
 You typically initiate the engine at the app startup time by calling `+initWithRecognizerType:andASRBundle:andDecodingGraph:` method,  and then use sharedInstance method when you need to access the recognizer.
 
 You can implement a delegate object for a recognizer to respond to partial or final recognition results. For more details refer to KIOSRecognizerDelegate protocol,
 
 Initialization example:
 
     if (! [KIOSRecognizer sharedInstance]) {
       [KIOSRecognizer initWithRecognizerType:KIOSRecognizerTypeGMM andASRBundle:@"librispeech-gmm" andDecodingGraph:@"librispeech-gmm/HCLG.fst"];
       [KIOSRecognizer sharedInstance].createAudioRecordings = FALSE;
     }
     // our class keeps a local reference of the recognizer (not necessary)
     self.recognizer = [KIOSRecognizer sharedInstance];
     self.recognizer.delegate = self;
     self.recognizer.createAudioRecordings = YES;
 
 @warning Only a single instance of the recognizer can exist at any given time.
 
 
 */
@interface KIOSRecognizer : NSObject 

/** @name Properties */

/** Returns shared instance of the recognizer
 @return The shared recognizer instance
 @warning if the engine has not been initialized by calling `+initWithRecognizerType:andASRBundle:andDecodingGraph:`, this method will return nil
 */
+ (KIOSRecognizer *)sharedInstance;

/** delegate, which handles KIOSRecognizerDelegate protocol methods */
@property(nonatomic, weak) id<KIOSRecognizerDelegate> delegate;

/** Is recognizer listening to and decoding the incoming audio. */
@property(assign, readonly) BOOL listening;

/** Relative path to the ASR bundle where acoustic models, config, etc. reside 
 */
@property(nonatomic, readonly) NSString *asrBundlePath;


/** @name Initialization, starting, and stopping recognition */


/** Initialize ASR engine with the specific recognizer type. This method needs
 to be called first, before any other work can be performed.
 
 @param recognizerType one of KIOSRecognizerType
 
 @param bundle directory containing all the resources necessary for the specific
 recognizer type. This will typically include all acoustic model related files, 
 configuration files and HCLG.fst file(s). Directory should contain decode.conf 
 configuration file, which can be extended with additional Kaldi-specific config 
 params. Currently, that is the only way to pass various settings to Kaldi. All
 path references in config files should be relative to the app root directory
 (i.e. librispeech-gmm-en-us/mfcc.conf)
 
 @param pathToDecodingGraph relative path to the decoding graph. This will
 usually be <ASR_BUNDLE_NAME>/HCLG.fst or similar.
 
 @return TRUE if succesful, FALSE otherwise.
 
 @warning When initializing the recognizer, make sure that the bundle directory
 contains all the necessary resources needed for the specific recognizer type
 */
+ (BOOL)initWithRecognizerType:(KIOSRecognizerType)recognizerType andASRBundle:(NSString *)bundle andDecodingGraph:(NSString*)pathToDecodingGraph;


//+ (instancetype) alloc  __attribute__((unavailable("alloc not available, call sharedInstance instead")));
//- (instancetype) init   __attribute__((unavailable("init not available, call sharedInstance instead")));
+ (instancetype) new    __attribute__((unavailable("new not available, call sharedInstance instead")));



/** Start processing incoming audio.
 @return TRUE if successful, FALSE otherwise
 
 After calling this method, recognizer will listen and decode audio coming through
 the microphone. The process will stop either by explicit call to stopListening or
 if VoiceActivityDetection module rules are triggered (for example, max duration 
 without speech, or end-silence, etc.). 
 
 VAD settings can currently be specified
 only via the decode.conf file in the ASR bundle. Future releases will expose 
 some of these parameters via the API.
*/
- (BOOL)startListening;


/** Start processing incoming audio using pathToDecodingGraphFile as a decoding graph.
 @param pathToDecodingGraphFile path to the HCLG file created with the ASR bundle
 used to initalize the engine
 @return TRUE if successful, FALSE otherwise
 
 */
- (BOOL)startListeningWithDecodingGraph:(NSString *)pathToDecodingGraphFile;


/** Stop the recognizer from processing incoming audio.
 @return TRUE if successful, FALSE otherwise
 @warning Currently, calling this method will not trigger recognizerFinalResult
 delegate call.
 */
- (BOOL)stopListening;

// TODO
//- (BOOL)stopListeningWithDelay:(float)delay;


/** @name File Audio Recording Management */

/** Set to true if you want to keep audio recordings in the file system. Default is FALSE. */
@property(nonatomic, assign) BOOL createAudioRecordings;

/** Directory in which recordings will be stored. Default is Library/Cache/KaldiIOS-recordings */
@property(nonatomic, copy) NSString *recordingsDir;

/** Filename of the last recording. If createAudioRecordings was set to TRUE, you
 can read the filename of the latest recording via this property. */
@property(nonatomic, readonly) NSString *lastRecordingFilename;


/** @name Other */

/** The most recent signal input level in dB

 @return signal input level in dB
 */
- (float)inputLevel;

/** relative path to the decoding graph */
- (NSString *)decodingGraphPath;


@end




#endif /* KIOSRecognizer_h */
