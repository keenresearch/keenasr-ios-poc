//
//  KIOSDecodingGraph.h
//  KeenASR
//
//  Created by Ognjen Todic on 5/17/16.
//  Copyright © 2016 Keen Research. All rights reserved.
//

#ifndef KIOSDecodingGraph_h
#define KIOSDecodingGraph_h

///** KIOSTask defines a type of speaking task that will be handled. It is primarily
// * used to indicate to methods that create decoding graphs what type of task they
// * need to handle, so that appropiate customization can be done when creating
// * language model and decoding graph
// */
//typedef NS_ENUM(NSInteger, KIOSSpeakingTask) {
//  /** Reading aloud in educational context (children, language learning */
//  KIOSSpeakingTaskEduReading,
//  /** Keyword spotting among small number (20-30) of words */
//  KIOSSpeakingTaskKeywordSpotting,
//};
//
///** Probability of pauses between words, with values between 0 and 1; default
// * value is 0.5. You may want to increase this value when users are reading
// * (especially if they are not proficient readers), or decrease it for fast
// * conversational speech where pauses between words are unlikely. This parameter
// * will typically have noticable effect on performance only in extreme
// * situations, and as such there rarely a need to adjust it.
// */
//extern NSString * _Nonnull const DecodingGraphOptionInterwordSilenceProbability;

@class KIOSRecognizer;

/** KIOSDecodingGraph class manages decoding graphs in the filesystem. For more
 details on the concept of decoding graphs in automated speech recognition see 
 [this page](http://kaldi-asr.org/doc/graph.html).
 
 For ASR tasks in which domain and vocabulary are defined ahead of time and not
 dependent on information available only during the runtime, it is recommended that
 decoding graph is created offline and packaged in the ASR bundle directory.
 
 If user specific information is necessary to create decoding graphs, you can use
 various KIOSDecodingGraph class methods to dynamically create decoding graphs,
 which will be saved in the filesystem on the device. Typically, you will
 provide a list of sentences/phrases to createDecodingGraphFromSentences:forRecognizer:andSaveWithName:
 method, which will then create a custom decoding graph. Later on, you can refer
 to the custom decoding graph by its name. Alternatively, instead of list of
 sentences/phrases you can provide an ARPA language model (bundled with your app),
 which will be used to build a custom decoding graph.

 Decoding graphs can only be built dynamically if the lang/ subdirectory in the
 ASR bundle exists.
 
 @warning When dynamically creating decoding graphs, any words that do not have
 phonetic representation in the lexicon (ASRBUNDLE/lang/lexicon.txt) will be 
 assigned one algorithmically. For English langauge algorithmic representation is
 imperfect, thus you should aim to manually augment the lexicon text file with
 pronunciations for as many additional words that are likely to be encountered
 in your app. For example, if your app is dealing with ASR of names
 you would augment the lexicon with additional names and their proper 
 pronunciation before releasing your app.

 @warning In the current version of the framework, creating of decoding graph can
 take on the order of 10-30sec (on iPhone 6 and equivalent devices) for
 medium size vocabulary task (more than thousand words). For larger language 
 models we recommend you create decoding graph ahead of time and bundle it with
 your app.
 */
@interface KIOSDecodingGraph : NSObject 


 /** Create custom decoding graph using the language model specifed in an ARPA 
  file and save it in the filesystem for later use. Custom decoding graphs can 
  be referenced by their name by various methods in the framework.
  
  @param arpaURL a URL for an ARPA file that defines the language model for
  which decoding graph needs to be created. Words in the ARPA file should all be
  in uppercase.

  @param recognizer KIOSRecognizer object that will be used to perform recognition
  with this decoding graph. Note that decoding graph is persisted in the filesystem
  and can be resued at the later time with a different KIOSRecognizer object as
  long as such recognizer uses the same ASR bundle as the KIOSRecognizer object
  used to create the decoding graph.

  @param decodingGraphName name of the custom decoding graph. All graph
  resources will be stored in a directory named DECODING_GRAPH_NAME-ASR_BUNDLE_NAME
  in Library/Application Support/KaldiIOS-decoding-graphs/

  @return TRUE on success, FALSE otherwise
  */
+ (BOOL)createDecodingGraphFromArpaFileAtURL:(nonnull NSURL *)arpaURL
                               forRecognizer:(nonnull KIOSRecognizer *)recognizer
                             andSaveWithName:(nonnull NSString *)decodingGraphName;


/** Create custom decoding graph from an array of sentences/phrases and save it
 in the filesystem under for later use. Custom decoding graphs can be referenced
 by their name by various methods in the framework.
 
 @param sentences an NSArray of NSString objects that specify sentences/phrases
 recognizer should listen for. These sentences are used to create an ngram 
 language model, from which decoding graph is created. Text in sentences should
 be normalized (e.g. numbers and dates should be represented by words, so 
 'two hundred dollars' not $200)
 
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
+ (BOOL)createDecodingGraphFromSentences:(nonnull NSArray *)sentences
                           forRecognizer:(nonnull KIOSRecognizer *) recognizer
                            andSaveWithName:(nonnull NSString *)decodingGraphName;


//+ (BOOL)createDecodingGraphFromSentences:(nonnull NSArray *)sentences
//                           forRecognizer:(nonnull KIOSRecognizer *)recognizer
//                                 forTask:(nonnull NSString *)task
//                             withOptions:(nullable NSDictionary *)options
//                         andSaveWithName:(nonnull NSString *)decodingGraphName;


+ (BOOL)createDecodingGraphForKeywordSpotting:(nonnull NSArray *)keywords
                                forRecognizer:(nonnull KIOSRecognizer *) recognizer
                              andSaveWithName:(nonnull NSString *)decodingGraphName;


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
+ (BOOL)decodingGraphExistsAtPath:(nonnull NSString *)absolutePathToDecodingGraphDirectory;


/** Returns date when custom decoding graph was created.
 
 @param decodingGraphName name of the decodingGraph
 @param recognizer KIOSRecognizer object equivalent to the KIOSRecognizer object
 that was used to create the decoding graph.
 
 @return date when decoding graph was created and saved in the filesystem. nil 
 if not available.
 */
+ (nullable NSDate *)decodingGraphCreationDate:(nonnull NSString *)decodingGraphName
                                 forRecognizer:(nonnull KIOSRecognizer *)recognizer;


+ (nullable NSString *)hclgFilepathForDecodingGraphAtPath:(nonnull NSString *)absolutePath;
+ (nullable NSString *)wordSymsFilepathForDecodingGraphAtPath:(nonnull NSString *)absolutePath;
+ (nullable NSString *)rescoringConstArpaFilepathForDecodingGraphAtPath:(nonnull NSString *)absolutePath;

+ (nullable NSURL *)getDecodingGraphDirURL:(nonnull NSString *)customDecodingGraphName
                             forRecognizer:(nonnull KIOSRecognizer *)recognizer;

@end


#endif /* KIOSDecodingGraph_h */
