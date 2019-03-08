//
//  KIOSRecognizer.h
//  KeenASR
//
//  Created by Ognjen Todic on 2/29/16.
//  Copyright © 2016 Keen Research. All rights reserved.
//

#ifndef KIOSRecognizer_h
#define KIOSRecognizer_h

@class KIOSRecognizer;

// @name Constants

/** These constants indicate the type of recognizers you are creating. */
typedef NS_ENUM(NSInteger, KIOSRecognizerType) {
  /** Unknown Recognizer */
  KIOSRecognizerTypeUnknown = -1,
  /** Gaussian Mixture Model Recognizer */
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
  KIOSRecognizerLogLevelDebug=0,
  /** Log info messages and higher */
  KIOSRecognizerLogLevelInfo,
  /** Log only warnings or errors (default level)*/
  KIOSRecognizerLogLevelWarning,
};

/** These constants indicate the recognizer state */
typedef NS_ENUM(NSInteger, KIOSRecognizerState) {
  /** Recognizer is initialized but it needs decoding graph before if can start
   listening */
  KIOSRecognizerStateNeedsDecodingGraph=0,
  /** Recognizer is ready to start listening */
  KIOSRecognizerStateReadyToListen,
  /** Recognizer is actively listening. Any calls to startListening will be ignored */
  KIOSRecognizerStateListening,
  /** Recognizer is not acquiring incoming audio any more, it is processing the 
   final result.
   Note that in realistic scenarios recognizer is not likely to be in this state 
   for a long time (usuaully 200-300ms). Long processing times may indicate that
   the SDK is running on devices which cannot keep up with the processing, or
   some type of misconfiguration.
   */
  KIOSRecognizerStateFinalProcessing,
};


/** These constants correspond to different Voice Activity Detection parameters
 that are used for endpointing during recognition.
 
 You can change values of these parameters using setVadParameter method.
 */
typedef NS_ENUM(NSInteger, KIOSVadParameter) {
  /** Timeout after this many seconds even if nothing has been recognized. 
   Default is 10 seconds. */
  KIOSVadTimeoutForNoSpeech=0,

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

/**  An instance of the KIOSResult class, called recognition result, provides
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

/** Name of the decoding graph used to perform recognition */
@property(nonatomic, copy, nullable) NSString *decodingGraphName;

/** Name of the ASR bunde used to perform recognition */
@property(nonatomic, copy, nullable) NSString *asrBundle;

/** Returns TRUE if recognition result is empty, FALSE otherwise */
- (BOOL)isEmpty;

- (nonnull NSString *)description;

/** JSON representation of the KIOSResult. Example:
    {
      "words" : [
      {
        "startTime" : 0.52,
        "duration" : 0.3,
        "confidence" : 1,
        "text" : "GO"
      },
      {
        "startTime" : 0.82,
        "duration" : 0.3,
        "confidence" : 1,
        "text" : "UP"
      }
      ],
      "confidence" : 1,
      "cleanText" : "GO UP",
      "text" : "GO UP <SPOKEN_NOISE>"
    }
 */
- (nullable NSString *)toJSON;

- (nullable NSDictionary *)toDictionary;

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

/** False for real words, TRUE for tags, e.g. <SPOKEN_NOISE>, <LAUGHTER> */
@property (nonatomic, assign, readonly, getter=isTag) BOOL tag;

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

/** @name Mandatory callback methods */

/**
 This method is called when audio interrupt occurs. It will be called in synchronous
 manner immediately before KIOSRecognizer starts unwinding its audio stack. You
 would use this method to stop playing any audio that is controlled directly by
 your app. Your app should not modify AVAudioSession state nor interact with the
 recognizer at this point.
 
 @warning NOTE: this method will be called during app wind-down when audio
 interrupt occurs or the app goes to the background. It is crucial that this method
 performs quickly, otherwise KIOSRecognizer may not have sufficient time to properly
 unwind its audio stack before the app goes to background.
 */
- (void)unwindAppAudioBeforeAudioInterrupt;

/** @name Optional callback methods */

@optional
/** This method is called when trigger phrase has been recognized (in case decoding graph was
 built with trigger phrase support).
 
 @param recognizer recognizer that recognized the trigger phrase
 
 */
- (void)recognizerTriggerPhraseDetectedForRecognizer:(nonnull KIOSRecognizer *)recognizer;


/** This method is called when recognizer has a new (different than before)
 partial recognition result. If decoding graph was built with trigger phrase support
 this method will not be called until trigger phrase occurs.
 
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


/** This method is called when recognizer is ready to listen again, after being 
 interrupted due to audio interrupt (incoming call, etc.) or because the app went 
 to the background. See KIOSRecognizer for more details on handling interrupts.
 You will typically setup UI elements in this callback (e.g. enable "Start Listening"
 button), or explictly call startListening if your app is expected to listen as 
 soon as the view has appeared.
 
 @param recognizer the recognizer
 
 @warning NOTE: this callback indicates readiness to listen from audio setup 
 point of view. If you initialized a recognizer, but didn't fully prepare it for
 listening (via prepareForListening: method), this callback will still trigger
 when audio interrupt ends.
 */
- (void)recognizerReadyToListenAfterInterrupt:(nonnull KIOSRecognizer *)recognizer;


///** This method is called after an interrupt has ended and KIOSRecognizer
// is about to re-init its audio stack. This callback will be called *before*
// KIOSRecognizer audio stack is reinitialized and you would use it to setup your
// own audio stack, if necessary.
// 
// */
//- (void)setupAppAudioAfterInterrupt;


@end



/*  ################## KIOSRecognizer #############*/

/** An instance of the KIOSRecognizer class, called recognizer, manages 
 recognizer resources and provides speech recognition capabilities to your 
 application.
 
 You typically initialize the engine at the app startup time by calling
 `+initWithASRBundle:` or `+initWithASRBundleAtPath:` method, and
 then use sharedInstance method when you need to access the recognizer.
 
 Recognition results are provided via callbacks. To obtain results one of your
 classes will need to adopt a 
 [KIOSRecognizerDelegate protocol](KIOSRecognizerDelegate), and implement some 
 of its methods.
 
 In order to properly handle audio interrupts you will need to implement
  [KIOSRecognizerDelegate recognizerReadyToListenAfterInterrupt:] callback method 
 in which you need to perform audio play cleanup (stop playing audio). This allows KeenASR
 SDK to properly deactivate audio session before app goes to background.
 
 You can optionally implement [KIOSRecognizerDelegate recognizerReadyToListenAfterInterrupt:] callback method, which will trigger after KIOSRecognizer is fully setup after
 app comes to the foreground. This is where you may refresh the UI state of the app.
 
 Initialization example:
 
     if (! [KIOSRecognizer sharedInstance]) {
         [KIOSRecognizer initWithASRBundle:@"librispeechQT-nnet2-en-us"];
     }
     // for convenience our class keeps a local reference of the recognizer
     self.recognizer = [KIOSRecognizer sharedInstance];
 
     // this class will also be implementing methods from KIOSRecognizerDelegate 
     // protocol
     self.recognizer.delegate = self;
 
     // recordings will be saved on the device
     self.recognizer.createAudioRecordings = YES;
 
     // after 0.8sec of silence, recognizer will automatically stop listening
     [self.recognizer setVADParameter:KIOSVadTimeoutEndSilenceForGoodMatch toValue:.8];

     // define callbacks for KIOSRecognizerDelegate
 
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
 `+initWithASRBundle:`, this method will return nil
 */
+ (nullable KIOSRecognizer *)sharedInstance;



/** Delegate, which handles KIOSRecognizerDelegate protocol methods */
@property(nonatomic, weak, nullable) id<KIOSRecognizerDelegate> delegate;

/** State of the recognizer, a read-only property that takes one of KIOSRecognizerState values
 */
@property(assign, readonly) KIOSRecognizerState recognizerState;

/** Absolute path to the ASR bundle where acoustic models, config, etc. reside
 */
@property(nonatomic, readonly, nonnull) NSString *asrBundlePath;

/** Name of the ASR Bundle (name of the directory that contains all the ASR 
 resources. This will be the last component of the asrBundlePath.
 */
@property(nonatomic, readonly, nonnull) NSString *asrBundleName;

/** Name of the decoding graph currently used by the recognizer */
@property(nonatomic, readonly, nullable) NSString *currentDecodingGraphName;

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


/** Initialize ASR engine with the ASR Bundle, which provides all the
 resources necessary for initialization. You will use this initalization method 
 if you included ASR bundle with your application. See also initWithASRBundleAtPath:
 for scenarios when ASR Bundle is not included with the app, but downloaded after
 the app has been installed. SDK initialization needs to occur before any  other
 work can be performed.
 
 @param bundleName name of the ASR Bundle. A directory containing all the resources
 necessary for the specific recognizer type. This will typically include all 
 acoustic model related files, and configuration files. The bundle directory 
 should contain decode.conf configuration file, which can be augmented with 
 additional config params. Currently, that is the only way to pass various 
 settings to the decoder. All path references in config files should be relative 
 to the app root directory (e.g. librispeechQT-nnet2-en-us/mfcc.conf). The init 
 method will initiallize appropriate recognizer type based on the name and 
 content of the ASR bundle.
 
 @return TRUE if succesful, FALSE otherwise.
 
 @warning When initializing the recognizer, you need to make sure that bundle
 directory contains all the necessary resources needed for the specific 
 recognizer type. If your app is dynamically creating decoding graphs, ASR 
 bundle directory needs to contain lang subdirectory with relevant resources 
 (lexicon, etc.).
 */

+ (BOOL)initWithASRBundle:(nonnull NSString *)bundleName;


/** Initialize ASR engine with the ASR Bundle located at provided path. This is
 an alternative method to initialize the SDK, which you would use if you did not
 package ASR Bundle with your application but instead downloaded it after the
 app has been installed. SDK initialization needs to occur before any  other
 work can be performed.
 
 @param pathToASRBundle full path to the ASR Bundle. For more details about ASR 
 Bundles see initWithASRBundle:
 
 @return TRUE if succesful, FALSE otherwise.
 
 @warning When initializing the recognizer, make sure that the bundle directory
 contains all the necessary resources needed for the specific recognizer type.
 If your app is dynamically creating decoding graphs, ASR bundle directory needs
 to contain lang subdirectory with relevant resources (lexicon, etc.).
 */

+ (BOOL)initWithASRBundleAtPath:(nonnull NSString *)pathToASRBundle;


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
 through the microphone using decoding graph you specified via one of the 
 prepareForListening methods. The listening process will stop either by: a) an 
 explicit call to stopListening or b) if one of the Voice Activity Detection 
 module rules are triggered (for example, max duration without speech, or 
 end-silence, etc.), c) if audio interrupt occurs (phone call, audible
 notification, app goes to background, etc.).
 
 When the recognizer stops listening due to VAD triggering, it will call 
 [recognizerFinalResult:forRecognizer:]([KIOSRecognizerDelegate recognizerFinalResult:forRecognizer:]) 
 callback method.
 
 When the recognizer stops listening due to audio interrupt, *no callback methods*
 will be triggered until audio interrupt is over.
 
 If decoding graph was created with the trigger phrase support recognizer will listen
 continuously until the trigger phrase is recognized, then it will switch over to the
 standard mode with partial results being reported via
 [recognizerPartialResult:forRecognizer:]([KIOSRecognizerDelegate recognizerPartialResult:forRecognizer:]) callback.
 
 VAD settings can be modified via setVADParameter:toValue: method.
 
 @warning You will need to call either [prepareForListeningWithCustomDecodingGraphWithName]([KIOSRecognizer prepareForListeningWithCustomDecodingGraphWithName:])
 or [prepareForListeningWithCustomDecodingGraphAtPath]([KIOSRecognizer prepareForListeningWithCustomDecodingGraphAtPath:]) before calling this method.
 You will also need to make sure that user has granted audio recording permission
 before calling this method; see AVAudioSessionRecordPermission and [AVAudioSession requestRecordPermission:] in AVFoundation framework for details.
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
 limit the length to 200sec. If file is longer than 200sec no processing will
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
 noticable delay (few hundred ms) on lower-end devices. This method will return nil
 if recognizer is already in KIOSRecognizerStateFinalProcessing (due to VAD rules
 automatically triggering for example).
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


/*
 @name Audio Interruption Management
 When audio interruption occurs, due to a phone call, SMS, etc.  SDK will
 automatically stop listening if necessary, and tear down the internal audio setup.
 When interrupt ends audio will be automatically reinitialized. You can define
 a callback method recognizerReadyToListenAfterInterrupt: to track when these
 changes happen.
*/

/**
 */
//- (void)audioInterruptionEndedHandler:(nonnull void (^)(void))callbackBlock;


/** @name File Audio Recording Management */

/** Set to true if you want to keep audio recordings in the file system. Default is FALSE. */
@property(nonatomic, assign) BOOL createAudioRecordings;

/** Set to FALSE if you do NOT want to keep response metadata in the file system.
 *
 * When set to TRUE, KIOSRecognizer instance will store a JSON file with various
 * metadata (speech recognition result, basic device info, etc.) on device
 * filesystem. If you are using Keen Dashboard cloud service via KIOSUploader
 * this flag needs to be set to true, otherwise no data will be stored locally
 * on the device, and consequently pushed to the cloud.
 *
 * Default is TRUE.
 */
@property(nonatomic, assign) BOOL createJSONMetadata;

/** Directory in which recordings and JSON metadata will be stored.
 Default is Library/Cache/keenasr-data/ */
@property(nonatomic, copy, readonly, nonnull) NSString *recordingsDir;

/** Filename of the last recording. If createAudioRecordings was set to TRUE, you
 can read the filename of the latest recording via this property. */
@property(nonatomic, readonly, nullable) NSString *lastRecordingFilename;

/** Filename of the last JSON metadata file. If createJSONMetadata was set to
 TRUE, you can read the filename of the latest JSON metadata file via this
 property. */
@property(nonatomic, readonly, nullable) NSString *lastJSONMetadataFilename;


/** @name Audio Handling */
/**
 If set to YES (default behavior), SDK will handle various notifications
 related to app activity. When app goes to background, or a phone call or a
 audio interrupt comes through, the SDK will stop listening, teardown internal
 audio stack, and then upon app coming back to foreground/interrupt
 ending it will reinitialize internal audio stack.
 
 If set to NO, it is developer's responsibility to handle notifications that may
 affect audio capture. In this case, you will need to stop listening and deactivate
 KeenASR audio stack if an audio interrupt comes through, and then
 reinit the audio stack when the interrupt is over. Setting handleNotifications
 to NO allows the SDK to work in the background mode; you will still need to
 properly handle audio interrupts using deactivateAudioStack,
 activateAudioStack or reinitAudioStack, and stopListening methods.
 */
@property(nonatomic, assign, setter=setHandleNotifications:) BOOL handleNotifications;


/** The most recent signal input level in dB

@return signal input level in dB
*/
- (float)inputLevel;

/** Provides information about echo cancellation support on the device.
 
 @return YES if echo cancellation is supported, NO otherwise
 
 */
+ (BOOL)echoCancellationAvailable;


/** *EXPERIMENTAL* Specifies if echo cancellation should be performed. If value
 is set to YES and the device supports echo cancellation, then audio played by
 the application will be removed from the audio captured via the microphone.
 
 @param value set to YES to turn on echo cancellation processing, NO to turn it
 off. Default is NO.
 
 @return TRUE if value was successfully set, FALSE otherwise. If the device does not
 support echo cancellatio and you pass YES to this method, it will return FALSE.
 
 @warning Calls to this method while the recognizer is listening will be ignored
 end the method will return FALSE.
 
 */
- (BOOL)performEchoCancellation:(BOOL)value;



/** Enables bluetooth output via AVAudioSessionCategoryOptionAllowBluetoothA2DP
 category option of AVAudioSession.
 
 @warning: This will force AVAudioSession to use A2DP output by disabling
 general (HPC) Bluetooth This setting is only available in iOS 10 and later.
 */
- (void)enableBluetoothA2DPOutput:(BOOL)value;


- (void)enableBluetoothOutput:(BOOL)value __attribute__((deprecated("use enableBluetoothA2DPOutput instead")));


/**
 Deactivates audio session and KeenASR audio stack. If handleNotifications is set
 to YES, you will not need to use this method and its counterpart
 activateAudioStack; KeenASR Framework will handle audio interrupts and
 notifications when the app goes to background/foreground.
 
 If your app is handling notifications explicitly (handleNotifications is set to
 NO), you may want to call this method when an audio interrupt occurs. If recognizer
 is listening, this method will automatically stop listening, and then deactivate the
 audio stack. When the app comes active or audio interrupt finishes, you will need to
 call the activateAudioStack.
 */
- (void)deactivateAudioStack;


 /**
  Activates audio stack that was previously deactivated using
  deactivateAudioStack method. This method should be called *after* all other
  audio systems have been setup to make sure AVAudioSession is properly
  initialized for audio capture.
 */
- (BOOL)activateAudioStack;

/**
 Reinitializes audio stack. Calling this method is equaivalent to calling
 deactivateAudioStack followed by activateAudioStack method.
 */
- (void) reinitAudioStack;



/** @name Other */

/** Version of the KeenASR framework. */
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

/** @name Deprecated methods and properties */

/** Is recognizer listening to and decoding the incoming audio. 
 This property has been deprecated and replaced by recognizerState.
 */
@property(assign, readonly) BOOL listening __attribute__((deprecated("use recognizerState method")));



@end

#endif /* KIOSRecognizer_h */
