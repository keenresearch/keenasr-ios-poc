//
//  KIOSDecodingGraph.h
//  KaldiIOS
//
//  Created by Ognjen Todic on 5/17/16.
//  Copyright © 2016 Keen Research. All rights reserved.
//

#ifndef KIOSDecodingGraph_h
#define KIOSDecodingGraph_h


// LATER
/** These constants indicate the type of the language model that will be created
 from the sentences you pass to the decoding graph */

//typedef NS_ENUM(NSInteger, KIOSLanguageModelOrder) {
//  /** Bigram language model */
//  KIOSLanguageModelOrderBigram = 2,
//  /** Trigram language model */
//  KIOSLanguageModelOrderTrigram = 3
//};


@class KIOSRecognizer;

/** An instance of the KIOSDecodingGraph class, called decodingGraph, manages
 recognizer's decoding graph. For more details on the concept of decoding graphs
 in automated speech recognition see [this page](http://kaldi-asr.org/doc/graph.html).
 
 For ASR tasks in which domain and vocabulary are defined ahead of time and not
 dependent on information available only during the runtime, it is recommended that
 decoding graph is created offline and packaged in the ASR bundle directory.
 
 If user specific information is necessary to create decoding graphs, you can use
 KIOSDecodingGraph class to dynamically create decoding graphs which will be 
 saved in the filesystem on the device. Typically, you will provide a list of
 sentences/phrases to createDecodingGraphFromSentences:andSaveWithName: method,
 which will then create a custom decoding graph in the file system. Later on, 
 you can refer to the decodingGraph by its name. Alternatively, you can provide
 a bigram language model, which will be used to build a decoding graph.

 Using this class is conditioned on availability of the lang/ subdirectory in the
 ASR bundle.
 
 @warning When dynamically creating decoding graphs, any words that do not have
 phonetic representation in the lexicon (ASRBUNDLE/lang/lexicon.txt) will be 
 assigned one algorithmically. For English langauge algorithmic representation is
 imperfect, thus you should aim to augment the lexicon text file with 
 pronunciations for as many additional words that are likely to be encountered
 in your app. For example, if your app is dealing with ASR of names
 you would augment the lexicon with additional names and their proper 
 pronunciation.

 @warning In the current versio of the framework, creating of decodingGraph can
 take on the order of 10-15 sec for medium size vocabulary/bigrams (more than
 thousand words). We are actively working on optimizing methods that create
 decoding graphs.
 
 */
@interface KIOSDecodingGraph : NSObject 

@property (nonatomic, weak, readonly) KIOSRecognizer *recognizer;


 /** Initialize the decoding graph with the specific recognizer type.
 @param recognizer an instance of KIOSRecognizer which will be using this decoding
  graph
 */
- (id)initWithRecognizer:(KIOSRecognizer*) recognizer;


 /** Create custom decoding graph from a bigram file and save it in the 
  filesystem for later use.
  
 @param bigramURL a URL for the bigram file that defines the language model for
  which decoding graph needs to be created
  
  @param decodingGraphName a name of the custom decoding graph. All graph 
  resources will be stored in a directy named decodingGraphName in 
  Library/Application Support/KaldiIOS-decoding-graphs/

  @return TRUE on success, FALSE otherwise
  */
- (BOOL)createDecodingGraphFromBigramURL:(NSURL *)bigramURL
                         andSaveWithName:(NSString *)decodingGraphName;


/** Create custom decoding graph from an array of sentences/phrases and save it
 in the filesystem under for later use. Custom decoding graphs can be referenced
 by their name by various methods in the framework.
 
 @param sentences a NSArray or NSString objects that specify sentences recognizer
 should listen for. These sentences are used to create a bigram language model,
 from which decoding graph is created. Text in sentences should be normalized (e.g.
 numbers and dates should be represented by words, so 'two hunded dollars' not $200)
 
 @param decodingGraphName a name of the custom decoding graph. All graph
 resources will be stored in a directy named DECODING_GRAPH_NAME-ASR_BUNDLE_NAME
 in Library/Application Support/KaldiIOS-decoding-graphs/
 
 @return TRUE on success, FALSE otherwise
 */
- (BOOL)createDecodingGraphFromSentences:(NSArray *)sentences
                            andSaveWithName:(NSString *)decodingGraphName;


/** Returns TRUE if graph with the given name already exists in the filesystem.
 
 @param decodingGraphName name of the custom decoding graph
 
 @return TRUE if decoding graph with such name exists, FALSE otherwise
 */
- (BOOL)decodingGraphExists:(NSString *)decodingGraphName;


/** Returns date when decoding graph was created.
 
 @param decodingGraphName name of the decodingGraph
 
 @return date when decoding graph was created. nil if not available.
 
 */
- (NSDate *)decodingGraphCreationDate:(NSString *)decodingGraphName;


- (NSURL *)hclgURLForCustomDecodingGraph:(NSString *)decodingGraphName;
- (NSURL *)wordSymsURLForCustomDecodingGraph:(NSString *)decodingGraphName;



@end


#endif /* KIOSDecodingGraph_h */
