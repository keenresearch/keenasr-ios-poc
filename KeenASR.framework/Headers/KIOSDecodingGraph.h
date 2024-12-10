//
//  KIOSDecodingGraph.h
//  KeenASR
//
//  Created by Ognjen Todic on 5/17/16.
//  Copyright © 2016 Keen Research. All rights reserved.
//

#ifndef KIOSDecodingGraph_h
#define KIOSDecodingGraph_h

/** KIOSTask defines a type of speaking task that will be handled. It is primarily
 * used to indicate to methods that create decoding graphs what type of task they
 * need to handle, so that appropiate customization can be done when creating
 * language model and decoding graph
 */
typedef NS_ENUM(NSInteger, KIOSSpeakingTask) {
  /** Default task  (no prior knowledge exists about the type of spoken interaction) */
  KIOSSpeakingTaskDefault,
  /** Reading aloud in educational context (children, language learning) */
  KIOSSpeakingTaskOralReading,
//  /** Keyword spotting among small number (20-30) of words */
//  KIOSSpeakingTaskKeywordSpotting,
};

/** AlternativePronunciation is a class that defines mapping beween a word and its phonetic
 pronunciation. Phonetic pronunciation is a space separated string of phonemes that define how the word is
 pronounced. The names of the phonemes are defined in ASR Bundle lang/phones.txt file. For some languages
 for which this mapping is not deterministic, ASR Bundle will contain a large lookup table in lang/lexicon.txt file.
 
 You can use AlternativePronunciations to provide alternatives to existing pronunciations, to define
 pronunciations for the words that are not in the lexicon.txt file (including made-up words), or to provide
 common mispronunciations (which can be useful in some scenarios such as language learning and reading
 instruction); For the latter, you can also provide a tag when defining AlternativePronunciation; if such
 alternative pronunciation is recognized by the recognizer, the # symbol and the provided tag will be appended
 to the word in the result (e.g. "PEAK#WRONG", if the tag was set to "WRONG").
 
 Example:
 
 ```
    KIOSAlternativePronunciation *ap = [KIOSAlternativePronunciation new];
    ap.word = @"PEAK";
    ap.pronunciation = @"P IH0 K";
    ap.tag = @"WRONG";
 ```
 
 */
@interface KIOSAlternativePronunciation : NSObject

/**
 Name of the word.
 */
@property(nonatomic, strong, nonnull) NSString *word;

/**
 Phonetic transcription of a word, provided as a space-separated sequence of phones.
 */
@property(nonatomic, strong, nonnull) NSString *pronunciation;

/**
Optional value, which, if provided, will be appended together with the # symbol to the word if the variation of
 the word with the provided pronunciation is recognized. For example, PEAK#WRONG.
 */
@property(nonatomic, strong, nullable) NSString *tag;

@end


@class KIOSRecognizer;

/** KIOSDecodingGraph class manages decoding graphs in the filesystem.
 
 You can use  various KIOSDecodingGraph class methods to  create decoding graphs, which will be saved in
 the filesystem on the device. Typically, you will  provide a list of phrases to
 createDecodingGraphFromPhrases:forRecognizer:andSaveWithName: method, which will then create a
 decoding graph in the filesystem. Later on, you can refer  to the  decoding graph by its name.

 Contextual graphs are a composition of multiple decoding graphs in a single graph. If your application needs to
 create multiple decoding graphs often it may be more efficient to create a single contextual decoding graph
 instead and then switch the contexts as needed. A good example would be a digital book; each page presented
 to the user would be a single context and you would switch contexts as the app (or user) changes the pages.
 The trade-offs with contextual graphs is that creating one with N contexts will be much faster than creation of a
 single graph N times; the downside is that there will be a small penalty (delay of 100ms or so) when switching
 between different contexts.
 
 @note When dynamically creating decoding graphs, any words that do not have
 phonetic representation in the lexicon (`ASRBUNDLE/lang/lexicon.txt`) will be
 assigned one algorithmically. For English langauge algorithmic representation is
 imperfect, thus you should aim to use KIOSAlternative prounciations to augment the  lexicon with
 words that are likely to be encountered in your app. For example, if your app is dealing with ASR of names
 you would augment the lexicon with additional names and their proper  pronunciation before releasing your app.

 @note For the large number of phrases (e.g. several thousands), creating of decoding graph can
 take several seconds on older devices.
 
 @note Decoding graphs can also be created ahead of time and packaged with the application.
 */
@interface KIOSDecodingGraph : NSObject 

/** @name Regular Decoding Graphs
 */
/** Create decoding graph from an array of phrases and save it  in the filesystem for later use.
 Decoding graphs can be referenced  by their name by various methods in the framework.
 
 @param phrases an NSArray of NSString objects that specify phrases recognizer should listen for.
 These phrases are used to create a  language model, from which decoding graph is created. Text in phrases
 should be normalized (e.g. numbers and dates should be represented by words, so 'two hundred dollars'
 not $200).
 
 @param recognizer KIOSRecognizer object that will be used to perform recognition
 with this decoding graph. Note that decoding graph is persisted in the filesystem
 and can be resued at the later time with a different KIOSRecognizer object as
 long as such recognizer uses the same ASR bundle as the KIOSRecognizer object
 used to create the decoding graph.
 
 @param alternativePronunciations an NSArray of AlternativePronunciations specifying alternative
 pronunciations that should be used when building this decoding graph.

 @param task KIOSSpeakingTask specyfing the type of task this decoding graph corresponds to. Calling this
 method with KIOSSpeakingTaskDefault is equivalent to calling
 createDecodingGraphFromSentences:forRecognizer:andSaveWithName method.

 @param decodingGraphName a name of the custom decoding graph. All graph
 resources will be stored in a directy named DECODING_GRAPH_NAME-ASR_BUNDLE_NAME
 in Library/Application Support/KaldiIOS-decoding-graphs/
 
 @return TRUE on success, FALSE otherwise
 */
+ (BOOL)createDecodingGraphFromPhrases:(nonnull NSArray *)phrases
                           forRecognizer:(nonnull KIOSRecognizer *) recognizer
          usingAlternativePronunciations:(nullable NSArray<KIOSAlternativePronunciation *> *) alternativePronunciations
                                 andTask:(KIOSSpeakingTask) task
                         andSaveWithName:(nonnull NSString *)decodingGraphName;


/** Create decoding graph from an array of phrases and save it  in the filesystem for later use.
 Decoding graphs can be referenced  by their name by various methods in the framework.
 
 @param phrases an NSArray of NSString objects that specify phrases  recognizer should listen for.
 These phrases are used to create a  language model, from which decoding graph is created. Text in phrases
 should be normalized (e.g. numbers and dates should be represented by words, so 'two hundred dollars'
 not $200).
 
 @param recognizer KIOSRecognizer object that will be used to perform recognition
 with this decoding graph. Note that decoding graph is persisted in the filesystem
 and can be resued at the later time with a different KIOSRecognizer object as
 long as such recognizer uses the same ASR bundle as the KIOSRecognizer object
 used to create the decoding graph.
 
 @param alternativePronunciations an NSArray of AlternativePronunciations specifying alternative
 pronunciations that should be used when building this decoding graph.

 @param task KIOSSpeakingTask specyfing the type of task this decoding graph corresponds to. Calling this
 method with KIOSSpeakingTaskDefault is equivalent to calling
 createDecodingGraphFromSentences:forRecognizer:andSaveWithName method.
 
 @param spokenNoiseProbability a float value in the range 0.0 - 1.0. Default value is 0.5. Lower values
 will make <SPOKEN_NOISE> occur less frequently in the result, whereas higher values will make it more likely
 to occur in the result.

 @param decodingGraphName a name of the custom decoding graph. All graph
 resources will be stored in a directy named DECODING_GRAPH_NAME-ASR_BUNDLE_NAME
 in Library/Application Support/KaldiIOS-decoding-graphs/
 
 @return TRUE on success, FALSE otherwise
 */
+ (BOOL)createDecodingGraphFromPhrases:(nonnull NSArray *)phrases
                           forRecognizer:(nonnull KIOSRecognizer *) recognizer
          usingAlternativePronunciations:(nullable NSArray<KIOSAlternativePronunciation *> *) alternativePronunciations
                                 andTask:(KIOSSpeakingTask) task
              withSpokenNoiseProbability:(float) spokenNoiseProbability
                         andSaveWithName:(nonnull NSString *)decodingGraphName;

/** @name Contextual Decoding Graphs
  */

/** Create custom decoding graph from an array of arrays of  phrases and save it  in the filesystem for later
 use. Each top-level array represents a context, which you can then set using prepareForListening before
 calling startListening.
 
 For example, you could build a decoding graph with the following contextualPhrases parameter:
 @[
     @[                                           // contextId 0
       @"This is a first phrase.",
       @"This first phrase belongs to the first contextual group
       ],
     @[                                           // contextId 1
       @"This is another phrase.",
       @"This phrase belongs to the second contextual group
      ]
 ];
 
 Custom decoding graphs can be referenced by their name by various methods in the framework.
 
 Decoding graphs created with this method require call to prepareForListeningWithContextId
 
 @param contextualPhrases an NSArray of NSArrays with NSString objects that specify
 phrases grouped by specific context. These phrases are used to create a language model, from which
 decoding graph is created. Text in phrases should  be normalized (e.g. numbers and dates should be
 represented by words, so 'two hundred dollars' not $200)
 
 @param recognizer KIOSRecognizer object that will be used to perform recognition
 with this decoding graph. Note that decoding graph is persisted in the filesystem
 and can be resued at the later time with a different KIOSRecognizer object as
 long as such recognizer uses the same ASR bundle as the KIOSRecognizer object
 used to create the decoding graph.
 
 @param alternativePronunciations an  optional NSArray of AlternativePronunciations specifying
 alternative pronunciations that should be used when building this decoding graph.
 
 @param task KIOSSpeakingTask specyfing the type of task this decoding graph corresponds to. Calling this
 method with KIOSSpeakingTaskDefault is equivalent to calling
 createDecodingGraphFromPhrases:forRecognizer:andSaveWithName method.

 @param decodingGraphName a name of the custom decoding graph. All graph
 resources will be stored in a directy named DECODING_GRAPH_NAME-ASR_BUNDLE_NAME
 in Library/Application Support/KaldiIOS-decoding-graphs/
 
 @return TRUE on success, FALSE otherwise
 */
+ (BOOL)createContextualDecodingGraphFromPhrases:(nonnull NSArray<NSArray *> *) contextualPhrases
                                   forRecognizer:(nonnull KIOSRecognizer *) recognizer
                  usingAlternativePronunciations:(nullable NSArray<KIOSAlternativePronunciation *> *) alternativePronunciations
                                         andTask:(KIOSSpeakingTask) task
                                 andSaveWithName:(nonnull NSString *)decodingGraphName;


/** Create custom decoding graph from an array of arrays of  phrases and save it  in the filesystem for later
 use. Each top-level array represents a context, which you can then set using prepareForListening before
 calling startListening.
 
 For example, you could build a decoding graph with the following contextualPhrases parameter:
 @[
     @[                                           // contextId 0
       @"This is a first phrase.",
       @"This first phrase belongs to the first contextual group
       ],
     @[                                           // contextId 1
       @"This is another phrase.",
       @"This phrase belongs to the second contextual group
      ]
 ];
 
 Custom decoding graphs can be referenced by their name by various methods in the framework.
 
 Decoding graphs created with this method require call to prepareForListeningWithContextId
 
 @param contextualPhrases an NSArray of NSArrays with NSString objects that specify
 phrases grouped by specific context. These phrases are used to create a language model, from which
 decoding graph is created. Text in phrases should  be normalized (e.g. numbers and dates should be
 represented by words, so 'two hundred dollars' not $200)
 
 @param recognizer KIOSRecognizer object that will be used to perform recognition
 with this decoding graph. Note that decoding graph is persisted in the filesystem
 and can be resued at the later time with a different KIOSRecognizer object as
 long as such recognizer uses the same ASR bundle as the KIOSRecognizer object
 used to create the decoding graph.

 @param alternativePronunciations an optional NSArray of AlternativePronunciations specifying
 alternative pronunciations that should be used when building this decoding graph.

 @param task KIOSSpeakingTask specyfing the type of task this decoding graph corresponds to. Calling this
 method with KIOSSpeakingTaskDefault is equivalent to calling
 createDecodingGraphFromPhrases:forRecognizer:andSaveWithName method.

 @param spokenNoiseProbability a float value in the range 0.0 - 1.0. Default value is 0.5. Lower values
 will make <SPOKEN_NOISE> occur less frequently in the result, whereas higher values will make it more likely
 to occur in the result.
 
 @param decodingGraphName a name of the custom decoding graph. All graph
 resources will be stored in a directy named DECODING_GRAPH_NAME-ASR_BUNDLE_NAME
 in Library/Application Support/KaldiIOS-decoding-graphs/
 
 @return TRUE on success, FALSE otherwise
 */
+ (BOOL)createContextualDecodingGraphFromPhrases:(nonnull NSArray<NSArray *> *) contextualPhrases
                                   forRecognizer:(nonnull KIOSRecognizer *) recognizer
                  usingAlternativePronunciations:(nullable NSArray<KIOSAlternativePronunciation *> *) alternativePronunciations
                                         andTask:(KIOSSpeakingTask) task
                      withSpokenNoiseProbability:(float)spokenNoiseProbability
                                 andSaveWithName:(nonnull NSString *)decodingGraphName;


/** Create decoding graph setup for trigger phrase, using an array of phrases and save it  in the filesystem for
 later use. Decoding graphs can be referenced  by their name by various methods in the framework.
 
 @param phrases an NSArray of NSString objects that specify phrases recognizer should listen for.
 These phrases are used to create a  language model, from which decoding graph is created. Text in phrases
 should be normalized (e.g. numbers and dates should be represented by words, so 'two hundred dollars'
 not $200).
 
 @param triggerPhrase NSString object that defines trigger phrase which will be used when building this
 decoding graphs. When using graphs built with trigger phrase support, recognizer will not report any results
 until it recognizes the trigger phrase. If you are using trigger phrase graphs, you can also setup a
 [KIOSRecognizer 
 
 @param recognizer KIOSRecognizer object that will be used to perform recognition
 with this decoding graph. Note that decoding graph is persisted in the filesystem
 and can be resued at the later time with a different KIOSRecognizer object as
 long as such recognizer uses the same ASR bundle as the KIOSRecognizer object
 used to create the decoding graph.

 @param decodingGraphName a name of the custom decoding graph. All graph
 resources will be stored in a directy named DECODING_GRAPH_NAME-ASR_BUNDLE_NAME
 in Library/Application Support/KaldiIOS-decoding-graphs/
 
 @return TRUE on success, FALSE otherwise
 */
+ (BOOL)createDecodingGraphFromPhrases:(nonnull NSArray *)phrases
                       withTriggerPhrase:(nonnull NSString *)triggerPhrase
                           forRecognizer:(nonnull KIOSRecognizer *) recognizer
                         andSaveWithName:(nonnull NSString *)decodingGraphName;

/** @name Helper methods */

/** Verify if pronunciation speciifed in the input string is composed of valid phones that are supported for the
 given recognizer. Returns TRUE if pronunciation is valid, FALSE otherwise.
 
 @param pronunciation string that represents pronunciation of a word. For example @"k ae t"
 
 @param recognizer KIOSRecognizer object equivalent to the KIOSRecognizer object
 that was used to create the decoding graph.

 @return  Returns TRUE if pronunciation is valid, false otherwise
 */
+ (BOOL)validatePronunciation:(nonnull NSString *) pronunciation
                forRecognizer:(nonnull KIOSRecognizer *) recognizer
__deprecated_msg("This method is temporarily deprecated");

/** Returns TRUE if valid custom decoding graph with the given name exists in
 the filesystem.
 
 @param decodingGraphName name of the custom decoding graph
 
 @param recognizer KIOSRecognizer object equivalent to the KIOSRecognizer object
 that was used to create the decoding graph.

 @return TRUE if decoding graph with such name exists, FALSE otherwise. This method
 will also check for existance of all the necessary files in the decoding graph
 directory.
 */
+ (BOOL)decodingGraphWithNameExists:(nonnull NSString *)decodingGraphName
                      forRecognizer:(nonnull KIOSRecognizer *)recognizer;


/** Returns TRUE if a valid decoding graph exists at the given absolute filepath.
 
 @param absolutePathToDecodingGraphDirectory absolute path to the decoding graph directory.
 
 @return TRUE if decoding graph with such name exists, FALSE otherwise. This method
 will also check for existance of all the necessary files in the decoding graph
 directory.
 */
+ (BOOL)decodingGraphAtPathExists:(nonnull NSString *)absolutePathToDecodingGraphDirectory;


/** Returns TRUE if a valid decoding graph exists at the given absolute filepath.
 
 @param absolutePathToDecodingGraphDirectory absolute path to the decoding graph directory.
 
 @return TRUE if decoding graph with such name exists, FALSE otherwise. This method
 will also check for existance of all the necessary files in the decoding graph
 directory.
 */
+ (BOOL)decodingGraphExistsAtPath:(nonnull NSString *)absolutePathToDecodingGraphDirectory
__deprecated_msg("Please use decodingGraphAtPathExists method");


/** Returns date when custom decoding graph was created.
 
 @param decodingGraphName name of the decoding graph
 @param recognizer KIOSRecognizer object equivalent to the KIOSRecognizer object
 that was used to create the decoding graph.
 
 @return date when decoding graph was created and saved in the filesystem. nil 
 if not available.
 */
+ (nullable NSDate *)decodingGraphCreationDate:(nonnull NSString *)decodingGraphName
                                 forRecognizer:(nonnull KIOSRecognizer *)recognizer;

/** Returns NSURL object that specifies directory where decoding graph is stored.

 @param decodingGraphName name of the decoding graph
 #param recognizer KIOSRecognizer object equivalent to the KIOSRecognizer object that was used to
 create the decoding 	graph.
 
 @return NSURL object where the decoding graph was or should have been stored.
 
 */
+ (nullable NSURL *)getDecodingGraphDirURL:(nonnull NSString *)decodingGraphName
                             forRecognizer:(nonnull KIOSRecognizer *)recognizer;


/** @name Deprecated Methods */

+ (BOOL)createDecodingGraphFromSentences:(nonnull NSArray *)sentences
                           forRecognizer:(nonnull KIOSRecognizer *) recognizer
                            andSaveWithName:(nonnull NSString *)decodingGraphName
__deprecated_msg("Please use createDecodingGraphFromPhrases methods");


+ (BOOL)createContextualDecodingGraphFromSentences:(nonnull NSArray<NSArray *> *) contextualSentences
                                     forRecognizer:(nonnull KIOSRecognizer *) recognizer
                    usingAlternativePronunciations:(nullable NSArray<KIOSAlternativePronunciation *> *) alternativePronunciations
                                           andTask:(KIOSSpeakingTask) task
                                   andSaveWithName:(nonnull NSString *)decodingGraphName
__deprecated_msg("Please use createContextualDecodingGraphFromPhrases methods");


+ (BOOL)createDecodingGraphFromSentences:(nonnull NSArray *)sentences
                       withTriggerPhrase:(nonnull NSString *)triggerPhrase
                           forRecognizer:(nonnull KIOSRecognizer *) recognizer
                         andSaveWithName:(nonnull NSString *)decodingGraphName
__deprecated_msg("Please use createDecodingGraphFromPhrases: withTriggerPhrase method");


+ (BOOL)createDecodingGraphFromSentences:(nonnull NSArray *)sentences
                           forRecognizer:(nonnull KIOSRecognizer *) recognizer
          usingAlternativePronunciations:(nullable NSArray<KIOSAlternativePronunciation *> *) alternativePronunciations
                                 andTask:(KIOSSpeakingTask) task
                            andSaveWithName:(nonnull NSString *)decodingGraphName
__deprecated_msg("Please use createDecodingGraphFromPhrases methods");

@end


#endif /* KIOSDecodingGraph_h */
