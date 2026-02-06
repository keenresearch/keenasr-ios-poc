#ifndef KIOSWordPronunciation_h
#define KIOSWordPronunciation_h

@class KIOSRecognizer;

/**
 * WordPronunciation is a class that defines mapping beween a word and its phonetic
 * pronunciation. Phonetic pronunciation is a space separated string of phonemes that define how the word is
 * pronounced. The names of the phonemes are defined in ASR Bundle lang/phones.txt file. For some languages
 * for which this mapping is not deterministic, ASR Bundle will contain a large lookup table in lang/lexicon.txt file.
 * 
 * You can use WordPronunciations to provide alternatives to existing pronunciations, to define
 * pronunciations for the words that are not in the lexicon.txt file (including made-up words), or to provide
 * common mispronunciations (which can be useful in some scenarios such as language learning and reading
 * instruction); For the latter, you can also provide a tag when defining WordPronunciation; if such
 * alternative pronunciation is recognized by the recognizer, the # symbol and the provided tag will be appended
 * to the word in the result (e.g. "PEAK#WRONG", if the tag was set to "WRONG").
 *
 * Example:
 *
 * ```
     KIOSWordPronunciation *myFoo = [[KIOSWordPronunciation alloc] initWithWord:@"TIME" pronunciation:@"L AY1 M" tag:@"WRONG"];
 * ```
 */
@interface KIOSWordPronunciation : NSObject

/**
 * Parameterized constructor
 *
 * NOTE: both word and phones will internally be stored in uppercase.
 *
 * @param word string specifying the word. For example "CAT".
 * @param pronunciation a space separated phone string.
 * @param tag a tag suffix for the word.
 */
- (instancetype)initWithWord:(nonnull NSString *)word pronunciation:(nonnull NSString *)pronunciation tag:(nullable NSString *)tag;

/**
 * Get the string specifying the word. For example "CAT".
 * @return string specifying the word.
 */
- (nonnull NSString *)getWord;

/**
 * Get the optional tag value, which, if provided, will be appended together with the # symbol to the word if the variation of
 * the word with the provided pronunciation is recognized. For example, PEAK#WRONG.
 */
- (nonnull NSString *)getTag;

/**
 * Get the phonetic transcription of a word, provided as a space-separated sequence of phones.
 *
 * @return space separated sequence of phones, provided during object creation. Phones will be in upper case and extra white spaces will be removed during object creation.
 */
- (nonnull NSString *)getPronunciation;

/**
 * Verify if this object is valid, for a given { @link KIOSRecognizer }.
 *
 * A word pronunciation is valid if:
 * 1. word does not contain < or > characters
 * 2. tag is not equal to "INC" (reserved tag) and it does not contain # character
 * 3. pronunciations are composed of valid phones (as defined in the ASR Bundle that was used to
 * initialize the Recognizer)
 *
 * @param recognizer an instance of { @link KIOSRecognizer } object against which the validation should be performed.
 * @return true if this word pronunciation is valid; false otherwise
 */
- (BOOL)isValid:(nonnull KIOSRecognizer *)recognizer;

@end

#endif /* KIOSWordPronunciation_h */
