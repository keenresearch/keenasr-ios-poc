//
//  CommandAndControlViewController.m
//  kaldi-ios-poc
//
//  Created by Ognjen Todic on 11/18/16.
//  Copyright © 2016 Keen Research. All rights reserved.
//

#import "CommandAndControlViewController.h"


// end speech timeout if we recognized something that looks like a relevant word
static float kEndSpeechTimeoutShort = 0.8;

@interface CommandAndControlViewController ()

@property (nonatomic, strong) UIButton *startListeningButton, *backButton;
@property (nonatomic, strong) UILabel *textLabel, *statusLabel;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSArray *words;

// just to make it easier to access recognizer throught this class
@property (nonatomic, weak) KIOSRecognizer *recognizer;
@end

@implementation CommandAndControlViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
  
  // Do any additional setup after loading the view.
  NSLog(@"Starting edu-words demo");
    self.view.backgroundColor = [UIColor whiteColor];
  
  // back button
  self.backButton = [UIButton buttonWithType:UIButtonTypeSystem];
  self.backButton.frame = CGRectMake(20, 5, 100, 20);
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
                                               CGRectGetHeight(self.view.frame)-height - 15,
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
  self.textLabel.font = [UIFont systemFontOfSize:45];
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
  
  
  // keeping weak local reference just so we don't have to call shared instance
  // all the time
  self.recognizer = [KIOSRecognizer sharedInstance];
  [KIOSRecognizer setLogLevel:KIOSRecognizerLogLevelDebug];
  
  // setup self to be the delegate for the recognizer so we get notifications
  // for partial/final results
  self.recognizer.delegate = self;
  
  // set Voice Activity Detection timeouts
  // if user doesn't say anything for this many seconds we end recognition
  [self.recognizer setVADParameter:KIOSVadTimeoutForNoSpeech toValue:10];
  // we never run recognition longer than this many seconds
  [self.recognizer setVADParameter:KIOSVadTimeoutMaxDuration toValue:20];
  // end silence timeouts (somewhat arbitrary); too long and it may be weird
  // if the user finished. Too short and we may cut them off if they pause for a
  // while.
  // In this demo we will dynamically change the end timeouts. Initially we set
  // them to a fairly large values, but in partialResult callbacks we will reduce
  // them significantly if we spotted a correct word. That way user could say
  // "SPELL...." and if they hesitate for a while to say the word we won't cut
  // them off. But, if they say the right word (actually, we think they said the
  // right word, then we timeout faster.
  [self.recognizer setVADParameter:KIOSVadTimeoutEndSilenceForGoodMatch
                           toValue:kEndSpeechTimeoutShort];
  // use the same setting here as for the good match, although this could be
  // slightly longer
  [self.recognizer setVADParameter:KIOSVadTimeoutEndSilenceForAnyMatch
                           toValue:kEndSpeechTimeoutShort];
  
  self.startListeningButton.enabled = NO;
}



- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  self.spinner.alpha = 1;
  [self.spinner startAnimating]; //
  
  self.statusLabel.text = @"Creating graph and preparing to listen...";
}


- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  NSLog(@"View appeared, setting up decoding graph now");
  
  // we'll create decoding graph based on the sentences in the paragraph presented
  // to the user
  NSArray *sentences = [self createSentences];
  if ([sentences count] == 0) {
    self.statusLabel.text = @"Unable to create a list of sentences for the decoding graph";
    return;
  }
  
  // explore these two methods just for fun; regardless we will recreate the
  // decoding graph but in real case scenario we may want to avoid creating it
  // if it already exists
  NSString *dgName = @"commands";
  if ([KIOSDecodingGraph decodingGraphWithNameExists:dgName forRecognizer:self.recognizer]) {
    NSLog(@"Custom decoding graph '%@' exists", dgName);
    NSDate *createdOn = [KIOSDecodingGraph decodingGraphCreationDate:dgName
                                                       forRecognizer:self.recognizer];
    NSLog(@"It was created on %@", createdOn);
  } else {
    NSLog(@"Decoding graph '%@' doesn't exist", dgName);
  }
  
  // create custom decoding graph using sentences obtained above
  if (! [KIOSDecodingGraph createDecodingGraphFromSentences:sentences
                                              forRecognizer:self.recognizer
                                            andSaveWithName:dgName]) {
    self.textLabel.text = @"Error occured while creating decoding graph from the text";
    [self.spinner stopAnimating];
    self.spinner.alpha = 0;
    return;
  }
  NSLog(@"Preparing to listen with custom decoding graph '%@'", dgName);
  [self.recognizer prepareForListeningWithCustomDecodingGraphWithName:dgName];

  NSLog(@"Ready to start listening");

  [self.spinner stopAnimating];
  self.spinner.alpha = 0;
  self.statusLabel.text = @"Completed decoding graph";
  
  // Note that this decoding graph doesn't need to be created in this view controller.
  // It could have been created any time; we just need to know the name so we can
  // reference it when starting to listen
  
  self.textLabel.textColor = [UIColor lightGrayColor];
  self.textLabel.textAlignment = UIControlContentHorizontalAlignmentLeft;
  self.textLabel.text = @"Tap the button and then say a command (left, right, up, down, run, lay down, jump, stop, spin, follow me)";
  
  self.startListeningButton.alpha = 1;
  self.startListeningButton.enabled = YES;
  self.backButton.enabled = YES;
}


- (void)viewWillDisappear:(BOOL)animated {
  // We save speaker profile when view is about to disappear. You can do this
  // on other events as well if needed. The main reason we are doing this is so
  // that on subsequent starts of the app we can reuse the speaker profile and
  // not start from the baseline
  [self.recognizer saveSpeakerAdaptationProfile];
  
  [super viewWillDisappear:animated];
}


- (void)startListeningButtonTapped:(id)sender {
  self.startListeningButton.enabled = NO;
  self.textLabel.text = @"";
  self.textLabel.textColor = [UIColor lightGrayColor];
  self.statusLabel.text = @"Listening...";
  
  // start listening using decoding graph we created in viewDidAppear
  [self.recognizer startListening];
}


- (void)backButtonTapped:(id)sender {
  if (self.recognizer.recognizerState == KIOSRecognizerStateListening ||
      self.recognizer.recognizerState == KIOSRecognizerStateFinalProcessing)
    [self.recognizer stopListening];
    // if you wanted to obtain the final result for everything processed up to
    // now, you could call this method instead
//    KIOSResult *result = [self.recognizer stopListeningAndReturnFinalResult];
//    NSLog(@"Final result (direct) is: %@", result);
  
  [self dismissViewControllerAnimated:YES completion:^{}];
}



#pragma mark KIOSRecognizer delegate methods

- (void)unwindAppAudioBeforeAudioInterrupt {
  NSLog(@"Unwinding app audio (nothing to do here since app doens't play audio");
}


- (void)recognizerPartialResult:(KIOSResult *)result forRecognizer:(KIOSRecognizer *)recognizer {
  NSLog(@"Partial Result: %@ (%@), conf %@", result.cleanText, result.text, result.confidence);
  
  self.textLabel.text = result.cleanText;
}


- (void)recognizerFinalResult:(KIOSResult *)result forRecognizer:(KIOSRecognizer *)recognizer {
  NSLog(@"Final Result: %@", result);
  
  self.textLabel.text = result.cleanText;
  if ([result.confidence floatValue] < 0.7) { //
    self.textLabel.textColor = [UIColor redColor];
  //    self.textLabel.text = @"";
  //    NSLog(@"Ignoring recognized phrase due to low confidence");
  //    // TODO if we got here bcs something was recognized in partial callback but now
  //    // based on confidence we are ignoring it, we should probably continue listening
  //    // i.e. call startListening from here
  } else {
    self.textLabel.textColor = [UIColor blackColor];
  }
  
  if (recognizer.createAudioRecordings)
    NSLog(@"Audio recording is in %@", recognizer.lastRecordingFilename);
  
  self.statusLabel.text = @"Done Listening";
  self.startListeningButton.enabled = YES;
}


- (void)recognizerReadyToListenAfterInterrupt:(KIOSRecognizer *)recognizer {
  self.startListeningButton.enabled = YES;
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskLandscape;
}




- (NSArray *)createSentences {
  NSArray *sentences = @[
//                         @"ache",
//                         @"cay",
//                         @"k"
//                                                  @"Go left",
//                         @"up",
@"one",
@"two",
@"three",
@"four",
@"five",
@"six",
@"seven",
@"eight",
@"nine",
@"zero",
@"favor",

                         //                         @"left",
//                         @"go right",
//                         @"right",
//                         @"june",
//                         @"hint",
//                         @"go up",
//                         @"up",
//                         @"go down",
//                         @"down",
//                         @"jump",
//                         @"stop",
//                         @"spin",
//                         @"run",
//                         @"faster",
//                         @"slower",
//                         @"lay down",
//                         @"follow me",
                         ];

  return sentences;
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
