#ifndef KIOSAudioQualityResult_h
#define KIOSAudioQualityResult_h

/**
 * AudioQualityResult class with specified rms values vector, clipped sample count
 * and estimated SNR value.
 *
 * AudioQualityResult will be computed during final response computation, and provided 
 * in an instance of { @link KIOSResponse } object.
 */
@interface KIOSAudioQualityResult : NSObject

/**
 * Serialises contents of AudioQualityResult into JSON format.
 *
 * @return A JSON string representation of AudioQualityResult.
 */
- (nonnull NSString *)toJson;

/**
 * Root mean square (RMS) values for each frame (25ms long with 10ms shift) in decibels in the
 * processed audio. Values are computed as 20*log10(√(sum of squared sample values)). Where a
 * frame has a zero signal level, the RMS dB value is reported as around -100dB.
 */
@property(nonatomic, readonly, nonnull) NSArray<NSNumber *> *frameRmsValues;

/**
 * Number of raw samples in processed audio that were clipping, i.e. reaching either maximum or
 * minimum value. Clipping indicate that the user might be too close to the microphone during
 * audio capture or fidgeting with the microphone. It can have negative implications on speech
 * recognition performance.
 */
@property(nonatomic, readonly) NSUInteger clippedSampleCount;

/**
 * Estimated signal to noise ratio (SNR) in decibels for processed audio. SNR is computed as a
 * difference between meanSpeechRmsValue and mean_noise_rms_value. The way SNR is currently
 * computed may not take transient noise as effectively into account as it does stationary
 * background noise. Low values will affect speech recognition performance.
 *
 * NOTE: snrValue will be nil if there wasn't sufficient data to compute it.
 */
@property(nonatomic, readonly, nullable) NSNumber *snrValue;

/**
 * Mean frame root mean square (RMS) level for the speech segments in processed audio in decibels.
 *
 * NOTE: This value will be nil if no speech segments were available in the response.
 */
@property(nonatomic, readonly, nullable) NSNumber *meanSpeechRmsValue;

/**
 * Mean frame root mean square (RMS) level for the noise segments in processed audio, in decibels.
 */
@property(nonatomic, readonly, nonnull) NSNumber *meanNonSpeechRmsValue;

/**
 * Estimated peak root mean square (RMS) level of speech in the processed audio, in decibels. This
 * value is computed as 98th percentile of all the RMS speech levels to filter outliers. Low
 * values would indicate faint speech or user being too far from the microphone. This metric may
 * not work well for responses with very short speech segments.
 *
 * NOTE: This value will be nil if no speech segments were available in the response.
 */
@property(nonatomic, readonly, nullable) NSNumber *peakSpeechRmsValue;

/**
 * Flag indicating that high RMS (root mean square) value was detected during the initial part of the
 * processed audio. This could either indicate that: a) device is playing audio, which is then captured
 * by the microphone); b) the user has already started speaking, and recognizer started to listen
 * too late. c) high levels of noise in general.
 */
@property(nonatomic, readonly) BOOL initialSegmentRmsWarning;

@end

#endif /* KIOSAudioQualityResult_h */
