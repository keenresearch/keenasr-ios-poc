//
//  ViewController.m
//  kaldi-ios-poc
//
//  Created by Ognjen Todic on 11/14/14.
//  Copyright (c) 2014 Keen Research. All rights reserved.
//

#import "ViewController.h"

#import "KaldiIOS/KaldiIOS.h"

#import "MusicDemoViewController.h"
#import "ContactsDemoViewController.h"
#import "EduReadingDemoViewController.h"
#import "EduWordsDemoViewController.h"
#import "CommandAndControlViewController.h"
#import "FileRecognitionDemoViewController.h"

typedef NS_ENUM(NSInteger, DemoType) {
  kDemoTypeMusicLibrary,
  kDemoTypeContacts,
  kDemoTypeEduReading,
  kDemoTypeEduWords,
  kDemoTypeCommandAndControl,
  kDemoTypeFileRecognition,
};


const static NSArray *demoIntroText;


@interface ViewController ()

@property (nonatomic, strong) UILabel *mainLabel, *instructionsLabel;
@property (nonatomic, weak) KIOSRecognizer *recognizer;
@property (nonatomic, strong) UIButton *startButton, *chooseDemoButton;
@property (nonatomic, strong) UIView *chooseDemoView;

@property (nonatomic, strong) UIButton *musicDemoButton, *contactsDemoButton, \
*eduReadingDemoButton, *eduWordsDemoButton, *commandAndControlDemoButton, *fileRecognitionDemoButton;

@property (nonatomic, assign) CGRect openMenuFrame, closedMenuFrame;
@property (nonatomic, assign) NSInteger currentDemo;

@end



@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  NSString *intro = @"All the demos are utilizing basic functionality of the Kaldi-iOS framework; many paramenters can be tuned to further optimize recognition performance.\n\nThe app will show the words it's recognizing in real-time in gray text. Once it detects 2sec of silence, the app stops listening and displays the final hypothesis in black text.\n\nNow, choose demo via Choose Demo button.";
  
  demoIntroText = @[@"This demo showcases access to your music library via voice. You can say \"PLAY <SONGNAME>\" or \"PLAY <ARTIST_NAME>\" or \"PLAY <SONGNAME_NAME> BY <ARTIST_NAME>\"",
                    @"This demo showcases access to your contacts via voice. You can say \"CALL <NAME>\" or just \"<NAME>\" for any of your contacts.\n\nNote that foreign and non-common American names are assigned pronunciation algorithmically; the real-world app would aim to assign proper pronunciations to as many names as possible beforehand.",
                    @"In the reading demo you will see a paragraph of text. As you read the text aloud, the app will highlight the words you say. Real-world app can track timings (delays, hesitations, pauses), false starts, skips, etc. for specific words, and also provide hints when the child is struggling with a word.",
                    @"The words demo shows how to do recognition of individual words, with the goal of helping young children learn how to spell words. Child can say the word and then see how it's spelled",
                    @"Command and controls demo shows how to do recognition of individual words or short phrases for command and control (e.g. robots)",
                    @"The File ASR demo shows how to do recognition from a file. Decoding graph is built to listen to any day of the week and the audio recording has several days said."];
  // Choose button in the top right corner, reveals Music Library, Contacts,
  // Edu-Reading, File ASR
  
  // mainLabel is used to show the app intro message as well as the overview of
  // different demos
  // swapping width and height since app only supports landscape orientation
  float h = CGRectGetHeight(self.view.frame) - 120;
  float w = CGRectGetWidth(self.view.frame) - 40;
  CGRect frame = CGRectMake((CGRectGetWidth(self.view.frame)-w)/2,
                            (CGRectGetHeight(self.view.frame)-h)/2,
                            w, h);
  self.mainLabel = [[UILabel alloc] initWithFrame:frame];
//  self.mainLabel.textAlignment = NSTextAlignmentCenter;
  self.mainLabel.textAlignment = NSTextAlignmentLeft;
  self.mainLabel.font = [UIFont systemFontOfSize:30];
  self.mainLabel.numberOfLines = 0;
  [self.mainLabel setAdjustsFontSizeToFitWidth:YES];
  self.mainLabel.textColor = [UIColor blackColor];
  self.mainLabel.backgroundColor = [UIColor clearColor];
  [self.view addSubview:self.mainLabel];
  self.mainLabel.text = intro;
  
  
  self.startButton = [UIButton buttonWithType:UIButtonTypeSystem];
  float width=220, height=40;
  self.startButton.frame = CGRectMake((CGRectGetWidth(self.view.frame)-width)/2,
                                      CGRectGetHeight(self.view.frame)-height - 5,
                                      width,
                                      height);
  self.startButton.titleLabel.font = [UIFont systemFontOfSize:30];
  [self.view addSubview:self.startButton];
  self.startButton.backgroundColor = [UIColor clearColor];
  [self.startButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
  [self.startButton setTitle:@"Start Demo" forState:UIControlStateNormal];
  [self.startButton addTarget:self action:@selector(startDemo:) forControlEvents:UIControlEventTouchDown];
  
  float cdButtonWidth = 170;
  self.chooseDemoButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, cdButtonWidth, 30)];
  self.chooseDemoButton.titleLabel.font = [UIFont systemFontOfSize:20];
  self.chooseDemoButton.backgroundColor = [UIColor clearColor];
  [self.chooseDemoButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
  [self.chooseDemoButton setTitle:@"Choose Demo" forState:UIControlStateNormal];
  [self.view addSubview:self.chooseDemoButton];
  self.chooseDemoButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
  [self.chooseDemoButton addTarget:self action:@selector(chooseDemoButtonTapped:) forControlEvents:UIControlEventTouchDown];
  
  [self setupSelectionMenu];

  // Kaldi-iOS SETUP
  // we'll set the log level to info so we can see what's going on (default is WARN)
//  [KIOSRecognizer setLogLevel:KIOSRecognizerLogLevelInfo];
  [KIOSRecognizer setLogLevel:KIOSRecognizerLogLevelDebug];

  // Init can occur here on in the AppDelegate
  if (! [KIOSRecognizer sharedInstance]) {

//    [KIOSRecognizer initWithASRBundle:@"librispeech-gmm-en-us"];
    
    // nnet recognizers/acoustic models are more robust and provide better accuracy than GMM
    [KIOSRecognizer initWithASRBundle:@"librispeech-nnet2-en-us"];

  }
  self.recognizer = [KIOSRecognizer sharedInstance];
  // we are NOT setting this controller as a delegate, since individual demo
  // controllers handle callbacks and display results
  //  self.recognizer.delegate = self;
  
  // set to yes, if you'd like to capture audio recordings (see docs for details)
  self.recognizer.createAudioRecordings = NO;
  
  // Setting speaker name to some random value. If not set, adaptation will be
  // performed via 'default' name, so this makes sense only if you know you will
  // have different users and you can match users to their (pseudo)names.
  
  // In individual demo controllers we call SaveSpeakerAdaptationProfile on
  // viewWillDisappear to persist speakear adaptation profile on disk, so that
  // it can be used at from the beggining in subsequent sessions
  [self.recognizer adaptToSpeakerWithName:@"john"];
  // also see resetSpeakerAdaptation
  
  self.startButton.alpha = 0;
}


- (void)chooseDemoButtonTapped:(id)sender {
  // reveal the menu
  [UIView animateWithDuration:.25 animations:^ {
    self.chooseDemoView.frame = self.openMenuFrame;
  }];

}


- (void)selectedDemoButtonTapped:(id)sender {
  [UIView animateWithDuration:.4 animations:^ {
    self.chooseDemoView.frame = self.closedMenuFrame;
  }];
  
  [UIView animateWithDuration:.2 animations:^ {
    self.mainLabel.alpha = 0.4;
  } completion:^(BOOL finished) {
    if ((UIButton *)sender == self.musicDemoButton) {
      self.currentDemo = kDemoTypeMusicLibrary;
    } else if ((UIButton *)sender == self.contactsDemoButton) {
      self.currentDemo = kDemoTypeContacts;
    } else if ((UIButton *)sender == self.eduReadingDemoButton) {
      self.currentDemo = kDemoTypeEduReading;
    } else if ((UIButton *)sender == self.eduWordsDemoButton) {
      self.currentDemo = kDemoTypeEduWords;
    } else if ((UIButton *)sender == self.commandAndControlDemoButton) {
      self.currentDemo = kDemoTypeCommandAndControl;
    } else if ((UIButton *)sender == self.fileRecognitionDemoButton) {
      self.currentDemo = kDemoTypeFileRecognition;
    }

    self.mainLabel.text = demoIntroText[self.currentDemo];
    [UIView animateWithDuration:.3 animations:^ {
      self.mainLabel.alpha = 1;
      self.startButton.alpha = 1;
    }];
  }];
}

- (void)startDemo:(id)sender {
  UIViewController *vc;
  switch (self.currentDemo) {
    case kDemoTypeMusicLibrary:
      vc = [MusicDemoViewController new];
      break;
    case kDemoTypeContacts:
      vc = [ContactsDemoViewController new];
      break;
    case kDemoTypeEduReading:
      vc = [EduReadingDemoViewController new];
      break;
    case kDemoTypeEduWords:
      vc = [EduWordsDemoViewController new];
      break;
    case kDemoTypeCommandAndControl:
      vc = [CommandAndControlViewController new];
      break;
    case kDemoTypeFileRecognition:
      vc = [FileRecognitionDemoViewController new];
      break;
  }
  [self presentViewController:vc animated:YES completion:^ {}];
  
}


#pragma mark UI Setup
- (void)setupSelectionMenu {
  CGRect cbFrame = self.chooseDemoButton.frame;
  float offset = 0;
  self.closedMenuFrame = CGRectMake(cbFrame.origin.x+offset, cbFrame.origin.y+cbFrame.size.height+offset, 0, 0);
  self.openMenuFrame = CGRectMake(self.closedMenuFrame.origin.x,
                                 self.closedMenuFrame.origin.y,
                                 cbFrame.size.width + 20,
                                 (demoIntroText.count + 1)*cbFrame.size.height);


  self.chooseDemoView = [[UIView alloc] initWithFrame:self.openMenuFrame];
  self.chooseDemoView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:.95];
  [self.view addSubview:self.chooseDemoView];
  
  float x=15;
  self.musicDemoButton = [[UIButton alloc] initWithFrame:CGRectMake(x, 15, self.openMenuFrame.size.width-5, 20)];
  [self.musicDemoButton setTitle:@"Music Library" forState:UIControlStateNormal];
  self.musicDemoButton.titleLabel.font = [UIFont systemFontOfSize:18];
  [self.musicDemoButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
  self.musicDemoButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
  [self.musicDemoButton addTarget:self action:@selector(selectedDemoButtonTapped:) forControlEvents:UIControlEventTouchDown];
  self.musicDemoButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [self.chooseDemoView addSubview:self.musicDemoButton];

  self.contactsDemoButton = [[UIButton alloc] initWithFrame:CGRectMake(x, 50, self.openMenuFrame.size.width-5, 20)];
  [self.contactsDemoButton setTitle:@"Contacts" forState:UIControlStateNormal];
  self.contactsDemoButton.titleLabel.font = [UIFont systemFontOfSize:18];
  [self.contactsDemoButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
  self.contactsDemoButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
  [self.contactsDemoButton addTarget:self action:@selector(selectedDemoButtonTapped:) forControlEvents:UIControlEventTouchDown];
  self.contactsDemoButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [self.chooseDemoView addSubview:self.contactsDemoButton];

  self.eduReadingDemoButton = [[UIButton alloc] initWithFrame:CGRectMake(x, 85, self.openMenuFrame.size.width-5, 20)];
  [self.eduReadingDemoButton setTitle:@"Edu: Reading" forState:UIControlStateNormal];
  self.eduReadingDemoButton.titleLabel.font = [UIFont systemFontOfSize:18];
  [self.eduReadingDemoButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
  self.eduReadingDemoButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
  [self.eduReadingDemoButton addTarget:self action:@selector(selectedDemoButtonTapped:) forControlEvents:UIControlEventTouchDown];
  self.eduReadingDemoButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [self.chooseDemoView addSubview:self.eduReadingDemoButton];

  self.eduWordsDemoButton = [[UIButton alloc] initWithFrame:CGRectMake(x, 120, self.openMenuFrame.size.width-5, 20)];
  [self.eduWordsDemoButton setTitle:@"Edu: Words" forState:UIControlStateNormal];
  self.eduWordsDemoButton.titleLabel.font = [UIFont systemFontOfSize:18];
  [self.eduWordsDemoButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
  self.eduWordsDemoButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
  [self.eduWordsDemoButton addTarget:self action:@selector(selectedDemoButtonTapped:) forControlEvents:UIControlEventTouchDown];
  self.eduWordsDemoButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [self.chooseDemoView addSubview:self.eduWordsDemoButton];

  self.commandAndControlDemoButton = [[UIButton alloc] initWithFrame:CGRectMake(x, 155, self.openMenuFrame.size.width-5, 20)];
  [self.commandAndControlDemoButton setTitle:@"Command & Control" forState:UIControlStateNormal];
  self.commandAndControlDemoButton.titleLabel.font = [UIFont systemFontOfSize:18];
  [self.commandAndControlDemoButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
  self.commandAndControlDemoButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
  [self.commandAndControlDemoButton addTarget:self action:@selector(selectedDemoButtonTapped:) forControlEvents:UIControlEventTouchDown];
  self.commandAndControlDemoButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [self.chooseDemoView addSubview:self.commandAndControlDemoButton];

  self.fileRecognitionDemoButton = [[UIButton alloc] initWithFrame:CGRectMake(x, 190, self.openMenuFrame.size.width-5, 20)];
  [self.fileRecognitionDemoButton setTitle:@"File ASR" forState:UIControlStateNormal];
  self.fileRecognitionDemoButton.titleLabel.font = [UIFont systemFontOfSize:18];
  [self.fileRecognitionDemoButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
  self.fileRecognitionDemoButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
  [self.fileRecognitionDemoButton addTarget:self action:@selector(selectedDemoButtonTapped:) forControlEvents:UIControlEventTouchDown];
  self.fileRecognitionDemoButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [self.chooseDemoView addSubview:self.fileRecognitionDemoButton];

  
  self.chooseDemoView.frame = self.closedMenuFrame;
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskLandscape;
}



- (BOOL) shouldAutorotate  {
  return YES;
}


@end
