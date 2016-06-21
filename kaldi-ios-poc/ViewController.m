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


typedef NS_ENUM(NSInteger, DemoType) {
  kDemoTypeMusicLibrary,
  kDemoTypeContacts,
  kDemoTypeEduReading
};


const static NSArray *demoIntroText;


@interface ViewController ()

@property (nonatomic, strong) UILabel *mainLabel, *instructionsLabel;
@property (nonatomic, weak) KIOSRecognizer *recognizer;
@property (nonatomic, strong) UIButton *startButton, *chooseDemoButton;
@property (nonatomic, strong) UIView *chooseDemoView;
@property (nonatomic, strong) UIButton *musicDemoButton, *contactsDemoButton, *eduReadingDemoButton;
@property (nonatomic, assign) CGRect openMenuFrame, closedMenuFrame;
@property (nonatomic, assign) NSInteger currentDemo;

@end



@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  NSString *intro = @"All the demos are utilizing basic functionality of the Kaldi-iOS framework; many paramenters can be tuned to further optimize recognition performance.\n\nThe app will show the words it's recognizing in real-time in gray text. Once it detects 2sec of silence, the app stops listening and displays the final hypothesis in black text.\n\nNow, choose demo via Choose Demo button.";
  
  demoIntroText = @[@"This demo showcases access to your music library via voice. You can say \"PLAY <SONGNAME>\" or \"PLAY <ARTIST_NAME>\" or \"PLAY <SONGNAME_NAME> BY <ARTIST_NAME>\"",
                    @"This demo showcases access to your contacts via voice. You can say \"CALL <NAME>\" or just \"<NAME>\" for any of your contacts.\n\nNote that foreign and non-common American names are assigned pronunciation algorithmically; the real-world app would aim to assign proper pronunciations to as many names as possible beforehand.",
                    @"In a reading demo you will see a paragraph of text. As you read the text aloud, the app will highlight the words you say. Real-world app can track timings (delays, hesitations, pauses), false starts, skips, etc. for specific words, and also provide hints when the child is struggling with a word."];
  // Choose button in the top right corner, reveals Music Library, Contacts,
  // Edu-Reading, Smart Home
  
  // preview view, shows intro about the demo and creates decoding graph (if needed)
  // shows number of entries (e.g. 850 songs)
  
  // edu-reading starts another view controller
  
  
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
  [KIOSRecognizer setLogLevel:KIOSRecognizerLogLevelInfo];

  // Init can occur here on in the AppDelegate
  if (! [KIOSRecognizer sharedInstance]) {
    // since we are using custom decoding graphs, we init without passing decoding
    // graph path, and later on we pass the custom decoding graph name to
    // startListeningWithCustomDecodingGraph
//    [KIOSRecognizer initWithRecognizerType:KIOSRecognizerTypeGMM andASRBundle:@"librispeech-gmm-en-us"];
    [KIOSRecognizer initWithRecognizerType:KIOSRecognizerTypeNNet andASRBundle:@"librispeech-nnet2-en-us"];

    [KIOSRecognizer sharedInstance].createAudioRecordings = FALSE;
  }
  self.recognizer = [KIOSRecognizer sharedInstance];
  // we are NOT setting this controller as a delegate, since individual demo
  // controllers handle callbacks and display results
  //  self.recognizer.delegate = self;
  
  // set to yes, if you'd like to capture audio recordings (see docs for details)
  self.recognizer.createAudioRecordings = NO;

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
                                 cbFrame.size.width,
                                 4*cbFrame.size.height);


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

  
  self.chooseDemoView.frame = self.closedMenuFrame;
}


#pragma mark Helper methods for language models for different demos







- (NSArray *)createStorySentences {
  NSMutableArray *sentences = [NSMutableArray new];
  
  [sentences addObjectsFromArray:@[@"Once upon a time there were three little pigs.",
                                   @"Once upon a time there were three little pigs.",
                                   @"Once upon a time there were three little pigs.",
                                   @"Once upon a time there were three little pigs.",
                                   @"Once upon a time there were three little pigs.",
                                   @"Once upon a time there were three little pigs.",
                                   @"Once upon a time there were three little pigs.",
                                   @"Once upon a time there were three little pigs.",
                                   @"Once upon a time there were three little pigs.",
                                   @"Once upon a time there were three little pigs.",
                                   @"Once upon a time there were three little pigs.",
                                   @"Once upon a time there were three little pigs.",
                                   @"Once upon a time there were three little pigs.",
                                   @"Once upon a time there were three little pigs.",
                                   @"Once upon a time there were three little pigs.",
                                   @"Once upon a time there were three little pigs.",
                                   @"Once upon a time there were three little pigs.",
                                   @"One pig built a house of straw while the second pig built his house with sticks.",
                                   @"One pig built a house of straw while the second pig built his house with sticks.",
                                   @"One pig built a house of straw while the second pig built his house with sticks.",
                                   @"One pig built a house of straw while the second pig built his house with sticks.",
                                   @"One pig built a house of straw while the second pig built his house with sticks.",
                                   @"One pig built a house of straw while the second pig built his house with sticks.",
                                   @"One pig built a house of straw while the second pig built his house with sticks.",
                                   @"One pig built a house of straw while the second pig built his house with sticks.",
                                   @"One pig built a house of straw while the second pig built his house with sticks.",
                                   @"One pig built a house of straw while the second pig built his house with sticks.",
                                   @"One pig built a house of straw while the second pig built his house with sticks.",
                                   @"One pig built a house of straw while the second pig built his house with sticks.",
                                   @"One pig built a house of straw while the second pig built his house with sticks.",
                                   @"One pig built a house of straw while the second pig built his house with sticks.",
                                   @"One pig built a house of straw while the second pig built his house with sticks.",
                                   @"One pig built a house of straw while the second pig built his house with sticks.",
                                   @"They built their houses very quickly and then sang and danced all day because they were lazy.",
                                   @"They built their houses very quickly and then sang and danced all day because they were lazy.",
                                   @"They built their houses very quickly and then sang and danced all day because they were lazy.",
                                   @"They built their houses very quickly and then sang and danced all day because they were lazy.",
                                   @"They built their houses very quickly and then sang and danced all day because they were lazy.",
                                   @"They built their houses very quickly and then sang and danced all day because they were lazy.",
                                   @"They built their houses very quickly and then sang and danced all day because they were lazy.",
                                   @"They built their houses very quickly and then sang and danced all day because they were lazy.",
                                   @"They built their houses very quickly and then sang and danced all day because they were lazy.",
                                   @"They built their houses very quickly and then sang and danced all day because they were lazy.",
                                   @"They built their houses very quickly and then sang and danced all day because they were lazy.",
                                   @"They built their houses very quickly and then sang and danced all day because they were lazy.",
                                   @"They built their houses very quickly and then sang and danced all day because they were lazy.",
                                   @"They built their houses very quickly and then sang and danced all day because they were lazy.",
                                   @"They built their houses very quickly and then sang and danced all day because they were lazy.",
                                   @"They built their houses very quickly and then sang and danced all day because they were lazy.",
                                   @"The third little pig worked hard all day and built his house with bricks.",
                                   @"The third little pig worked hard all day and built his house with bricks.",
                                   @"The third little pig worked hard all day and built his house with bricks.",
                                   @"The third little pig worked hard all day and built his house with bricks.",
                                   @"The third little pig worked hard all day and built his house with bricks.",
                                   @"The third little pig worked hard all day and built his house with bricks.",
                                   @"The third little pig worked hard all day and built his house with bricks.",
                                   @"The third little pig worked hard all day and built his house with bricks.",
                                   @"The third little pig worked hard all day and built his house with bricks.",
                                   @"The third little pig worked hard all day and built his house with bricks.",
                                   @"The third little pig worked hard all day and built his house with bricks.",
                                   @"The third little pig worked hard all day and built his house with bricks.",
                                   @"The third little pig worked hard all day and built his house with bricks.",
                                   @"The third little pig worked hard all day and built his house with bricks.",
                                   @"The third little pig worked hard all day and built his house with bricks.",
                                   @"A big bad wolf saw the two little pigs while they danced and played and thought, What juicy tender meals they will make!",
                                   @"A big bad wolf saw the two little pigs while they danced and played and thought, What juicy tender meals they will make!",
                                   @"A big bad wolf saw the two little pigs while they danced and played and thought, What juicy tender meals they will make!",
                                   @"A big bad wolf saw the two little pigs while they danced and played and thought, What juicy tender meals they will make!",
                                   @"A big bad wolf saw the two little pigs while they danced and played and thought, What juicy tender meals they will make!",
                                   @"A big bad wolf saw the two little pigs while they danced and played and thought, What juicy tender meals they will make!",
                                   @"A big bad wolf saw the two little pigs while they danced and played and thought, What juicy tender meals they will make!",
                                   @"A big bad wolf saw the two little pigs while they danced and played and thought, What juicy tender meals they will make!",
                                   @"A big bad wolf saw the two little pigs while they danced and played and thought, What juicy tender meals they will make!",
                                   @"A big bad wolf saw the two little pigs while they danced and played and thought, What juicy tender meals they will make!",
                                   @"A big bad wolf saw the two little pigs while they danced and played and thought, What juicy tender meals they will make!",
                                   @"A big bad wolf saw the two little pigs while they danced and played and thought, What juicy tender meals they will make!",
                                   @"A big bad wolf saw the two little pigs while they danced and played and thought, What juicy tender meals they will make!",
                                   @"A big bad wolf saw the two little pigs while they danced and played and thought, What juicy tender meals they will make!",
                                   @"A big bad wolf saw the two little pigs while they danced and played and thought, What juicy tender meals they will make!",
                                   @"A big bad wolf saw the two little pigs while they danced and played and thought, What juicy tender meals they will make!",
                                   @"He chased the two pigs and they ran and hid in their houses.",
                                   @"He chased the two pigs and they ran and hid in their houses.",
                                   @"He chased the two pigs and they ran and hid in their houses.",
                                   @"He chased the two pigs and they ran and hid in their houses.",
                                   @"He chased the two pigs and they ran and hid in their houses.",
                                   @"He chased the two pigs and they ran and hid in their houses.",
                                   @"He chased the two pigs and they ran and hid in their houses.",
                                   @"He chased the two pigs and they ran and hid in their houses.",
                                   @"He chased the two pigs and they ran and hid in their houses.",
                                   @"He chased the two pigs and they ran and hid in their houses.",
                                   @"He chased the two pigs and they ran and hid in their houses.",
                                   @"He chased the two pigs and they ran and hid in their houses.",
                                   @"He chased the two pigs and they ran and hid in their houses.",
                                   @"He chased the two pigs and they ran and hid in their houses.",
                                   @"He chased the two pigs and they ran and hid in their houses.",
                                   @"He chased the two pigs and they ran and hid in their houses.",
                                   @"The big bad wolf went to the first house and huffed and puffed and blew the house down in minutes.",
                                   @"The big bad wolf went to the first house and huffed and puffed and blew the house down in minutes.",
                                   @"The big bad wolf went to the first house and huffed and puffed and blew the house down in minutes.",
                                   @"The big bad wolf went to the first house and huffed and puffed and blew the house down in minutes.",
                                   @"The big bad wolf went to the first house and huffed and puffed and blew the house down in minutes.",
                                   @"The big bad wolf went to the first house and huffed and puffed and blew the house down in minutes.",
                                   @"The big bad wolf went to the first house and huffed and puffed and blew the house down in minutes.",
                                   @"The big bad wolf went to the first house and huffed and puffed and blew the house down in minutes.",
                                   @"The big bad wolf went to the first house and huffed and puffed and blew the house down in minutes.",
                                   @"The big bad wolf went to the first house and huffed and puffed and blew the house down in minutes.",
                                   @"The big bad wolf went to the first house and huffed and puffed and blew the house down in minutes.",
                                   @"The big bad wolf went to the first house and huffed and puffed and blew the house down in minutes.",
                                   @"The big bad wolf went to the first house and huffed and puffed and blew the house down in minutes.",
                                   @"The big bad wolf went to the first house and huffed and puffed and blew the house down in minutes.",
                                   @"The big bad wolf went to the first house and huffed and puffed and blew the house down in minutes.",
                                   @"The big bad wolf went to the first house and huffed and puffed and blew the house down in minutes.",
                                   @"The frightened little pig ran to the second pig’s house that was made of sticks.,",
                                   @"The frightened little pig ran to the second pig’s house that was made of sticks.,",
                                   @"The frightened little pig ran to the second pig’s house that was made of sticks.,",
                                   @"The frightened little pig ran to the second pig’s house that was made of sticks.,",
                                   @"The frightened little pig ran to the second pig’s house that was made of sticks.,",
                                   @"The frightened little pig ran to the second pig’s house that was made of sticks.,",
                                   @"The frightened little pig ran to the second pig’s house that was made of sticks.,",
                                   @"The frightened little pig ran to the second pig’s house that was made of sticks.,",
                                   @"The frightened little pig ran to the second pig’s house that was made of sticks.,",
                                   @"The frightened little pig ran to the second pig’s house that was made of sticks.,",
                                   @"The frightened little pig ran to the second pig’s house that was made of sticks.,",
                                   @"The frightened little pig ran to the second pig’s house that was made of sticks.,",
                                   @"The frightened little pig ran to the second pig’s house that was made of sticks.,",
                                   @"The frightened little pig ran to the second pig’s house that was made of sticks.,",
                                   @"The frightened little pig ran to the second pig’s house that was made of sticks.,"
                                   ]];
  
  return sentences;
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskLandscape;
}



- (BOOL) shouldAutorotate  {
  return YES;
}


@end
