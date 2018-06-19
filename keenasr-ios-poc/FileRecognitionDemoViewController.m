//
//  FileRecognitionDemoViewController.m
//  kaldi-ios-poc
//
//  Created by Ognjen Todic on 10/24/16.
//  Copyright © 2016 Keen Research. All rights reserved.
//

#import "FileRecognitionDemoViewController.h"

@interface FileRecognitionDemoViewController () {
  int currentFileInd;
  NSString *filePath, *fileTranscript;
}

@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UILabel *transcriptLabel, *resultsLabel, *statusLabel;
@property (nonatomic, weak) KIOSRecognizer *recognizer;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;


@end

@implementation FileRecognitionDemoViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  filePath = @"audio-1.wav";
  fileTranscript = @"MONDAY TUESDAY FRIDAY SATURDAY SUNDAY";
  
  NSLog(@"Starting file ASR demo");
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
  

  // setup results label
  float w = CGRectGetWidth(self.view.frame) - 100;
  float h = 60;
  CGRect frame = CGRectMake((CGRectGetWidth(self.view.frame)-w)/2,
                            (CGRectGetHeight(self.view.frame)-h)/2 - h/2 - 10,
                            w, h);
  self.transcriptLabel = [[UILabel alloc] initWithFrame:frame];
  self.transcriptLabel.textAlignment = NSTextAlignmentLeft;
  self.transcriptLabel.font = [UIFont systemFontOfSize:30];
  self.transcriptLabel.numberOfLines = 0;
  [self.transcriptLabel setAdjustsFontSizeToFitWidth:YES];
  self.transcriptLabel.textColor = [UIColor grayColor];
  self.transcriptLabel.backgroundColor = [UIColor clearColor];
  [self.view addSubview:self.transcriptLabel];

  // setup results label
  w = CGRectGetWidth(self.view.frame) - 100;
  frame = CGRectMake((CGRectGetWidth(self.view.frame)-w)/2,
                            (CGRectGetHeight(self.view.frame)-h)/2 + h/2 + 10,
                            w, h);
  self.resultsLabel = [[UILabel alloc] initWithFrame:frame];
  self.resultsLabel.textAlignment = NSTextAlignmentLeft;
  self.resultsLabel.font = [UIFont systemFontOfSize:30];
  self.resultsLabel.numberOfLines = 0;
  [self.resultsLabel setAdjustsFontSizeToFitWidth:YES];
  self.resultsLabel.textColor = [UIColor blackColor];
  self.resultsLabel.backgroundColor = [UIColor clearColor];
  [self.view addSubview:self.resultsLabel];
  
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
  
  // spinner
  self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  float spWidth = 100, spHeight = 100;
  self.spinner.frame = CGRectMake(CGRectGetWidth(self.view.frame)/2 - spWidth/2,
                                  CGRectGetHeight(self.view.frame)/2 - spHeight/2,
                                  spWidth,
                                  spHeight);
  [self.view addSubview:self.spinner];
 // self.spinner.alpha = 0;

  // back button
  
  // keeping weak local reference just so we don't have to call shared instance
  // all the time
  self.recognizer = [KIOSRecognizer sharedInstance];
  // setup self to be the delegate for the recognizer so we get notifications
  // for partial/final results
  self.recognizer.delegate = self;
  [KIOSRecognizer setLogLevel:KIOSRecognizerLogLevelDebug];
  self.recognizer.createAudioRecordings=YES;
  // set Voice Activity Detection timeouts, so they the endpointing/VAD does not
  // get triggered
  
  // if user doesn't say anything for this many seconds we end recognition
  [self.recognizer setVADParameter:KIOSVadTimeoutForNoSpeech toValue:50];
  // we never run recognition longer than this many seconds
  [self.recognizer setVADParameter:KIOSVadTimeoutMaxDuration toValue:80];
  
  [self.recognizer setVADParameter:KIOSVadTimeoutEndSilenceForGoodMatch toValue:100];
  [self.recognizer setVADParameter:KIOSVadTimeoutEndSilenceForAnyMatch toValue:100];
}


- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  self.spinner.alpha = 1;
  [self.spinner startAnimating];
  
  self.transcriptLabel.text = [NSString stringWithFormat:@"REF: %@", fileTranscript];
  self.statusLabel.text = @"Creating graph and preparing to listen...";
}


- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

  NSString *fullPath = [[NSBundle mainBundle] pathForResource:filePath ofType:nil];
  if (! fullPath) {
    self.statusLabel.text = @"ERROR";
    self.transcriptLabel.text = [NSString stringWithFormat:@"Unable to open audio file %@", filePath];
    self.backButton.enabled = YES;
    return;
  }
  
  NSString *dgName = @"weekdays";
  NSArray *sentences = @[@"monday", @"tuesday", @"wednesday", @"thursday", @"friday", @"saturday", @"sunday"];
  if (! [KIOSDecodingGraph createDecodingGraphFromSentences:sentences
                                              forRecognizer:self.recognizer
                                            andSaveWithName:dgName]) {
    self.resultsLabel.text = @"Error occured while creating decoding graph from the text";
    [self.spinner stopAnimating];
    self.spinner.alpha = 0;
    return;
  }
  self.backButton.enabled = YES;

  NSLog(@"Preparing to listen with custom decoding graph '%@'", dgName);
  [self.recognizer prepareForListeningWithCustomDecodingGraphWithName:dgName];
  NSLog(@"Ready to start listening");

  [self.spinner stopAnimating];
  self.spinner.alpha = 0;

  self.statusLabel.text = @"Processing audio file...";
  if (! [self.recognizer startListeningFromAudioFile:fullPath]) {
    self.statusLabel.text = @"ERROR";
    self.transcriptLabel.text = [NSString stringWithFormat:@"Unable to open audio file %@", fullPath];
  }
}


#pragma mark KIOSRecognizer delegate methods

- (void)unwindAppAudioBeforeAudioInterrupt {
  NSLog(@"Unwinding app audio (nothing to do here since app doens't play audio");
}


- (void)recognizerPartialResult:(KIOSResult *)result forRecognizer:(KIOSRecognizer *)recognizer {
//  NSLog(@"Partial Result: %@ (%@)", result.cleanText, result.text);
  self.resultsLabel.textColor = [UIColor grayColor];
  self.resultsLabel.text = result.cleanText;
}


- (void)recognizerFinalResult:(KIOSResult *)result forRecognizer:(KIOSRecognizer *)recognizer {
  NSLog(@"Final Result: %@", result);
  self.resultsLabel.textColor = [UIColor blackColor];
  self.resultsLabel.text = [NSString stringWithFormat: @"REC: %@", result.cleanText];
  self.statusLabel.text = @"Done with processing audio file";
}





- (void)backButtonTapped:(id)sender {
  if (self.recognizer.recognizerState == KIOSRecognizerStateListening ||
      self.recognizer.recognizerState == KIOSRecognizerStateFinalProcessing)
    [self.recognizer stopListening];
  
  [self dismissViewControllerAnimated:YES completion:^{}];
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
