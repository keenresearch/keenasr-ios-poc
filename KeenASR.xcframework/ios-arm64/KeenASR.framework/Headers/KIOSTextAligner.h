//
//  KIOSTextAligner.h
//  KeenASR
//
//  Copyright © 2026 Keen Research LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KIOSRecognizer;

NS_ASSUME_NONNULL_BEGIN

/**
 * @enum KIOSAlignOp
 * @brief Edit-script operation produced by alignment.
 *
 * One of these values is associated with every step in the alignment trace
 * between a reference text and a recognized (hypothesis) text.
 */
typedef NS_ENUM(NSInteger, KIOSAlignOp) {
    /** Recognized token equals reference token. */
    KIOSAlignOpMatch        = 0,
    /** Recognized token paired with a different reference token. */
    KIOSAlignOpSubstitution = 1,
    /** Recognized token has no reference counterpart (extra word). */
    KIOSAlignOpInsertion    = 2,
    /** Reference token has no recognized counterpart (skipped word). */
    KIOSAlignOpDeletion     = 3,
};

#pragma mark - KIOSAlignmentConfig

/**
 * @class KIOSAlignmentConfig
 * @brief Per-call configuration for a text-alignment operation.
 *
 * Defaults reproduce classic Levenshtein word edit distance with unit costs
 * and noise-token filtering enabled. For most oral-reading and WER use cases
 * the defaults are appropriate.
 */
@interface KIOSAlignmentConfig : NSObject

/**
 * @brief Cost of inserting a recognized token (one not present in the reference).
 *
 * Default: 1.0.
 */
@property (nonatomic, assign) float insertCost;

/**
 * @brief Cost of deleting a reference token (one not present in the recognized text).
 *
 * Default: 1.0.
 */
@property (nonatomic, assign) float deleteCost;

/**
 * @brief Cost of substituting one token for another.
 *
 * When `substituteCost > insertCost + deleteCost` the aligner degenerates to
 * LCS-style behavior (no substitutions emitted). Default: 1.0.
 */
@property (nonatomic, assign) float substituteCost;

/**
 * @brief When YES, the result populates `repetitionRefIndices` for words the
 *        reader appears to have stuttered or repeated.
 *
 * A repetition is reported when two adjacent recognized tokens are identical
 * but only one of the pair was matched against the reference. Default: NO.
 */
@property (nonatomic, assign) BOOL detectRepetitions;

/**
 * @brief When YES, recognized tokens whose text begins with '<' (e.g.
 *        `<SPOKEN_NOISE>`, `<UNK>`) are dropped before alignment.
 *
 * Leave on when the recognized text comes from an ASR result; turn off when
 * aligning plain reference vs. plain hypothesis. Default: YES.
 */
@property (nonatomic, assign) BOOL filterNoiseTokens;

@end

#pragma mark - KIOSAlignmentItem

/**
 * @class KIOSAlignmentItem
 * @brief A single step in an alignment trace.
 *
 * For an insertion, `refIndex` is `NSNotFound` and `refToken` is empty.
 * For a deletion, `recIndex` is `NSNotFound` and `recToken` is empty.
 * For a match or substitution, both indices and tokens are populated.
 *
 * Indices refer to positions in the post-normalization token vectors —
 * see `KIOSTextAligner.referenceTokens` for the reference side.
 */
@interface KIOSAlignmentItem : NSObject

/** @brief The edit operation this item represents. */
@property (nonatomic, readonly) KIOSAlignOp op;

/**
 * @brief Index of the reference token participating in this operation,
 *        or `NSNotFound` for an insertion.
 */
@property (nonatomic, readonly) NSInteger refIndex;

/**
 * @brief Index of the recognized token participating in this operation,
 *        or `NSNotFound` for a deletion.
 */
@property (nonatomic, readonly) NSInteger recIndex;

/**
 * @brief Reference token at `refIndex`, or empty string for an insertion.
 */
@property (nonatomic, readonly, copy) NSString *refToken;

/**
 * @brief Recognized token at `recIndex`, or empty string for a deletion.
 */
@property (nonatomic, readonly, copy) NSString *recToken;

@end

#pragma mark - KIOSAlignmentResult

/**
 * @class KIOSAlignmentResult
 * @brief Result of aligning a recognized token sequence against a reference.
 *
 * Exposes both an edit-script trace (suitable for word-error-rate reporting)
 * and derived oral-reading views (matched / skipped / furthest-reached).
 *
 * Indices in all `*RefIndices` accessors and `furthestMatchedIndex` refer to
 * positions in the normalized reference token vector, accessible via
 * `KIOSTextAligner.referenceTokens`.
 */
@interface KIOSAlignmentResult : NSObject

/** @brief Full alignment trace, left-to-right over the input sequences. */
@property (nonatomic, readonly) NSArray<KIOSAlignmentItem *> *trace;

#pragma mark Edit-distance counts

/** @brief Number of matched token pairs. */
@property (nonatomic, readonly) NSInteger matches;

/** @brief Number of substitutions in the alignment. */
@property (nonatomic, readonly) NSInteger substitutions;

/** @brief Number of insertions (extra recognized tokens). */
@property (nonatomic, readonly) NSInteger insertions;

/** @brief Number of deletions (skipped reference tokens). */
@property (nonatomic, readonly) NSInteger deletions;

/** @brief Length of the post-normalization reference token vector. */
@property (nonatomic, readonly) NSInteger refLength;

/** @brief Length of the post-normalization recognized token vector. */
@property (nonatomic, readonly) NSInteger recLength;

/**
 * @brief Word error rate: (substitutions + insertions + deletions) / refLength.
 *
 * Returns 0.0 when refLength is 0.
 */
@property (nonatomic, readonly) float wordErrorRate;

#pragma mark Oral-reading views

/**
 * @brief Sorted array of reference indices that matched their corresponding
 *        recognized token (`NSNumber`-wrapped `NSInteger`).
 *
 * Substitutions and deletions are *not* counted as matched on the reference
 * side — only exact-word matches.
 */
@property (nonatomic, readonly) NSArray<NSNumber *> *matchedRefIndices;

/**
 * @brief Sorted array of reference indices that did not match but lie at or
 *        below `furthestMatchedIndex` (`NSNumber`-wrapped `NSInteger`).
 *
 * Reference tokens past the furthest-matched index are treated as "not yet
 * reached" rather than skipped, and are excluded here. Useful for read-along
 * UIs that highlight skipped words.
 */
@property (nonatomic, readonly) NSArray<NSNumber *> *skippedRefIndices;

/**
 * @brief Highest matched reference index, or `NSNotFound` if no reference
 *        token matched.
 */
@property (nonatomic, readonly) NSInteger furthestMatchedIndex;

/**
 * @brief Reference indices flagged as repetitions in the recognized text
 *        (`NSNumber`-wrapped `NSInteger`).
 *
 * Populated only when `KIOSAlignmentConfig.detectRepetitions` was YES on the
 * call that produced this result. Empty otherwise.
 */
@property (nonatomic, readonly) NSArray<NSNumber *> *repetitionRefIndices;

@end

#pragma mark - KIOSTextAligner

/**
 * @class KIOSTextAligner
 * @brief Aligns recognized speech against a reference text using DP edit distance.
 *
 * Typical use is oral-reading scoring: a user reads a known passage, the ASR
 * produces a hypothesis, and the aligner reports which reference words were
 * read correctly, which were skipped, and how far the reader got. The same
 * primitive supports word-error-rate reporting for batch ASR evaluation.
 *
 * The reference text is normalized and tokenized once at construction and
 * cached. Subsequent calls to `align:` and `incrementalAlign:`
 * normalize their inputs using the same rules, so reference and recognized
 * sides share a canonical form.
 *
 * The language code passed at construction must match the ASR bundle that
 * produced (or will produce) the recognized text — normalization differs
 * subtly between languages (accent handling, `&` expansion, etc.) and a
 * mismatch silently degrades accuracy.
 *
 * ### Stateless vs. incremental
 *
 * - `align:` recomputes alignment from scratch each call. Safe to call
 *   concurrently from multiple threads.
 * - `incrementalAlign:` caches DP rows from the previous call and reuses
 *   them up to the longest common prefix of consecutive recognized inputs,
 *   amortizing cost across a stream of partial ASR results. **Not**
 *   thread-safe. Call `-reset` between utterances.
 *
 * ### Ownership
 *
 * The receiver owns its native counterpart and releases it on `dealloc`.
 */
@interface KIOSTextAligner : NSObject

/**
 * @brief Designated initializer. Constructs an aligner bound to the given
 *        reference text and language code.
 *
 * The reference is normalized and tokenized at construction; the cached
 * token vector is available via `referenceTokens`.
 *
 * @param reference Reference text to align against. Required.
 * @param langCode  ASR bundle language code, e.g. `"en-us"`, `"fr-fr"`,
 *                  `"de-de"`, `"es-es"`. Required.
 * @return An initialized aligner, or `nil` if construction failed.
 */
- (nullable instancetype)initWithReference:(NSString *)reference
                                  langCode:(NSString *)langCode
    NS_DESIGNATED_INITIALIZER;

/**
 * @brief Convenience initializer that sources the language code from a
 *        recognizer instance.
 *
 * Equivalent to calling `initWithReference:langCode:` with
 * `[recognizer asrBundleLang]`.
 *
 * @param reference  Reference text to align against. Required.
 * @param recognizer Initialized recognizer whose ASR bundle defines the
 *                   language code. Required.
 * @return An initialized aligner, or `nil` if construction failed.
 */
- (nullable instancetype)initWithReference:(NSString *)reference
                                recognizer:(KIOSRecognizer *)recognizer;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

#pragma mark Alignment

/**
 * @brief Align recognized text against the reference using default configuration.
 *
 * Equivalent to calling `align:config:` with a default-constructed
 * `KIOSAlignmentConfig`. Stateless — safe to call concurrently with itself.
 *
 * @param recognized Recognized text from the ASR engine.
 * @return Alignment result. Never `nil`.
 */
- (KIOSAlignmentResult *)align:(NSString *)recognized;

/**
 * @brief Align recognized text against the reference with custom configuration.
 *
 * Stateless — safe to call concurrently with itself.
 *
 * @param recognized Recognized text from the ASR engine.
 * @param config     Alignment configuration. Pass `nil` to use defaults.
 * @return Alignment result. Never `nil`.
 */
- (KIOSAlignmentResult *)align:(NSString *)recognized
                        config:(nullable KIOSAlignmentConfig *)config;

#pragma mark Incremental alignment

/**
 * @brief Align recognized text incrementally, reusing DP state from the
 *        previous call.
 *
 * Intended for use in partial-result callbacks where the recognized text
 * grows or changes slightly between calls. The aligner detects the longest
 * common prefix between successive inputs and recomputes only the divergent
 * tail.
 *
 * Call `-reset` when starting a new utterance to clear the cache.
 *
 * **Not thread-safe.** Do not call concurrently from multiple threads, and
 * do not interleave with `-align:` if you depend on the cache surviving.
 *
 * @param recognized Recognized text from the ASR engine.
 * @return Alignment result. Never `nil`.
 */
- (KIOSAlignmentResult *)incrementalAlign:(NSString *)recognized;

/**
 * @brief Incremental align with custom configuration.
 *
 * Changing cost values between successive calls invalidates the cache and
 * forces a full recompute on the next call.
 *
 * @param recognized Recognized text from the ASR engine.
 * @param config     Alignment configuration. Pass `nil` to use defaults.
 * @return Alignment result. Never `nil`.
 */
- (KIOSAlignmentResult *)incrementalAlign:(NSString *)recognized
                                   config:(nullable KIOSAlignmentConfig *)config;

/**
 * @brief Drop cached DP state. Call between utterances when using
 *        incremental alignment.
 */
- (void)reset;

#pragma mark Accessors

/**
 * @brief Normalized reference tokens, in order. Indices in alignment results
 *        refer to positions in this array.
 */
@property (nonatomic, readonly) NSArray<NSString *> *referenceTokens;

/**
 * @brief Language code this aligner was constructed with.
 */
@property (nonatomic, readonly, copy) NSString *langCode;

@end

NS_ASSUME_NONNULL_END
