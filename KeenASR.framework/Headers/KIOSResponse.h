//
//  KIOSResponse.h
//  KeenASR
//
//  Created by Ognjen Todic on 1/11/24.
//  Copyright © 2024 Keen Research. All rights reserved.
//

#ifndef KIOSResponse_h
#define KIOSResponse_h

@class KIOSResult;

/**  An instance of the KIOSResponse class, called  response provides
 various information about the specifc run of a recognizer, including KIOSResult
 and additional metadata about recognition and audio setup */
@interface KIOSResponse : NSObject

/** an instance of KIOSResult that provides final result corresponding to this response */
@property(nonatomic, readonly, nullable) KIOSResult *result;

/** @name Various response properties */

/** name of the decoding graph that was used for recognition*/
@property(nonatomic, readonly, nonnull) NSString *decodingGraphName;

/** name of the ASR Bundle that was used for recognition */
@property(nonatomic, readonly, nonnull) NSString *asrBundleName;

/** JSON  for this response */
@property(nonatomic, readonly, nonnull) NSString *json;

/** id of this response. This corresponds to the id set via startListening method */
@property(nonatomic, readonly, nonnull) NSString *responseId;

/** BOOL value that's set to true if echo cancellation was used during recognition of this response,
 or false if it wasn't (the value is captured and persisted at the end of recognition) */
@property(nonatomic, readonly) BOOL echoCancellation;


/** @name File saving
 *
 * Response instance contains json and audio, which can be saved to the filesystem. .
 *
 */
/** Full path to the json file that corresponds to this response. This file will  be available only
 after call to saveJsonFile method */
@property(nonatomic, readonly, nonnull) NSString *jsonFilename;

/** Full path to the the audio file that corresponds to this response. This file will be available only
 after call to saveAudioFile method */
@property(nonatomic, readonly, nonnull) NSString *audioFilename;


/** Saves JSON representation of the response in the specified filepath in the filesystem. The name of the file
 * can be obtained via jsonFilename property.
 *
 * @param dirpath instance of the URL object that points to the directory in which the JSON file should
 * be saved
 *
 * @return TRUE if file was succesfully saved, false otherwise. This method will fail if  the dirpath does not
 * point to an existing directory, or if you attempt to pass a dirpath that points to internal directory KeenASR
 * SDK uses for uploades to Dashboard or if the directory is not writeable.
 */
- (BOOL)saveJsonFile:(nonnull NSURL *)dirpath;


/** Saves audio file in the specified filepath in the filesystem. The name of the file
 * can be obtained via audioFilename property.
 *
 * @param dirpath instance of the URL object that points to the directory in which the audio file should
 * be saved.
 *
 * @return TRUE if file was succesfully saved, false otherwise. This method will fail if  the dirpath does not
 * point to an existing directory, or if you attempt to pass a dirpath that points to internal directory KeenASR
 * SDK uses for uploades to Dashboard or if the directory is not writeable.
 */
- (BOOL)saveAudioFile:(nonnull NSURL *) dirpath;

@end

#endif /* KIOSResponse_h */
