//
//  KIOSUploader.h
//  KaldiIOS
//
//  Created by Ognjen Todic on 10/20/17.
//  Copyright © 2017 Keen Research. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KIOSRecognizer;

/** KIOSUploader class provides methods that manage uploads of speech
 recognition metadata and audio recordings to Dashboard, a Keen Research cloud
 service for data collection and development of voice applications.
 
 For more details see http://keenresearch.com.
  */
@interface KIOSUploader : NSObject

/** If set to TRUE, data will be deleted from the device after it has been
 succesfully uploaded to the cloud. If FALSE, data will be kept on the device
 after it's been uploaded, it will just be renamed to the files with additional
 extension .BKP.

 Default is TRUE.
 */
@property (class) BOOL removeDataAfterUpload;


/** Creates a background thread which periodically scans recognizer data
 directory and uploads audio recordings and speech recognition metadata to
 Dashboard, a Keen Research cloud service. Data will be uploaded to the
 cloud service using the specified appKey.
 
 For more details see http://keenresearch.com/dashboard
 
 @param recognizer recognizer for which recordings and metadata will be
 uploaded
 @param appKey app key provided for your app via Dashboard cloud
 service
 
 @return TRUE if upload thread was successfully created, FALSE otherwise.
  
 If provided appKey cannot be matched via cloud API, upload requests will be
 ignored.
 
 If KIOSRecognizer.createJSONMetadata is set to NO, response json files
 will not be created on the device and there will be no metadata to transfer to
 the Dashboard. KIOSRecognizer.createAudioRecordings also needs be set to YES
 (future releases will provide ways to upload only metadata, even when audio
 recordings are not stored on the device).
 
 KIOSUploader will currently upload data as long as there is internet
 connectivity regardless of its type (WiFi, LTE, etc.). Future releases will
 provide finer control over the type of internet connectivity channels that
 should be used for uploads.
 */
+ (BOOL)createDataUploadThreadForRecognizer:(KIOSRecognizer *) recognizer
                                usingAppKey:(NSString *)appKey;


/** Pause uploads in already created upload thread. If upload thread was not
 created prior to calling this method, the call to this method will be ignored.
 Once uploads have* been paused they can be resumed at any time by calling
 resume.
 */
+ (void)pause;


/** Resume uploads in already created upload thread.
 
 @return YES if uploads successfully resumed (data upload thread has been
 created prior to calling this method), NO if uploads cannot be resumed.
 */
+ (BOOL)resume;


/** Returns YES is upload thread is paused, NO if it's running.
 */
+ (BOOL)isPaused;


/** Returns number of upload errors since the upload thread was created.
 */
//+ (NSUInteger)numberOfUploadErrors;

@end
