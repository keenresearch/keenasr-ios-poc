//
//  MusicDemoViewController.m
//  kaldi-ios-poc
//
//  Created by Ognjen Todic on 6/2/16.
//  Copyright © 2016 Keen Research. All rights reserved.
//

#import "MusicDemoViewController.h"
@import MediaPlayer;


@interface MusicDemoViewController ()

@property (nonatomic, strong) UIButton *startListeningButton, *backButton;
@property (nonatomic, strong) UILabel *resultsLabel, *statusLabel;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@property(nonatomic, strong) NSArray *words;

// just to make it easier to access recognizer throught this class
@property (nonatomic, weak) KIOSRecognizer *recognizer;


@end

@implementation MusicDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
  NSLog(@"Starting music demo");
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
  self.recognizer.createAudioRecordings=YES;
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
  [self.recognizer setVADParameter:KIOSVadTimeoutEndSilenceForGoodMatch toValue:1];
  // use the same setting here as for the good match, although this could be
  // slightly longer
  [self.recognizer setVADParameter:KIOSVadTimeoutEndSilenceForAnyMatch toValue:1];
  
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

  NSLog(@"View appeared, checking access to the media library");
  
  if ([MPMediaLibrary authorizationStatus] != MPMediaLibraryAuthorizationStatusAuthorized) {
    [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus status) {
      if (status == MPMediaLibraryAuthorizationStatusAuthorized) {
        [self prepareForListening];
      } else {
        self.startListeningButton.enabled = NO;
        self.backButton.enabled = YES;
        self.statusLabel.text =@"No permission to access music library";
        self.resultsLabel.text = @"It seems you've declined access to the music library. To proceed you will need to allow access under iPhone Settings for this app";
      }
      
    }];
  } else {
    [self prepareForListening];
  }
}

- (void)prepareForListening {
  NSLog(@"View appeared, setting up decoding graph now");
  // Since we are using data from the phone's music library, we will first
  // compose a list of relevant phrases
  NSArray *sentences = [self createMusicDemoSentences];
  if ([sentences count] == 0) {
    self.statusLabel.text = @"Unable to access music library";
    return;
  }
  
  // and create custom decoding graph named 'music' using those phrases
  NSString *dgName = @"music";
  if (! [KIOSDecodingGraph createDecodingGraphFromSentences:sentences
                                              forRecognizer:self.recognizer
                                            andSaveWithName:dgName]) {
    self.resultsLabel.text = @"Error occured while creating decoding graph from users music library";
    [self.spinner stopAnimating];
    self.spinner.alpha = 0;
    return;
  }
  // Note that this decoding graph doesn't need to be created in this view controller.
  // It could have been created any time; we just need to know the name so we can
  // reference it when we need to call preprareForListening methods
  
  NSLog(@"Preparing to listen with custom decoding graph '%@'", dgName);
  [self.recognizer prepareForListeningWithCustomDecodingGraphWithName:dgName];
  NSLog(@"Ready to start listening");
  
  [self.spinner stopAnimating];
  self.spinner.alpha = 0;
  
  self.resultsLabel.textColor = [UIColor lightGrayColor];
  self.resultsLabel.text = @"Tap the button an then say \"PLAY <ARTIST_NAME>\" or \"PLAY <SONG_NAME>\", or \"PLAY <SONG_NAME> by <ARTIST_NAME>\", where <ARTIST_NAME> and <SONG_NAME> are name of a song or an artist in your music library on this device";
  
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
  self.resultsLabel.text = @"";
  self.statusLabel.text = @"Listening...";
  // since we are using only a single decoding graph here, we can just call startListening
  //  [self.recognizer startListening];
  
  // start listening using decoding graph we created in viewDidAppear
  [self.recognizer startListening];
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
  NSLog(@"Final Result: %@ (%@, conf: %@)", result.cleanText, result.text, result.confidence);
  if (recognizer.createAudioRecordings)
    NSLog(@"Audio recording is in %@", recognizer.lastRecordingFilename);
  self.resultsLabel.textColor = [UIColor blackColor];
  self.resultsLabel.text = result.cleanText;
  self.statusLabel.text = @"Done Listening";
  self.startListeningButton.enabled = YES;
}



- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskLandscape;
}



- (NSArray *)createMusicDemoSentences {
  NSMutableArray *sentences = [NSMutableArray new];
  MPMediaQuery *songsQuery = [MPMediaQuery songsQuery];
  NSArray *songs = songsQuery.items;
  NSString *prevArtist;
  NSLog(@"Found %ld songs in the library", (unsigned long)[songs count]);
  for (int i=0; i<[songs count]; i++) {
    MPMediaItem *item = songs[i];
    NSString *title = [item valueForProperty:MPMediaItemPropertyTitle];
    NSString *artist = [item valueForProperty:MPMediaItemPropertyArtist];

    [sentences addObject:[NSString stringWithFormat:@"PLAY %@ by %@", title, artist]];
    [sentences addObject:[NSString stringWithFormat:@"PLAY %@", title]];
    [sentences addObject:title];
    if (! [artist isEqualToString:prevArtist]) {
      [sentences addObject:[NSString stringWithFormat:@"PLAY %@", artist]];
      [sentences addObject:artist];
      prevArtist = artist;
    }
  }
  // TODO add genres, slow, moderate, fast
  return sentences;
}


- (void)recognizerReadyToListenAfterInterrupt:(KIOSRecognizer *)recognizer {
  self.startListeningButton.enabled = YES;
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
