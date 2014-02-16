//
//  ViewController.m
//  ChromCastTest
//
//  Created by Sandeep on 09/02/14.
//  Copyright (c) 2014 Sandeep. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <GoogleCast/GoogleCast.h>

@interface ViewController ()<GCKDeviceScannerListener, GCKDeviceManagerDelegate, GCKMediaControlChannelDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableArray *foundDevices;
@property (nonatomic, strong) 	GCKDeviceScanner *scanner;
@property (nonatomic, strong) GCKDeviceManager *deviceManager;
@property (nonatomic, strong) GCKDevice *currentDevice;
@property (nonatomic, strong) GCKMediaControlChannel *mediaControlChannel;

@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, assign) BOOL playing;
@property (nonatomic, assign) float restoreAfterScrubbingRate;


@end

@implementation ViewController{
  id timeObserver;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
  self.foundDevices = [NSMutableArray array];
  	[self performScan];
  
  [self loadAssets];
}

NSString *const PlayerItemStatusContext = @"PlayerItemStatusContext";


- (void)avPlayerItemDidPlayToEndTimeNotification:(NSNotification*)notification{
  [self.playButton setTitle:@"Player" forState:UIControlStateNormal];
  self.playing = NO;
}

- (void)loadAssets{
  self.playButton.enabled = NO;
  
  AVAsset *asset = [AVAsset assetWithURL:[NSURL URLWithString:@"http://media.railscasts.com/assets/episodes/videos/415-upgrading-to-rails-4.mp4"]];
  [asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
    
    dispatch_async(dispatch_get_main_queue(), ^{
      NSError *error = nil;
      AVKeyValueStatus status = [asset statusOfValueForKey:@"tracks" error:&error];
    	if(status == AVKeyValueStatusLoaded){
        self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(avPlayerItemDidPlayToEndTimeNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];

        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
        [self.playerView setPlayer:self.player];
        [self.playerItem addObserver:self forKeyPath:@"status" options:0 context:(__bridge void *)(PlayerItemStatusContext)];
      }
    	});
    }];
}

- (void)watchSlider{
  __weak UISlider *slider = self.scrubber;
  __weak ViewController *controller = self;
  timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.1f, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
    
    NSLog(@"%f %f", CMTimeGetSeconds(time), CMTimeGetSeconds([controller.playerItem duration]));
    float value = CMTimeGetSeconds(time) / CMTimeGetSeconds([controller.playerItem duration]);
    
    [slider setValue:value];
  }];
}

- (IBAction)userStartedScrubbing:(id)sender{
  self.restoreAfterScrubbingRate  = [self.player rate];
  [self.player removeTimeObserver:timeObserver];
}

- (IBAction)userStoppedScrubbing:(id)sender{
  [self watchSlider];
  if(self.restoreAfterScrubbingRate){
    [self.player setRate:self.restoreAfterScrubbingRate];
    self.restoreAfterScrubbingRate = 0.0f;
  }
}

- (IBAction)scrub:(UISlider*)slider{
  float value = slider.value;
  float minValue = slider.minimumValue;
  float maxValue = slider.maximumValue;
  Float64 duration =  CMTimeGetSeconds([self.playerItem duration]);
  
  float nextTimeToSeekTo = duration * (value - minValue) / (maxValue - minValue);
  [self.player seekToTime:CMTimeMakeWithSeconds(nextTimeToSeekTo, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
    
  }];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
  if([keyPath  isEqualToString:@"status"] && context == (__bridge void*)PlayerItemStatusContext){
    dispatch_async(dispatch_get_main_queue(), ^{
      if(self.playerItem.status == AVPlayerItemStatusReadyToPlay){
       	self.playButton.enabled = YES;
        [self watchSlider];

      }
    });
    
  }else
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (IBAction)playPauseButtonTapped:(id)sender{
  if(!self.playing){
    [self.player play];
    [self.playButton  setTitle:@"Pause" forState:UIControlStateNormal];
  }
  else{
    [self.player pause];
   	[self.playButton setTitle:@"Play" forState:UIControlStateNormal];
  }
  self.playing = !self.playing;
}

- (void)isScanning:(NSTimer*)timer{
  NSLog(@"%@", [self.scanner scanning] ? @"Scanning" : @"Not scanning");
}

- (void)performScan{
  self.scanner = [[GCKDeviceScanner alloc] init];
  [self.scanner addListener:self];
  [self.scanner startScan];
  
}


/**
 * Called when a device has been discovered or has come online.
 *
 * @param device The device.
 */
- (void)deviceDidComeOnline:(GCKDevice *)device{
  
	  [self.tableView reloadData];
//  self.currentDevice = device;
//  NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
//  NSString *bundleIdentifier = infoDict[@"CFBundleIdentifier"];
//  self.deviceManager = [[GCKDeviceManager alloc] initWithDevice:self.currentDevice clientPackageName:bundleIdentifier];
//  [self.deviceManager setDelegate:self];
//  [self.deviceManager connect];
  

}
/**
 * Called when a device has gone offline.
 *
 * @param device The device.
 */
- (void)deviceDidGoOffline:(GCKDevice *)device{
  
}

 NSString *const kReceiverAppId = @"A5E19CD9";

- (void)deviceManagerDidConnect:(GCKDeviceManager *)deviceManager{
	[deviceManager launchApplication:kReceiverAppId];
  [deviceManager setDelegate:self];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
didFailToConnectWithError:(NSError *)error{
  NSLog(@"%@ %@", NSStringFromSelector(_cmd), error);
}


/**
 * Called when the connection to the device has been terminated.
 *
 * @param deviceManager The device manager.
 * @param error The error that caused the disconnection; nil if there was no error (e.g. intentional
 * disconnection).
 */
- (void)deviceManager:(GCKDeviceManager *)deviceManager
didDisconnectWithError:(NSError *)error{
  NSLog(@"%@ %@", NSStringFromSelector(_cmd), error);
  
}

#pragma mark Application connection callbacks

/**
 * Called when an application has been launched or joined.
 *
 * @param applicationMetadata Metadata about the application.
 * @param sessionID The session ID.
 * @param launchedApplication YES if the application was launched as part of the connection, or NO
 * if the application was already running and was joined.
 */
- (void)deviceManager:(GCKDeviceManager *)deviceManager
didConnectToCastApplication:(GCKApplicationMetadata *)applicationMetadata
            sessionID:(NSString *)sessionID
  launchedApplication:(BOOL)launchedApplication{
  
  
  
  
  NSURL *url = [NSURL URLWithString:@"http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"];
  GCKMediaMetadata *metadata = [[GCKMediaMetadata alloc] init];
  
  NSString *const title = @"Some random title";
  [metadata setString:title forKey:kGCKMetadataKeyTitle];
  
  
  NSString *const subtitle = @"Subtitle";
  
  
	[metadata setString:subtitle forKey:kGCKMetadataKeySubtitle];
  
  [metadata addImage:[[GCKImage alloc] initWithURL:[NSURL URLWithString:@"http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg"] width:200 height:100]];
  
  
  GCKMediaInformation *mediaInformation =
  [[GCKMediaInformation alloc] initWithContentID:[url absoluteString]
                                      streamType:GCKMediaStreamTypeNone
                                     contentType:@"video/mp4"
                                        metadata:metadata
                                  streamDuration:0
                                      customData:nil];
  
  
  self.mediaControlChannel = [[GCKMediaControlChannel alloc] init];
  self.mediaControlChannel.delegate = self;
  [self.deviceManager addChannel:self.mediaControlChannel];
  [self.mediaControlChannel requestStatus];
  
  [self.mediaControlChannel loadMedia:mediaInformation autoplay:YES playPosition:0];

  NSLog(@"connected %@ %@ %@ %@", deviceManager, applicationMetadata, sessionID, launchedApplication ? @"Launched" : @"Not Launched");
}

/**
 * Called when connecting to an application fails.
 *
 * @param deviceManager The device manager.
 * @param error The error that caused the failure.
 */
- (void)deviceManager:(GCKDeviceManager *)deviceManager
didFailToConnectToApplicationWithError:(NSError *)error{
  NSLog(@"deviceManagerFailedToConnectToApplication: %@",[GCKError enumDescriptionForCode:[error code]]);
}

/**
 * Called when disconnected from the current application.
 */
- (void)deviceManager:(GCKDeviceManager *)deviceManager
didDisconnectFromApplicationWithError:(NSError *)error{
  NSLog(@"didDisconnectFromApplicationWithError %@", error);
}

/**
 * Called when a stop application request fails.
 *
 * @param deviceManager The device manager.
 * @param error The error that caused the failure.
 */
- (void)deviceManager:(GCKDeviceManager *)deviceManager
didFailToStopApplicationWithError:(NSError *)error{
  
}

#pragma mark Device status callbacks

/**
 * Called whenever updated status information is received.
 *
 * @param applicationMetadata The application metadata.
 */
- (void)deviceManager:(GCKDeviceManager *)deviceManager
didReceiveStatusForApplication:(GCKApplicationMetadata *)applicationMetadata{
  NSLog(@"status %@", applicationMetadata);
}

/**
 * Called whenever the volume changes.
 *
 * @param volumeLevel The current device volume level.
 * @param isMuted The current device mute state.
 */
- (void)deviceManager:(GCKDeviceManager *)deviceManager
volumeDidChangeToLevel:(float)volumeLevel
              isMuted:(BOOL)isMuted{
  
}


- (void)mediaControlChannel:(GCKMediaControlChannel *)mediaControlChannel
didCompleteLoadWithSessionID:(NSInteger)sessionID{
  NSLog(@"%@ %d", NSStringFromSelector(_cmd), sessionID);
}

/**
 * Called when a request to load media has failed.
 */
- (void)mediaControlChannel:(GCKMediaControlChannel *)mediaControlChannel
didFailToLoadMediaWithError:(NSError *)error{
  NSLog(@"%@ %@", NSStringFromSelector(_cmd), error);
}

/**
 * Called when updated player status information is received.
 */
- (void)mediaControlChannelDidUpdateStatus:(GCKMediaControlChannel *)mediaControlChannel{
  NSLog(@"%@ %@", NSStringFromSelector(_cmd), mediaControlChannel);
}

/**
 * Called when updated media metadata is received.
 */
- (void)mediaControlChannelDidUpdateMetadata:(GCKMediaControlChannel *)mediaControlChannel{
  NSLog(@"%@ %@", NSStringFromSelector(_cmd), mediaControlChannel);
}

/**
 * Called when a request fails.
 *
 * @param requestID The request ID that failed. This is the ID returned when the request was made.
 * @param error The error. If any custom data was associated with the error, it will be in the
 * error's userInfo dictionary with the key {@code kGCKErrorCustomDataKey}.
 */
- (void)mediaControlChannel:(GCKMediaControlChannel *)mediaControlChannel
       requestDidFailWithID:(NSInteger)requestID
                      error:(NSError *)error{
  NSLog(@"%@ %d %@", NSStringFromSelector(_cmd), requestID, error);
}


#pragma mark - UITableViewDelegate 


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
  return [[self.scanner devices] count];
}


- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
  NSString *const cellIdentifier = @"ChromeCastDeviceCell";
  UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  GCKDevice *device = [[self.scanner devices] objectAtIndex:indexPath.row];
  UILabel *label = (UILabel*)[cell viewWithTag:1000];
  label.text = [device friendlyName];
  return cell;
  
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
  GCKDevice *device = [[self.scanner devices] objectAtIndex:indexPath.row];
  
  NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
  NSString *bundleIdentifier = infoDict[@"CFBundleIdentifier"];
  self.deviceManager = [[GCKDeviceManager alloc] initWithDevice:device clientPackageName:bundleIdentifier];
  [self.deviceManager setDelegate:self];
  [self.deviceManager connect];
  
  //  NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
  //  NSString *bundleIdentifier = infoDict[@"CFBundleIdentifier"];
  //  self.deviceManager = [[GCKDeviceManager alloc] initWithDevice:self.currentDevice clientPackageName:bundleIdentifier];
  //  [self.deviceManager setDelegate:self];
  //  [self.deviceManager connect];
}



@end
