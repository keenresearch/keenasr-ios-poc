//
//  EduReadingDemoViewController.m
//  kaldi-ios-poc
//
//  Created by Ognjen Todic on 6/2/16.
//  Copyright © 2016 Keen Research. All rights reserved.
//

#import "EduReadingDemoViewController.h"

@interface EduReadingDemoViewController()

@property (nonatomic, strong) UIButton *startListeningButton, *backButton;
@property (nonatomic, strong) UILabel *textLabel, *statusLabel;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, assign) BOOL initializedDecodingGraph;

@property (nonatomic, assign) float rateOfSpeech;
@property (nonatomic, strong) UILabel *rateOfSpeechLabel;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, assign) unsigned long numWords; // number of words in the current hypothesis (used for ROS)
// use this timer to update rate of speech UI label periodically
@property (nonatomic, strong) NSTimer *rosUpdateTimer;

// just to make it easier to access recognizer throught this class
@property (nonatomic, weak) KIOSRecognizer *recognizer;


@end

@implementation EduReadingDemoViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.text = @"Once upon a time there were three little pigs One pig built a house of straw while the second pig built his house with sticks They built their houses very quickly and then sang and danced all day because they were lazy The third little pig worked hard all day and built his house with bricks."; //A big bad wolf saw the two little pigs while they danced and played and thought, “What juicy tender meals they will make!” He chased the two pigs and they ran and hid in their houses. The big bad wolf went to the first house and huffed and puffed and blew the house down in minutes.";
  
  
  // Do any additional setup after loading the view.
  NSLog(@"Starting edu-reading demo");
  self.view.backgroundColor = [UIColor whiteColor];
  
  // back button
  self.backButton = [UIButton buttonWithType:UIButtonTypeSystem];
  self.backButton.frame = CGRectMake(5, 5, 100, 20);
  self.backButton.titleLabel.font = [UIFont systemFontOfSize:18];
  self.backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
  self.backButton.backgroundColor = [UIColor clearColor];
  [self.backButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
  [self.backButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
  [self.backButton setTitle:@"Back" forState:UIControlStateNormal];
  [self.backButton addTarget:self action:@selector(backButtonTapped:) forControlEvents:UIControlEventTouchDown];
  [self.view addSubview:self.backButton];
  self.backButton.enabled = NO;
  
  // start button
  self.startListeningButton = [UIButton buttonWithType:UIButtonTypeSystem];
  float width=220, height=40;
  self.startListeningButton.frame = CGRectMake((CGRectGetWidth(self.view.frame)-width)/2,
                                               CGRectGetHeight(self.view.frame)-height - 5,
                                               width,
                                               height);
  self.startListeningButton.titleLabel.font = [UIFont systemFontOfSize:30];
  [self.view addSubview:self.startListeningButton];
  self.startListeningButton.backgroundColor = [UIColor clearColor];
  [self.startListeningButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
  [self.startListeningButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
  [self.startListeningButton setTitle:@"TAP TO START" forState:UIControlStateNormal];
  [self.startListeningButton addTarget:self action:@selector(startListeningButtonTapped:) forControlEvents:UIControlEventTouchDown];
  self.startListeningButton.alpha = 0;
  
  // setup results label
  float w = CGRectGetWidth(self.view.frame) - 120;
  float h = 200;
  CGRect frame = CGRectMake((CGRectGetWidth(self.view.frame)-w)/2,
                            (CGRectGetHeight(self.view.frame)-h)/2,
                            w, h);
  self.textLabel = [[UILabel alloc] initWithFrame:frame];
  self.textLabel.textAlignment = NSTextAlignmentLeft;
  self.textLabel.font = [UIFont systemFontOfSize:30];
  self.textLabel.numberOfLines = 0;
  [self.textLabel setAdjustsFontSizeToFitWidth:YES];
  self.textLabel.textColor = [UIColor blackColor];
  self.textLabel.backgroundColor = [UIColor clearColor];
  [self.view addSubview:self.textLabel];
  
  
  // spinner
  self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  float spWidth = 100, spHeight = 100;
  self.spinner.frame = CGRectMake(CGRectGetWidth(self.view.frame)/2 - spWidth/2,
                                  CGRectGetHeight(self.view.frame)/2 - spHeight/2,
                                  spWidth,
                                  spHeight);
  [self.view addSubview:self.spinner];
  self.spinner.alpha = 0;
  
  // status label
  float slWidth = 300, slHeight=20;
  self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)/2-slWidth/2, 5, slWidth, slHeight)];
  self.statusLabel.textAlignment = NSTextAlignmentCenter;
  self.statusLabel.font = [UIFont systemFontOfSize:18];
  self.statusLabel.numberOfLines = 0;
  [self.statusLabel setAdjustsFontSizeToFitWidth:YES];
  self.statusLabel.textColor = [UIColor grayColor];
  self.statusLabel.backgroundColor = [UIColor clearColor];
  
  [self.view addSubview:self.statusLabel];
  
  // rateOfSpeech label
  // we are currently estimating rate of speech in partialresult callback, so the
  // value on the screen will not be updated constantly, only when there is new
  // partial result (but ROS changes regardless since denominator changes)
  // We update it on the final result; in a real app, that's when ROS would be
  // estimated anyway and it also probably doesn't need to be displayed in the
  // real time for the user
  float rosLWidth = 300, rosLHeight=20;
  self.rateOfSpeechLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame) - rosLWidth - 5, 5, rosLWidth, rosLHeight)];
  self.rateOfSpeechLabel.textAlignment = NSTextAlignmentRight;
  self.rateOfSpeechLabel.font = [UIFont systemFontOfSize:18];
  self.rateOfSpeechLabel.numberOfLines = 0;
  [self.rateOfSpeechLabel setAdjustsFontSizeToFitWidth:YES];
  self.rateOfSpeechLabel.textColor = [UIColor blackColor];
  self.rateOfSpeechLabel.backgroundColor = [UIColor clearColor];
  self.rateOfSpeechLabel.text = [NSString stringWithFormat:@"Words per minute: %.0f", self.rateOfSpeech];
  [self.view addSubview:self.rateOfSpeechLabel];
  
  // keeping weak local reference just so we don't have to call shared instance
  // all the time
  self.recognizer = [KIOSRecognizer sharedInstance];
  [KIOSRecognizer setLogLevel:KIOSRecognizerLogLevelInfo];
  
  // setup self to be the delegate for the recognizer so we get notifications
  // for partial/final results
  self.recognizer.delegate = self;
  
  // set Voice Activity Detection timeouts
  // if user doesn't say anything for this many seconds we end recognition
  [self.recognizer setVADParameter:KIOSVadTimeoutForNoSpeech toValue:10];
  // we never run recognition longer than this many seconds
  [self.recognizer setVADParameter:KIOSVadTimeoutMaxDuration toValue:40];
  // end silence timeouts (somewhat arbitrary); too long and it may be weird
  // if the user finished. Too short and we may cut them off if they pause for a
  // while.
  [self.recognizer setVADParameter:KIOSVadTimeoutEndSilenceForGoodMatch toValue:5];
  // use the same setting here as for the good match, although this could be
  // slightly longer
  [self.recognizer setVADParameter:KIOSVadTimeoutEndSilenceForAnyMatch toValue:5];
  
  self.startListeningButton.enabled = NO;
  
  // on first tap we will initialize the
  // decoder with the custom decoding graph via startListningWithCustomDecodingGraph
  // and set this to YES, so that subsequent taps on Start trigger only startListening
  self.initializedDecodingGraph = NO;
}



- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  self.spinner.alpha = 1;
  [self.spinner startAnimating]; //
  
  self.statusLabel.text = @"Creating decoding graph...";
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  NSLog(@"View appeared, setting up decoding graph now");
  
  KIOSDecodingGraph *dg = [[KIOSDecodingGraph alloc] initWithRecognizer:self.recognizer];
  

  // we'll create decoding graph based on the sentences in the paragraph presented
  // to the user
  NSArray *sentences = [self createReadingSentences];
  if ([sentences count] == 0) {
    self.statusLabel.text = @"Unable to create a list of sentences for decoding graph";
    return;
  }
  
  // explore these two methods just for fun; regardless we will recreate the
  // decoding graph
  NSString *dgName = @"reading";
  if ([dg decodingGraphExists:dgName]) {
    NSLog(@"Custom decoding graph '%@' exists", dgName);
    NSDate *createdOn = [dg decodingGraphCreationDate:dgName];
    NSLog(@"It was created on %@", createdOn);
  } else {
    NSLog(@"Decoding graph '%@' doesn't exist", dgName);
  }
  
  // create custom decoding graph with (arbitraty) name 'reading' using
  // sentences obtained above
  if (! [dg createDecodingGraphFromSentences:sentences andSaveWithName:@"reading"]) {
    self.textLabel.text = @"Error occured while creating decoding graph from the text";
    [self.spinner stopAnimating];
    self.spinner.alpha = 0;
    return;
  }

  [self.spinner stopAnimating];
  self.spinner.alpha = 0;
  self.statusLabel.text = @"Completed decoding graph"; // TODO - add num songs/artists
  
  [self.spinner stopAnimating];
  self.spinner.alpha = 0;
  // Note that this decoding graph doesn't need to be created in this view controller.
  // It could have been created any time; we just need to know the name so we can
  // reference it when starting to listen
  
  self.textLabel.textColor = [UIColor lightGrayColor];
  self.textLabel.textAlignment = UIControlContentHorizontalAlignmentLeft;
  self.textLabel.text = @"Tap the button and then read the paragraph aloud. Words will be highlighted as you read them (for example, try to skip some words)";
  
  self.startListeningButton.alpha = 1;
  self.startListeningButton.enabled = YES;
  self.backButton.enabled = YES;
}



- (void)startListeningButtonTapped:(id)sender {
  self.startListeningButton.enabled = NO;
  self.textLabel.text = self.text;
  self.statusLabel.text = @"Listening...";
  self.startTime = [NSDate date];
  
  
  self.rateOfSpeechLabel.text = [NSString stringWithFormat:@"Words per minute:"];
  self.rosUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateRosUILabel:) userInfo:nil repeats:YES];
  
  // start listening using decoding graph we created in viewDidAppear
  if (! self.initializedDecodingGraph) {
    [self.recognizer startListeningWithCustomDecodingGraph:@"reading"];
    self.initializedDecodingGraph = YES;
  } else {
    [self.recognizer startListening]; // decoding graph is already set so we can just call startListening
    // this if/else is not mandatory, but there is some overhead in loading the
    // decoding graph so if we continue listening with the same graph it's better
    // to call startListening
  }
}


- (void)updateRosUILabel:(id)sender {
  NSTimeInterval minSinceStart = -1*[self.startTime timeIntervalSinceNow]/60;
  self.rateOfSpeech = self.numWords/minSinceStart;
  self.rateOfSpeechLabel.text = [NSString stringWithFormat:@"Words per minute: %.0f", self.rateOfSpeech];
}



- (void)backButtonTapped:(id)sender {
  if ([self.recognizer listening])
    [self.recognizer stopListening];
  [self.rosUpdateTimer invalidate];
  
  [self dismissViewControllerAnimated:YES completion:^{}];
}



#pragma mark KIOSRecognizer delegate methods

// This demo relies on the partial results for higlighting, since the recognizer is
// listening all the time and we want to highlight the text in real-time as user
// reads it. Final hypothesis (which may be more accurate), can be used for a
// more detailed evaluation/assessment of oral reading
// This should rely on a more reliable string alignment algorithm (below is a simple
// approximation that won't always work.
// Also, acoustically similar words (e..g 'they' and 'day' should be taken into
// consideration (e.g. some fuzzy match using a simple lookup of other acoustically
// similar words when comparing any given word -- that way false alarms will not
// affect user experience
- (void)recognizerPartialResult:(KIOSResult *)result forRecognizer:(KIOSRecognizer *)recognizer {
  NSLog(@"Partial Result: %@ (%@)", result.cleanText, result.text);

  self.numWords = [result.cleanText length] - [[result.cleanText stringByReplacingOccurrencesOfString:@" " withString:@""] length];

  NSLog(@"Partial Result (%lu words): %@", self.numWords, result.cleanText);

  NSArray *rangesToHiglight = [self getMatchedRangesForString:result.cleanText
                                                 withinString:self.text];
  NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:self.text];
  [attrStr addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, [self.text length])];
  for (int i=0; i<[rangesToHiglight count]; i++) {
    NSRange range;
    [[rangesToHiglight objectAtIndex:i] getValue:&range];
    [attrStr addAttribute:NSBackgroundColorAttributeName value:[[UIColor yellowColor] colorWithAlphaComponent:.3] range:range];
    [attrStr addAttribute:NSUnderlineColorAttributeName value:[UIColor redColor] range:range];
    [attrStr addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleDouble] range:range];
//    NSLog(@"Highlighting range %@", NSStringFromRange(range));
  }
  self.textLabel.attributedText = attrStr;
  
  //  self.resultsLabel.textColor = [UIColor grayColor];
  //  self.resultsLabel.text = result.cleanText;
}


// NOTE: we update ROS label here as well, but it will be sligtly off because
// we are including endTimeout silence as well. In the future, KIOSResult class
// will provide start/end times for individual words; then, we could look up the
// end time of the last word to do a final ROS estimation
- (void)recognizerFinalResult:(KIOSResult *)result forRecognizer:(KIOSRecognizer *)recognizer {
  NSLog(@"Final Result: %@ (%@, conf: %@)", result.cleanText, result.text, result.confidence);
  [self.rosUpdateTimer invalidate];

  unsigned long numWords = [result.cleanText length] - [[result.cleanText stringByReplacingOccurrencesOfString:@" " withString:@""] length];
  NSLog(@"Final Result (%lu words): %@", numWords, result.cleanText);
  NSTimeInterval minSinceStart = -1*[self.startTime timeIntervalSinceNow]/60;
  self.rateOfSpeech = numWords/minSinceStart;
  self.rateOfSpeechLabel.text = [NSString stringWithFormat:@"Words per minute: %.0f", self.rateOfSpeech];

  if (recognizer.createAudioRecordings)
    NSLog(@"Audio recording is in %@", recognizer.lastRecordingFilename);
  self.statusLabel.text = @"Done Listening";
  self.startListeningButton.enabled = YES;
}




// A simple (incomplete) matching between the substr and str that returns an
// array of NSRanges that correspond to the sections of str that match with the
// substr.
//
// TODO: the right way to do this would be to do string (word) alignment between
// the two strings
- (NSArray *)getMatchedRangesForString:(NSString *)substr withinString:(NSString *)str {
  NSMutableArray *ranges = [NSMutableArray new];
  
  NSArray *words = [substr componentsSeparatedByString:@" "];
  NSRange searchRange = NSMakeRange(0, [str length]);
  NSRange prevRange = NSMakeRange(0,0);
  NSRange foundRange = NSMakeRange(0,0);
  int cnt=0;
  for (NSString *word in words) {
    cnt++;
    foundRange = [str rangeOfString:word options:NSCaseInsensitiveSearch range:searchRange];
    if (foundRange.location == NSNotFound) {
      continue;  // TODO - handle situation when user goes back. ignoring for now
      // if nothing, look back (but not if stop-word or another short word)
      // if nothing, take two words and look for a match
    }
    // move the pointer for searching
    searchRange.location = foundRange.location+foundRange.length;
    searchRange.length = [str length] - searchRange.location;
    // we allow one space btw words (should be smarter and check chars in between)
    if (foundRange.location - (prevRange.location + prevRange.length) <= 1) {
      prevRange.length = foundRange.location + - prevRange.location + foundRange.length;
    } else {
      [ranges addObject:[NSValue valueWithBytes:&prevRange objCType:@encode(NSRange)]];
      prevRange = foundRange;
    }
  }
  if (! NSEqualRanges(foundRange, prevRange) || cnt==1)
    [ranges addObject:[NSValue valueWithBytes:&prevRange objCType:@encode(NSRange)]];
  
  return ranges;
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskLandscape;
}




- (NSArray *)createReadingSentences {
  NSMutableArray *sentences = [NSMutableArray new];
//  [sentences addObject:self.text];
  [sentences addObject:@"Once upon a time there were three little pigs"];
  [sentences addObject:@"One pig built a house of straw while the second pig built his house with sticks"];
  [sentences addObject:@"They built their houses very quickly and then sang and danced all day because they were lazy"];
  [sentences addObject:@"The third little pig worked hard all day and built his house with bricks"];
  return sentences;
}




- (BOOL) shouldAutorotate  {
  return YES;
}




- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
