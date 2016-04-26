//
//  ViewController.m
//  kaldi-ios-poc
//
//  Created by Ognjen Todic on 11/14/14.
//  Copyright (c) 2014 Keen Research. All rights reserved.
//

#import "ViewController.h"

#import "KaldiIOS/KaldiIOS.h"

@interface ViewController ()

@property (nonatomic, strong) UILabel *resultsLabel, *instructionsLabel;
@property(nonatomic, strong) KIOSRecognizer *recognizer;
@property(nonatomic, strong) UIButton *startButton;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.
  
  // put a UILabel in the middle of the screen,
  // recognition results will be shown there
  float h = 200;
  CGRect frame = CGRectMake(10,
                            (CGRectGetHeight(self.view.frame) - h)/2,
                            CGRectGetWidth(self.view.frame)-20,
                            200);
  self.resultsLabel = [[UILabel alloc] initWithFrame:frame];
  self.resultsLabel.textAlignment = NSTextAlignmentCenter;
  self.resultsLabel.font = [UIFont systemFontOfSize:30];
  self.resultsLabel.numberOfLines = 0;
  [self.resultsLabel setAdjustsFontSizeToFitWidth:YES];
  self.resultsLabel.textColor = [UIColor blackColor];
  self.resultsLabel.backgroundColor = [UIColor clearColor];
  [self.view addSubview:self.resultsLabel];
  
  self.startButton = [UIButton buttonWithType:UIButtonTypeSystem];
  float width=180, height=40;
  self.startButton.frame = CGRectMake((CGRectGetWidth(self.view.frame)-width)/2,
                                      CGRectGetHeight(self.view.frame)-height - 20,
                                      width,
                                      height);
  self.startButton.titleLabel.font = [UIFont systemFontOfSize:40];
  [self.view addSubview:self.startButton];
  self.startButton.backgroundColor = [UIColor clearColor];
  self.startButton.titleLabel.textColor = [UIColor redColor];
  [self.startButton setTitle:@"START" forState:UIControlStateNormal];
  [self.startButton addTarget:self action:@selector(startButtonTapped:) forControlEvents:UIControlEventTouchDown];
  
  self.instructionsLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, CGRectGetWidth(self.view.frame)-40, 100)];
  self.instructionsLabel.font = [UIFont systemFontOfSize:30];
  self.instructionsLabel.numberOfLines = 0;
  [self.instructionsLabel setAdjustsFontSizeToFitWidth:YES];
  self.instructionsLabel.textColor = [UIColor blackColor];
  self.instructionsLabel.backgroundColor = [UIColor clearColor];
  self.instructionsLabel.text = @"Tap START and say one or more digits in 1 - 100 range. ";
  [self.view addSubview:self.instructionsLabel];

  if (! [KIOSRecognizer sharedInstance]) {
//    [KIOSRecognizer initWithRecognizerType:KIOSRecognizerTypeNNet andASRBundle:@"librispeech-nnet2" andDecodingGraph:@"HCLG.fst"];
    [KIOSRecognizer initWithRecognizerType:KIOSRecognizerTypeGMM andASRBundle:@"librispeech-gmm" andDecodingGraph:@"HCLG.fst"];
    [KIOSRecognizer sharedInstance].createAudioRecordings = FALSE;
  }
  self.recognizer = [KIOSRecognizer sharedInstance];
  self.recognizer.delegate = self;
  self.recognizer.createAudioRecordings = YES;
}


- (void)startButtonTapped:(id)sender {
  self.startButton.enabled = NO;
  self.resultsLabel.text = @"";
  // since we are using only a single decoding graph here, we can just call startListening
//  [self.recognizer startListening];
  // if we were dynamically switching decodingGraphs, we would startListeningWithDecodingGraph
  // passing paths to different graphs
//  [self.recognizer startListeningWithDecodingGraph:@"librispeech-nnet2/HCLG.fst"];
  [self.recognizer startListeningWithDecodingGraph:@"librispeech-gmm/HCLG.fst"];
}


#pragma mark KIOSRecognizer delegate methods

- (void)recognizerPartialResult:(KIOSRecognizer *)recognizer result:(KIOSResult *)result {
  NSLog(@"Partial Result: %@ (%@)", result.cleanText, result.text);
  self.resultsLabel.textColor = [UIColor grayColor];
  self.resultsLabel.text = result.cleanText;
}

- (void)recognizerFinalResult:(KIOSRecognizer *)recognizer result:(KIOSResult *)result {
  NSLog(@"Final Result: %@ (%@, conf: %@)", result.cleanText, result.text, result.confidence);
  NSLog(@"Audio recording is in %@", recognizer.lastRecordingFilename);
  self.resultsLabel.textColor = [UIColor blackColor];
  self.resultsLabel.text = result.cleanText;
  // stop recognition
  [self.recognizer stopListening];
  self.startButton.enabled = YES;
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait;
}

- (BOOL) shouldAutorotate  {
  return NO;
}


@end
