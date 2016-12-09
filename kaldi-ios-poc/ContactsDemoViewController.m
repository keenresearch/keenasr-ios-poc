//
//  ContactsDemoViewController.m
//  kaldi-ios-poc
//
//  Created by Ognjen Todic on 6/2/16.
//  Copyright © 2016 Keen Research. All rights reserved.
//

#import "ContactsDemoViewController.h"

@import Contacts;


@interface ContactsDemoViewController()

@property (nonatomic, strong) UIButton *startListeningButton, *backButton;
@property (nonatomic, strong) UILabel *resultsLabel, *statusLabel;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, assign) BOOL initializedDecodingGraph;

// just to make it easier to access recognizer throught this class
@property (nonatomic, weak) KIOSRecognizer *recognizer;


@end

@implementation ContactsDemoViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  NSLog(@"Starting contacts demo");
  self.view.backgroundColor = [UIColor whiteColor];

  
  // back button
  self.backButton = [UIButton buttonWithType:UIButtonTypeSystem];
  self.backButton.frame = CGRectMake(10, 5, 100, 20);
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
  self.resultsLabel = [[UILabel alloc] initWithFrame:frame];
  self.resultsLabel.textAlignment = NSTextAlignmentCenter;
  self.resultsLabel.font = [UIFont systemFontOfSize:30];
  self.resultsLabel.numberOfLines = 0;
  [self.resultsLabel setAdjustsFontSizeToFitWidth:YES];
  self.resultsLabel.textColor = [UIColor blackColor];
  self.resultsLabel.backgroundColor = [UIColor clearColor];
  [self.view addSubview:self.resultsLabel];
  
  
  // spinner
  self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  float spWidth = 100, spHeight = 100;
  self.spinner.frame = CGRectMake(CGRectGetWidth(self.view.frame)/2 - spWidth/2,
                                  CGRectGetHeight(self.view.frame)/2 - spHeight/2,
                                  spWidth,
                                  spHeight);
  [self.view addSubview:self.spinner];
  self.spinner.alpha = 0;
  
  // status bar
  float slWidth = 300, slHeight=20;
  self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)/2-slWidth/2, 5, slWidth, slHeight)];
  self.statusLabel.textAlignment = NSTextAlignmentCenter;
  self.statusLabel.font = [UIFont systemFontOfSize:18];
  self.statusLabel.numberOfLines = 0;
  [self.statusLabel setAdjustsFontSizeToFitWidth:YES];
  self.statusLabel.textColor = [UIColor grayColor];
  self.statusLabel.backgroundColor = [UIColor clearColor];
  
  [self.view addSubview:self.statusLabel];
  
  // back button
  
  // keeping weak local reference just so we don't have to call shared instance
  // all the time
  self.recognizer = [KIOSRecognizer sharedInstance];
  // setup self to be the delegate for the recognizer so we get notifications
  // for partial/final results
  self.recognizer.delegate = self;
  [KIOSRecognizer setLogLevel:KIOSRecognizerLogLevelInfo];
  self.recognizer.createAudioRecordings = YES;
  
  // set Voice Activity Detection timeouts (defaults would probably be ok for
  // this use case, but we are changing them for the edu/reading demo and since
  // there is one recognizer we want to make sure they are  back to original
  // values
  // if user doesn't say anything for this many seconds we end recognition
  [self.recognizer setVADParameter:KIOSVadTimeoutForNoSpeech toValue:5];
  // we never run recognition longer than this many seconds
  [self.recognizer setVADParameter:KIOSVadTimeoutMaxDuration toValue:20];
  // end silence timeouts (somewhat arbitrary); too long and it may be weird
  // if the user finished. Too short and we may cut them off if they pause for a
  // while.
  [self.recognizer setVADParameter:KIOSVadTimeoutEndSilenceForGoodMatch toValue:1.2];
  // use the same setting here as for the good match, although this could be
  // slightly longer
  [self.recognizer setVADParameter:KIOSVadTimeoutEndSilenceForAnyMatch toValue:1.2];

  // on first tap we will initialize the
  // decoder with the custom decoding graph via startListningWithCustomDecodingGraph
  // and set this to YES, so that subsequent taps on Start trigger only startListening
  self.initializedDecodingGraph = NO;
  
  self.startListeningButton.enabled = NO;
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
  
  // If we had arpa language model in the asr bundle, we could create decoding graph
  // directly from the arpa file following the commented-out steps below.
  
//    NSArray *parts = [NSArray arrayWithObjects: [[NSBundle mainBundle] resourcePath], self.recognizer.asrBundlePath, @"file.arpa", nil];
//    NSURL *arpaURL = [NSURL fileURLWithPathComponents:parts];
//    [dg createDecodingGraphFromArpaURL:arpaURL andSaveWithName:@"file-dg"];
  
  // Since we are using data from the phone's music library, we will first
  // compose a list of relevant phrases
  NSArray *sentences = [self createContactsDemoSentences];
  if ([sentences count] == 0) {
    self.statusLabel.text = @"Unable to access contacts";
    return;
  }
  
  // and create custom decoding graph named 'contacts' using those phrases
  if (! [dg createDecodingGraphFromSentences:sentences andSaveWithName:@"contacts"]) {
    self.resultsLabel.text = @"Error occured while creating decoding graph from users contacts";
    [self.spinner stopAnimating];
    self.spinner.alpha = 0;
    return;
  }
  self.statusLabel.text = @"Completed decoding graph"; // TODO - add num contacts
  
  [self.spinner stopAnimating];
  self.spinner.alpha = 0;
  // Note that this decoding graph doesn't need to be created in this view controller.
  // It could have been created any time; we just need to know the name so we can
  // reference it when starting to listen
  
  self.startListeningButton.alpha = 1;
  self.startListeningButton.enabled = YES;
  self.backButton.enabled = YES;
  self.resultsLabel.textColor = [UIColor lightGrayColor];
  self.resultsLabel.text = @"Tap the button and then say \"CALL <CONTACT_NAME>\" (e.g. Call John, if he is in your contacts)";
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
  self.resultsLabel.text = @"";
  self.statusLabel.text = @"Listening...";

  // start listening using decoding graph we created in viewDidAppear
  if (! self.initializedDecodingGraph) {
    [self.recognizer startListeningWithCustomDecodingGraph:@"contacts"];
    self.initializedDecodingGraph = YES;
  } else {
    [self.recognizer startListening]; // decoding graph is already set so we can just call startListening
    // this if/else is not mandatory, but there is some overhead in loading the
    // decoding graph so if we continue listening with the same graph it's better
    // to call startListening
  }
}


- (void)backButtonTapped:(id)sender {
  if ([self.recognizer listening])
      [self.recognizer stopListening];
  
  [self dismissViewControllerAnimated:YES completion:^{}];
}



#pragma mark KIOSRecognizer delegate methods

- (void)recognizerPartialResult:(KIOSResult *)result forRecognizer:(KIOSRecognizer *)recognizer {
  NSLog(@"Partial Result: %@ (%@)", result.cleanText, result.text);
  self.resultsLabel.textColor = [UIColor grayColor];
  self.resultsLabel.text = result.cleanText;
}


- (void)recognizerFinalResult:(KIOSResult *)result forRecognizer:(KIOSRecognizer *)recognizer {
  NSLog(@"Final Result: %@", result);
  if (recognizer.createAudioRecordings)
    NSLog(@"Audio recording is in %@", recognizer.lastRecordingFilename);
  if (result.confidence && [result.confidence floatValue] < 0.7)
    self.resultsLabel.textColor = [UIColor redColor];
  else
    self.resultsLabel.textColor = [UIColor blackColor];
  
  self.resultsLabel.text = result.cleanText;
  self.statusLabel.text = @"Done Listening";
  self.startListeningButton.enabled = YES;
}



- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskLandscape;
}



- (NSArray *)createContactsDemoSentences {
  NSMutableArray *sentences = [NSMutableArray new];
  
  CNContactStore *addressBook = [CNContactStore new];
  NSArray *keysToFetch = @[CNContactGivenNameKey, CNContactFamilyNameKey,
                           CNContactNicknameKey];
  CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc]
                                         initWithKeysToFetch:keysToFetch];
  int __block numContacts=0;
  // we create couple of variations for each contact ("CALL FNAME LNAME",
  // "CALL LNAME FNAME", "FNAME LNAME". Other combinations will also be
  // implicitely covered via unigrams
  // this will slightly bias (make it slightly more likely) entries with only
  // first or last name. Doesn't matter for the demo purposes though.
  [addressBook enumerateContactsWithFetchRequest:fetchRequest error:nil
                                      usingBlock:^(CNContact * __nonnull contact,
                                                   BOOL * __nonnull stop) {
                                        if ((!contact.givenName && !contact.familyName) ||
                                            ([contact.givenName length]==0 && [contact.familyName length]==0)) {
                                          NSLog(@"Skipping empty contact (no first/last name)");
                                          return;
                                        }
                                        numContacts++;
                                        NSString *sent1 = [NSString stringWithFormat:
                                                           @"Call %@ %@", contact.givenName, contact.familyName];
                                        sent1 = [sent1 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                        sent1 = [sent1 stringByReplacingOccurrencesOfString:@"  " withString:@" "];
                                        [sentences addObject:sent1];
                                        NSString *sent2 = [NSString stringWithFormat:
                                                           @"Call %@ %@", contact.familyName,
                                                           contact.givenName];
                                        sent2 = [sent2 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                        sent2 = [sent2 stringByReplacingOccurrencesOfString:@"  " withString:@" "];
                                        [sentences addObject:sent2];

                                        NSString *sent3 = [NSString stringWithFormat:
                                                           @"%@ %@", contact.familyName,
                                                           contact.givenName];
                                        sent3 = [sent3 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                        sent3 = [sent3 stringByReplacingOccurrencesOfString:@"  " withString:@" "];
                                        [sentences addObject:sent3];
                                        
                                        NSString *sent4 = [NSString stringWithFormat:
                                                           @"%@ %@", contact.givenName,
                                                           contact.familyName];
                                        sent4 = [sent4 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                        sent4 = [sent4 stringByReplacingOccurrencesOfString:@"  " withString:@" "];
                                        [sentences addObject:sent4];
                                      }];
  
  NSLog(@"Got %d contacts from the address book", numContacts);
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
