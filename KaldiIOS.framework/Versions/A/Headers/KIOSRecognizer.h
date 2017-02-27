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

// @name Constants

/** These constants indicate the type of recognizers you are creating.
 */
typedef NS_ENUM(NSInteger, KIOSRecognizerType) {
  /** Unknown Recognizer */
  KIOSRecognizerTypeUnknown = -1,
  /** Gaussian Mixture Model Kaldi Recognizer */
  KIOSRecognizerTypeGMM,
  /** NNet2 Kaldi Recognizer */
  KIOSRecognizerTypeNNet,
  /** NNet3 Kaldi Recognizer */
  KIOSRecognizerTypeNNet3,
  /** NNet3 Chain Kaldi Recognizer */
  KIOSRecognizerTypeNNet3Chain
};

/** These constants indicate the log levels for the framework.*/
typedef NS_ENUM(NSInteger, KIOSRecognizerLogLevel) {
  /** Log debug messages and higher */
  KIOSRecognizerLogLevelDebug,
  /** Log info messages and higher */
  KIOSRecognizerLogLevelInfo,
  /** Log only warnings or errors (default level)*/
  KIOSRecognizerLogLevelWarning,
};


/** These constants correspond to different Voice Activity Detection parameters
 that are used for endpointing during recognition.
 
 You can change values of these parameters using setVadParameter method.
 */
typedef NS_ENUM(NSInteger, KIOSVadParameter) {
  /** Timeout after this many seconds even if nothing has been recognized. 
   Default is 10 seconds. */
  KIOSVadTimeoutForNoSpeech,

  /** Timeout after this many seconds if we had a good (high probability) 
   match to the final state. Default is 1 second. */
  KIOSVadTimeoutEndSilenceForGoodMatch,
  
  /** Timeout after this many seconds if we had any match (even if final state
   has not been reached). Default is 2 seconds. */
  KIOSVadTimeoutEndSilenceForAnyMatch,

  /** Timeout after this many seconds regardless of what has been recognized. 
   This is effectively upper bound on the duration of recognition. Default 
   value is 20 seconds. */
  KIOSVadTimeoutMaxDuration
};



/*  ################## KIOSResult #############*/

@class KIOSWord;

/**  An instance of the KIOSResult class, called recognition results, provides
 results of the recognition.*/
@interface KIOSResult : NSObject

/** recognition result text */
@property(nonatomic, readonly, nonnull) NSString *text;

/** recognition result clean text; all tokens of type \<TOKEN\> are removed
 (e.g. <SPOKEN_NOISE>, etc.)  */
@property(nonatomic, readonly, nonnull) NSString *cleanText;

/** Confidence of the overall result */
@property(nonatomic, readonly, nullable) NSNumber *confidence;

/** Array of KIOSWord objects */
@property(nonatomic, strong, nullable) NSArray<KIOSWord *> *words;

/** Returns TRUE if recognition result is empty, FALSE otherwise */
- (BOOL)isEmpty;

- (nonnull NSString *)description;

@end

/** An instance of the KIOSWord class, called word, provides word text, timing
 information, and the confidence of the word 
 
 Note that in certain circumstances startTime, duration, and confidence may be
 nil.
 
 */
@interface KIOSWord : NSObject
/** Text of the word */
@property (nonatomic, readonly, nonnull) NSString *text;

/** Start time, in seconds, for this word */
@property (nonatomic, strong, nullable, readonly) NSNumber *startTime;

/** Duration of the word, in seconds */
@property (nonatomic, strong, nullable, readonly) NSNumber *duration;

/** Confidence in the range 0 to 1 for the word. Higher value corresponds to
 better confidence that the recognized text matches what was said. */
@property (nonatomic, strong, nullable, readonly) NSNumber *confidence;

- (nullable id)initWithText:(nonnull NSString *)text
               andStartTime:(nullable NSNumber *)startTime
                andDuration:(nullable NSNumber *)duration
              andConfidence:(nullable NSNumber *)confidence;

- (nonnull NSString *)description;

@end

/*  ################## KIOSRecognizerDelegate #############*/


/** The KIOSRecognizerDelegate protocol defines optional methods implemented by
 delegates of the KIOSRecognizer class.
 
 Partial recognition result is a result that's periodically (100ms or so) 
 reported while recognition is still in progress.
 
 Final recognition result is a result that's reported after the engine determined
 that there hasn't been any voice activity for a predefined duration of time, as
 specifed by VAD endpointing settings.
 */
@protocol KIOSRecognizerDelegate <NSObject>

@optional
/** This method is called when recognizer has a new (different than before)
 partial recognition result. Internal timer that runs every 100ms checks for the 
 partial results and calls this method if result is different than before.
 
 @param result partial result of the recognition
 @param recognizer recognizer that produced the result
 
 */
- (void)recognizerPartialResult:(nonnull KIOSResult *)result
                  forRecognizer:(nonnull KIOSRecognizer *)recognizer;


/** This method is called when recognizer has finished the recognition on its
 own because one of the VAD rules has triggered. At this time, recognizer is not
 listening any more.
 
 @param result final result of the recognition
 @param recognizer recognizer that produced the result
 */
- (void)recognizerFinalResult:(nonnull KIOSResult *)result
                forRecognizer:(nonnull KIOSRecognizer *)recognizer;

@end



/*  ################## KIOSRecognizer #############*/

/** An instance of the KIOSRecognizer class, called recognizer, manages 
 recognizer resources and provides speech recognition capabilities to your 
 application.
 
 You typically initiate the engine at the app startup time by calling
 `+initWithASRBundle:` or `+initWithASRBundle:andDecodingGraph:` method, and
 then use sharedInstance method when you need to access the recognizer.
 
 Recognition results are provided via callbacks. To obtain results one of your
 classes will need to adopt a 
 [KIOSRecognizerDelegate protocol](KIOSRecognizerDelegate), and implement some 
 of its methods.
 
 Initialization example:
 
     if (! [KIOSRecognizer sharedInstance]) {
         [KIOSRecognizer initWithASRBundle:@"librispeech-nnet2-en-us"];
     }
     // for convenience our class keeps a local reference of the recognizer
     self.recognizer = [KIOSRecognizer sharedInstance];
     self.recognizer.delegate = self;
     self.recognizer.createAudioRecordings = YES;

 After initialization, audio data from all sessions when recognizer is listening
 will be used for online speaker adaptation. You can name speaker adaptation
 profiles via adaptToSpeakerWithName:, persist profiles in the filesystem via
 saveSpeakerAdaptationProfile, and reset via resetSpeakerAdaptation.
 
 @warning Only a single instance of the recognizer can exist at any given time.
 */
@interface KIOSRecognizer : NSObject 


/** @name Properties */

/** Returns shared instance of the recognizer
 @return The shared recognizer instance
 @warning if the engine has not been initialized by calling 
 `+initWithASRBundle:andDecodingGraph:`, this method will return nil
 */
+ (nullable KIOSRecognizer *)sharedInstance;



/** delegate, which handles KIOSRecognizerDelegate protocol methods */
@property(nonatomic, weak, nullable) id<KIOSRecognizerDelegate> delegate;

/** Is recognizer listening to and decoding the incoming audio. */
@property(assign, readonly) BOOL listening;

/** Relative path to the ASR bundle where acoustic models, config, etc. reside 
 */
@property(nonatomic, readonly, nonnull) NSString *asrBundlePath;

/**
 Type of the recognizer. It makes sense to query this property only after the
 recognizer has been initialized.
 */
@property(nonatomic, assign, readonly) KIOSRecognizerType recognizerType;

/**
 If set to YES, recognizer will perform rescoring for the final result, using
 rescoring language model provided in the custom decoding graph that's bundled
 with the application.
 
 Default is YES.
 
 @warning If the resources necessary for rescoring are not available in the custom
 decoding graph directory bundled with the app, and rescore is set to YES, 
 rescoring step will be skipped.
 */
@property(nonatomic, assign) BOOL rescore;

/** @name Initialization, Preparing, Starting, and Stopping Recognition */


/** Initialize ASR engine with the specific ASR Bundle, which provides all the 
 resources necessary for initialization. This method needs to be called first, 
 before any other work can be performed. You would use this init method if you 
 are planning to dynamically build decoding graphs in your app.
 
 @param bundle directory containing all the resources necessary for the specific
 recognizer type. This will typically include all acoustic model related files,
 and configuration files. The bundle directory should contain decode.conf 
 configuration file, which can be augmented with additional Kaldi-specific 
 config params. Currently, that is the only way to pass various settings to Kaldi.
 All path references in config files should be relative to the app root directory
 (e.g. librispeech-gmm-en-us/mfcc.conf). The init method will initiallize
 appropriate recognizer type based on the name and content of the ASR bundle.
 
 @return TRUE if succesful, FALSE otherwise.
 
 @warning When initializing the recognizer, make sure that the bundle directory
 contains all the necessary resources needed for the specific recognizer type. 
 If your app is dynamically creating decoding graphs, ASR bundle directory needs
 to contain lang subdirectory with relevant resources (lexicon, etc.).
 */

+ (BOOL)initWithASRBundle:(nonnull NSString *)bundle;


//+ (instancetype) alloc  __attribute__((unavailable("alloc not available, call sharedInstance instead")));
//- (instancetype) init   __attribute__((unavailable("init not available, call sharedInstance instead")));
+ (nullable instancetype) new    __attribute__((unavailable("new not available, call sharedInstance instead")));


/** Prepare for recognition by loading custom decoding graph that was prepared
 via [KIOSDecodingGraph createDecodingGraphFromSentences:forRecognizer:andSaveWithName:] 
 or [KIOSDecodingGraph createDecodingGraphFromArpaFileAtURL:forRecognizer:andSaveWithName:] methods.
 
 After calling this method, recognizer will load the decoding graph into memory
 and it will be ready to start listening via startListening method.
 
 @param dgName name of the custom decoding graph
 @return TRUE if successful, FALSE otherwise
 */
- (BOOL)prepareForListeningWithCustomDecodingGraphWithName:(nonnull NSString *)dgName;


/** Prepare for recognition by loading custom decoding graph that was bundled 
 with the application. You will typically use this approach for large vocabulary
 tasks, where it would take too long to build the decoding graph on the mobile
 device.
 
 After calling this method, recognizer will load the decoding graph into memory
 and it will be ready to start listening via startListening method.
 
 @param pathToDecodingGraphDirectory absolute path to the custom decoding graph
 directory which was created ahead of time and packaged with the app.
 
 @return TRUE if successful, FALSE otherwise.
 
 @warning If custom decoding graph was built with rescoring capability, all the 
 resources will be loaded regardless of how rescore paramater is set.
 */
- (BOOL)prepareForListeningWithCustomDecodingGraphAtPath:(nonnull NSString *)pathToDecodingGraphDirectory;


/** Start processing incoming audio.
 @return TRUE if successful, FALSE otherwise
 
 After calling this method, recognizer will listen to and decode audio coming
 through the microphone. The process will stop either by explicit call to
 stopListening or if one of the Voice Activity Detection module rules are 
 triggered (for example, max duration without speech, or end-silence, etc.).
 
 When the recognizer stops listening due to VAD triggering, it will call 
 [recognizerFinalResult:forRecognizer:]([KIOSRecognizerDelegate recognizerFinalResult:forRecognizer:]) 
 callback method.
 
 VAD settings can be modified via setVADParameter:toValue: method.
 
 @warning You will need to call either prepareForListeningWithCustomDecodingGraphWithName:
 or prepareForListeningWithCustomDecodingGraphAtPath: before calling startListening
 method.
*/
- (BOOL)startListening;




/**
 Performs speech recognition on the audio file. This is an asynchronious method,
 which will perform basic validation (valid wav file, sampling frequency of the 
 audio matches that of the ASR Bundle), and then start recognition in the 
 background and return. Recognition results can be obtained via [recognizerFinalResult:forRecognizer:]([KIOSRecognizerDelegate recognizerFinalResult:forRecognizer:]) and [recognizerPartialResult:forRecognizer:]([KIOSRecognizerDelegate recognizerPartialResult:forRecognizer:]) methods.
 
 @param pathToAudioFile full path to the audio file in WAV format. Files should
 be mono (single channel) and its sampling frequency should match the sampling
 frequency used for the ASR bundle training (typically 16kHz).
 
 @return TRUE if the audio file is valid WAV file, its sampling frequency
 matches the one in ASR Bundle, and recording duration is less than 100ms,
 FALSE otherwise.
 
 @note The whole audio file will be loaded in the memory, thus we currently
 limit the length to 100sec. If file is longer than 100sec no processing will
 occur and the method will return FALSE.
 */
- (BOOL)startListeningFromAudioFile:(nonnull NSString *)pathToAudioFile;


/** Stop the recognizer from processing incoming audio.
 @warning Calling this method will not trigger recognizerFinalResult
 delegate call. Use stopListeningAndReturnFinalResult if you are interested in 
 obtaining the final result directly.
 */
- (void)stopListening;


/** Stop the recognizer from processing incoming audio and return the final result.
 @return Final result of the recognition.
 
 @warning This method runs synchroniously. For large decoding graphs there may be
 noticable delay (few hundred ms) on lower-end devices.
 */
- (nullable KIOSResult *)stopListeningAndReturnFinalResult;


/** @name Speaker Adaptation 
 */

/** Defines the name that will be used to uniquely identify speaker adaptation 
 profile. When recognizer starts to listen, it will try to find a matching
 speaker profile in the filesystem (profiles are matched based on speakername, 
 asrbundle, and audio route). When saveSpeakerAdaptationProfile method is called, 
 it uses the name to uniquely identify the profile file that will be saved in 
 the filesystem.
 
 @param speakerName (pseduo)name of the speaker for which adaptation is to be
 performed. Default value is 'default'.
 
 The name used here does not have to correspond to the real name of user (thus
 we call it pseudo name). The exact value does not matter as long as you can
 match the value to the specific user in your app. For example, you could use
 'user1', 'user2', etc..
 
 @warning If you cannot match names to your users, it's recommended to not use 
 this method, and to not save adaptation profiles between sessions. Adaptation 
 will still be performed throughout the session, but each new session (activity 
 after initialization of recognizer) will start from the baseline models.
 
 In-memory speaker adaptation profile can always be reset by calling 
 resetSpeakerAdaptation.
 
 If this method is called while recognizer is listening, it will only affect 
 subsequent calls to startListening methods.
 */
- (void)adaptToSpeakerWithName:(nonnull NSString *)speakerName;


/** Resets speaker adaptation profile in the current recognizer session. Calling
 this method will also reset the speakerName to 'default'. If the corresponding 
 speaker adaptation profile exists in the filesystem for 'default' speaker, it 
 will be used. If not, initial models from the ASR Bundle will be the baseline.

 You would typically use this method id there is a new start of a certain
 activity in your app that may entail new speaker. For example, a practice view
 is started and there is a good chance a different user may be using the app.
 
 If speaker (pseudo)identities are known, you don't need to call this method, you
 can just switch speakers by calling adaptToSpeakerWithName: with the 
 appropriate speakerName
 
 Following are the tradeoffs when using this method:
 
   - the downside of resetting user profile for the existing user is that ASR
     performance will be reset to the baseline (no adaptation), which may 
     slightly degrade performance in the first few interactions
 
   - the downside of NOT resetting user profile for a new user is that, depending
     on the characteristics of the new user's voice, ASR performance may 
     initially be degraded slightly (when comparing to the baseline case of no 
     adaptation)
 
 Calls to this method will be ignored if recognizer is in LISTENING state.
 
 If you are resetting adaptation profile and you know user's (pseudo)identity, 
 you may want to call saveSpeakerAdaptationProfile method prior to calling this 
 method so that on subsequent user switches, adaptation profiles can be reloaded 
 and recognition starts with the speaker profile trained on previous sessions 
 audio.
 
 */
- (void)resetSpeakerAdaptation;


/** Saves speaker profile (used for adaptation) in the filesystem.
 
 Speaker profile will be saved in the file system, 
 in Caches/KaldiIOS-speaker-profiles/ directory. Profile filename is composed of
 the speakerName, asrBundle, and audioRoute.
 */
- (void)saveSpeakerAdaptationProfile;



/**
 Remove all adaptation profiles for all speakers.
 */
+ (BOOL)removeAllSpeakerAdaptationProfiles;

/**
 Removes all adaptation profiles for the speaker with name speakerName.
 
 @param speakerName name of the speaker whose profiles should be removed
 */
+ (BOOL)removeSpeakerAdaptationProfiles:(nonnull NSString *)speakerName;



/** @name File Audio Recording Management */

/** Set to true if you want to keep audio recordings in the file system. Default is FALSE. */
@property(nonatomic, assign) BOOL createAudioRecordings;

/** Directory in which recordings will be stored. Default is Library/Cache/KaldiIOS-recordings */
@property(nonatomic, copy, nonnull) NSString *recordingsDir;

/** Filename of the last recording. If createAudioRecordings was set to TRUE, you
 can read the filename of the latest recording via this property. */
@property(nonatomic, readonly, nullable) NSString *lastRecordingFilename;


/** @name Other */

/** The most recent signal input level in dB

 @return signal input level in dB
 */
- (float)inputLevel;


/** Version of the KaldiIOS framework. */
+ (nonnull NSString *)version;


/** Set log level for the framework.
 
 @param logLevel one of KIOSRecognizerLogLevel
 
 Default value is KIOSRecognizerLogLevelWarning.
 */

+ (void)setLogLevel:(KIOSRecognizerLogLevel)logLevel;


/** @name Config Parameters */

/** Set any of KIOSVadParameter Voice Activity Detection parameters. These 
 parameters can be set at any time and they will go into effect immediately.
 
 @param parameter one of KIOSVadParameter
 @param value duration in seconds for the parameter
 
 @warning Setting VAD rules in the config file within the ASR bundle will **NOT**
 have any effect. Values for these parameters are set to their defaults upon
 initialization of KIOSRecognizer. They can only be changed programmatically, 
 using this method.
*/
- (void)setVADParameter:(KIOSVadParameter)parameter toValue:(float)value;


@end

#endif /* KIOSRecognizer_h */
