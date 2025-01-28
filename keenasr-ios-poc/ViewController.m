//
//  ViewController.m
//  kaldi-ios-poc
//
//  Created by Ognjen Todic on 11/14/14.
//  Copyright (c) 2014 Keen Research. All rights reserved.
//

#import "ViewController.h"

#import "KeenASR/KeenASR.h"

#import "EduReadingDemoViewController.h"
#import "EduWordsDemoViewController.h"
#import "CommandAndControlViewController.h"

typedef NS_ENUM(NSInteger, DemoType) {
  kDemoTypeEduReading,
  kDemoTypeEduWords,
  kDemoTypeCommandAndControl,
};


const static NSArray *demoIntroText;


@interface ViewController ()

@property (nonatomic, strong) UILabel *mainLabel, *instructionsLabel;
@property (nonatomic, weak) KIOSRecognizer *recognizer;
@property (nonatomic, strong) UIButton *startButton, *chooseDemoButton;
@property (nonatomic, strong) UIView *chooseDemoView;

@property (nonatomic, strong) UIButton *eduReadingDemoButton, *eduWordsDemoButton, *commandAndControlDemoButton;

@property (nonatomic, assign) CGRect openMenuFrame, closedMenuFrame;
@property (nonatomic, assign) NSInteger currentDemo;

@end



@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  NSString *intro = @"All the demos are utilizing basic functionality of the KeenASR framework; many paramenters can be tuned to further optimize recognition performance.\n\nThe app will show the words it's recognizing in real-time in gray text. Once it detects 2sec of silence, the app stops listening and displays the final hypothesis in black text.\n\nNow, choose demo via Choose Demo button.";
  
  demoIntroText = @[
    @"In the reading demo you will see a paragraph of text. As you read the text aloud, the app will highlight the words you say. Real-world app can track timings (delays, hesitations, pauses), false starts, skips, etc. for specific words, and also provide hints when the child is struggling with a word.",
    @"The words demo shows how to do recognition of individual words, with the goal of helping young children learn how to spell words. Child can say the word and then see how it's spelled",
    @"Command and controls demo shows how to do recognition of individual words or short phrases for command and control (e.g. robots)",
  ];
  // Choose button in the top right corner, reveals options
  
  // mainLabel is used to show the app intro message as well as the overview of
  // different demos
  // swapping width and height since app only supports landscape orientation
  float h = CGRectGetHeight(self.view.frame) - 120;
  float w = CGRectGetWidth(self.view.frame) - 80;
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
                                      CGRectGetHeight(self.view.frame)-height - 15,
                                      width,
                                      height);
  self.startButton.titleLabel.font = [UIFont systemFontOfSize:30];
  [self.view addSubview:self.startButton];
  self.startButton.backgroundColor = [UIColor clearColor];
  [self.startButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
  [self.startButton setTitle:@"Start Demo" forState:UIControlStateNormal];
  [self.startButton addTarget:self action:@selector(startDemo:) forControlEvents:UIControlEventTouchDown];
  
  float cdButtonWidth = 170;
  self.chooseDemoButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 10, cdButtonWidth, 30)];
  self.chooseDemoButton.titleLabel.font = [UIFont systemFontOfSize:20];
  self.chooseDemoButton.backgroundColor = [UIColor clearColor];
  [self.chooseDemoButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
  [self.chooseDemoButton setTitle:@"Choose Demo" forState:UIControlStateNormal];
  [self.view addSubview:self.chooseDemoButton];
  self.chooseDemoButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
  [self.chooseDemoButton addTarget:self action:@selector(chooseDemoButtonTapped:) forControlEvents:UIControlEventTouchDown];
  
  [self setupSelectionMenu];

  // Initialize the engine
  // we'll set the log level to info so we can see what's going on (default is WARN)
//  [KIOSRecognizer setLogLevel:KIOSRecognizerLogLevelInfo];
  [KIOSRecognizer setLogLevel:KIOSRecognizerLogLevelDebug];

  // Init can occur here or in the AppDelegate
  if (! [KIOSRecognizer sharedInstance]) {
    [KIOSRecognizer initWithASRBundle:@"keenA1m-nnet3chain-en-us"];
  }
  self.recognizer = [KIOSRecognizer sharedInstance];
  // we are NOT setting this controller as a delegate, since individual demo
  // controllers handle callbacks and display results
  //  self.recognizer.delegate = self;
   
  // if you are using Dashboard to push data for further debugging, you would
  // setup a data upload thread here. You would need Dashboard account and
  // an app key.
//  if (! [KIOSUploader createDataUploadThreadForRecognizer:self.recognizer
//                                              usingAppKey:@"YOUR_APP_KEY_FOR_DASHBOARD"]) {
//    NSLog(@"Failed to create KIOSUploader background thread");
//  }
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
    if ((UIButton *)sender == self.eduReadingDemoButton) {
      self.currentDemo = kDemoTypeEduReading;
    } else if ((UIButton *)sender == self.eduWordsDemoButton) {
      self.currentDemo = kDemoTypeEduWords;
    } else if ((UIButton *)sender == self.commandAndControlDemoButton) {
      self.currentDemo = kDemoTypeCommandAndControl;
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
    case kDemoTypeEduReading:
      vc = [EduReadingDemoViewController new];
      break;
    case kDemoTypeEduWords:
      vc = [EduWordsDemoViewController new];
      break;
    case kDemoTypeCommandAndControl:
      vc = [CommandAndControlViewController new];
      break;
  }
  [self presentViewController:vc animated:YES completion:^ {}];
  
}


#pragma mark UI Setup
- (void)setupSelectionMenu {
  CGRect cbFrame = self.chooseDemoButton.frame;
  float offset = 20;
  self.closedMenuFrame = CGRectMake(cbFrame.origin.x+offset, cbFrame.origin.y+cbFrame.size.height+offset, 0, 0);
  self.openMenuFrame = CGRectMake(self.closedMenuFrame.origin.x,
                                 self.closedMenuFrame.origin.y,
                                 cbFrame.size.width + 20,
                                 (demoIntroText.count + 1)*cbFrame.size.height);


  self.chooseDemoView = [[UIView alloc] initWithFrame:self.openMenuFrame];
  self.chooseDemoView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:.95];
  [self.view addSubview:self.chooseDemoView];
  
  float x=15;

  self.eduReadingDemoButton = [[UIButton alloc] initWithFrame:CGRectMake(x, 15, self.openMenuFrame.size.width-5, 20)];
  [self.eduReadingDemoButton setTitle:@"Edu: Reading" forState:UIControlStateNormal];
  self.eduReadingDemoButton.titleLabel.font = [UIFont systemFontOfSize:18];
  [self.eduReadingDemoButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
  self.eduReadingDemoButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
  [self.eduReadingDemoButton addTarget:self action:@selector(selectedDemoButtonTapped:) forControlEvents:UIControlEventTouchDown];
  self.eduReadingDemoButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [self.chooseDemoView addSubview:self.eduReadingDemoButton];

  self.eduWordsDemoButton = [[UIButton alloc] initWithFrame:CGRectMake(x, 50, self.openMenuFrame.size.width-5, 20)];
  [self.eduWordsDemoButton setTitle:@"Edu: Words" forState:UIControlStateNormal];
  self.eduWordsDemoButton.titleLabel.font = [UIFont systemFontOfSize:18];
  [self.eduWordsDemoButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
  self.eduWordsDemoButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
  [self.eduWordsDemoButton addTarget:self action:@selector(selectedDemoButtonTapped:) forControlEvents:UIControlEventTouchDown];
  self.eduWordsDemoButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [self.chooseDemoView addSubview:self.eduWordsDemoButton];

  self.commandAndControlDemoButton = [[UIButton alloc] initWithFrame:CGRectMake(x, 85, self.openMenuFrame.size.width-5, 20)];
  [self.commandAndControlDemoButton setTitle:@"Command & Control" forState:UIControlStateNormal];
  self.commandAndControlDemoButton.titleLabel.font = [UIFont systemFontOfSize:18];
  [self.commandAndControlDemoButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
  self.commandAndControlDemoButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
  [self.commandAndControlDemoButton addTarget:self action:@selector(selectedDemoButtonTapped:) forControlEvents:UIControlEventTouchDown];
  self.commandAndControlDemoButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [self.chooseDemoView addSubview:self.commandAndControlDemoButton];
 
  self.chooseDemoView.frame = self.closedMenuFrame;
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskLandscape;
}



- (BOOL) shouldAutorotate  {
  return YES;
}


@end
