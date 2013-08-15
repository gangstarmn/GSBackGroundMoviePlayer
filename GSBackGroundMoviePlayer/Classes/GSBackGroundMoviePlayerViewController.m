//
//  GSBackGroundMoviePlayerViewController.m
//  DJTube
//
//  Created by Gantulga Tsendsuren on 8/1/13.
//  Copyright (c) 2013 Sorako. All rights reserved.
//

#import "GSBackGroundMoviePlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <objc/message.h>
@interface GSBackGroundMoviePlayerViewController () <UIGestureRecognizerDelegate>{
    UISlider *seeker;
    UILabel *currentTimeLabel;
    UILabel *totalTimeLabel;
    UIView *headerView;
    UILabel *headerLabel;
    UIView *normalView;
    UIView *loadingView;
    
    UIView *footerView;
    UIButton *playButton;
    UITapGestureRecognizer *tapGesture;
    NSTimer *timer;

}
@property (nonatomic, strong) AVPlayer *foreGroundPlayer;
@property (nonatomic, strong) AVPlayer *backGroundPlayer;
@property (nonatomic, strong) AVPlayerLayer *videoLayer;
@end

@implementation GSBackGroundMoviePlayerViewController
@synthesize playerStatus;

@synthesize foreGroundPlayer;
@synthesize backGroundPlayer;
@synthesize videoLayer;

#pragma mark UIViewController

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive: YES error: nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLicationDidEnterForeGround) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nextVideo) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    if (!headerView) {
        headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
        headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        headerView.backgroundColor = [UIColor grayColor];
        {
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(44, 0, 44, 44)];
            imageView.image = [[UIImage imageNamed:@"zuras_right"] stretchableImageWithLeftCapWidth:1 topCapHeight:1];
            [headerView addSubview:imageView];
        }        
        if (!headerLabel) {
            headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, headerView.bounds.size.width-55, 44)];
            headerLabel.lineBreakMode = NSLineBreakByWordWrapping;
            headerLabel.numberOfLines = 2;
            headerLabel.text = @"GS BackGround Movie Player";
            headerLabel.font = [UIFont systemFontOfSize:14];
            headerLabel.textColor = [UIColor whiteColor];
            headerLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            headerLabel.backgroundColor = [UIColor clearColor];
            headerLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.3];
            headerLabel.shadowOffset = CGSizeMake(1, 1);
            [headerView addSubview:headerLabel];
        }
        [self.view addSubview:headerView];
    }
    
    if (!tapGesture) {
        tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideOrShowInfo)];
        tapGesture.cancelsTouchesInView = YES;
        tapGesture.delegate = self;
        [self.view addGestureRecognizer:tapGesture];
    }
    
    if (!footerView) {
        footerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height-70, self.view.bounds.size.width, 70)];
        footerView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
        footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [self.view addSubview:footerView];
    }
    
    if (!normalView) {
        normalView = [[UIView alloc] initWithFrame:footerView.bounds];
        normalView.hidden = YES;
        normalView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [footerView addSubview:normalView];
    }
    
    if (!seeker) {
        seeker = [[UISlider alloc] initWithFrame:CGRectMake(0,0, headerView.bounds.size.width, 20)];
        seeker.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [seeker addTarget:self action:@selector(seekVideo) forControlEvents:UIControlEventTouchDragInside];
        [seeker addTarget:self action:@selector(seekVideoDone) forControlEvents:UIControlEventTouchUpInside];
        [seeker addTarget:self action:@selector(seekStart) forControlEvents:UIControlEventTouchDown];
        [seeker addTarget:self action:@selector(seekVideoDone) forControlEvents:UIControlEventTouchCancel];
        [normalView addSubview:seeker];
    }
    if (!currentTimeLabel) {
        currentTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 20, 50, 44)];
        currentTimeLabel.textAlignment = NSTextAlignmentCenter;
        currentTimeLabel.backgroundColor = [UIColor clearColor];
        currentTimeLabel.textColor = [UIColor whiteColor];
        currentTimeLabel.font = [UIFont systemFontOfSize:12];
        [normalView addSubview:currentTimeLabel];
    }
    if (!totalTimeLabel) {
        totalTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(normalView.bounds.size.width-55, 20, 50, 44)];
        totalTimeLabel.textAlignment = NSTextAlignmentCenter;
        totalTimeLabel.backgroundColor = [UIColor clearColor];
        totalTimeLabel.textColor = [UIColor whiteColor];
        totalTimeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        totalTimeLabel.font = [UIFont systemFontOfSize:12];
        [normalView addSubview:totalTimeLabel];
    }
    
    if (!loadingView) {
        loadingView = [[UIView alloc] initWithFrame:footerView.bounds];
        {
            UILabel *label = [[UILabel alloc] initWithFrame:loadingView.bounds];
            label.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            label.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            [label setText:@"Loading"];
            label.font = [UIFont systemFontOfSize:15];
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = [UIColor whiteColor];
            label.backgroundColor = [UIColor clearColor];
            [loadingView addSubview:label];
        }
        {
            UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(60, 0, 20, 20)];
            indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
            [indicator startAnimating];
            [loadingView addSubview:indicator];
        }
        [footerView addSubview:loadingView];
    }
    
    {
        UIButton *fullButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [fullButton setBackgroundImage:[UIImage imageNamed:@"prev"] forState:UIControlStateNormal];
        fullButton.showsTouchWhenHighlighted = YES;
        [fullButton addTarget:self action:@selector(prevVideo) forControlEvents:UIControlEventTouchUpInside];
        fullButton.frame = CGRectMake(60+16, 20, 44, 44);
        fullButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        [footerView addSubview:fullButton];
    }
    
    if (!playButton) {
        playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [playButton setBackgroundImage:[UIImage imageNamed:@"togluulah"] forState:UIControlStateNormal];
        [playButton setBackgroundImage:[UIImage imageNamed:@"pause"] forState:UIControlStateSelected];
        playButton.showsTouchWhenHighlighted = YES;
        [playButton addTarget:self action:@selector(togglePlayPause) forControlEvents:UIControlEventTouchUpInside];
        playButton.frame = CGRectMake(60+16+60, 20, 44, 44);
        playButton.selected = YES;
        playButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [footerView addSubview:playButton];
    }
    
    {
        UIButton *fullButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [fullButton setBackgroundImage:[UIImage imageNamed:@"next"] forState:UIControlStateNormal];
        fullButton.showsTouchWhenHighlighted = YES;
        [fullButton addTarget:self action:@selector(nextVideo) forControlEvents:UIControlEventTouchUpInside];
        fullButton.frame = CGRectMake(60+16+60+60, 20, 44, 44);
        fullButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [footerView addSubview:fullButton];
    }
    
    [self performSelector:@selector(hideOrShowInfo) withObject:nil afterDelay:7.0];
    
    [self startPlayMovie];
    self.playerStatus = PlayStatusLoadingInForeGround;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    self.videoLayer.frame = self.view.bounds;
}
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    self.videoLayer.frame = self.view.bounds;
    headerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, 44);
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}
#pragma mark Button Target

-(void)stop {
    if (self.foreGroundPlayer) {
        @try {
            [foreGroundPlayer removeObserver:self forKeyPath:@"status"];
        }
        @catch (NSException *exception) {
            
        }
        @finally {
            
        }
        [self.foreGroundPlayer pause];
    }
    if (self.backGroundPlayer) {
        @try {
            [backGroundPlayer removeObserver:self forKeyPath:@"status"];
        }
        @catch (NSException *exception) {
            
        }
        @finally {
            
        }
        [self.backGroundPlayer pause];
    }
    if (videoLayer) {
        videoLayer = nil;
    }
    self.playerStatus = PlayStatusPausedInForeGround;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (void)playAudio {
    if ([self appLicationIsInBackground])
    {
        self.playerStatus = PlayStatusPlayingInBackground;
        [backGroundPlayer play];
    }
    else {
        self.playerStatus = PlayStatusPlayingInForeGround;
        [foreGroundPlayer play];
    }
}
- (void)pauseAudio {
    if ([self appLicationIsInBackground])
    {
        self.playerStatus = PlayStatusPausedInBackground;
        [backGroundPlayer pause];
    }
    else {
        self.playerStatus = PlayStatusPausedInForeGround;
        [foreGroundPlayer pause];
    }
}
- (void)nextVideo {
    // play Next Video
}
- (void)prevVideo {
    // play Previous Video
}
- (void)togglePlayPause {
    float rate = [self appLicationIsInBackground] ? backGroundPlayer.rate : foreGroundPlayer.rate;
    if (rate == 1.0) {
        [self pauseAudio];
    }
    else {
        [self playAudio];
    }
    [self checkPlayButton];
}
#pragma mark ViewsReload
-(void)hideOrShowInfo {
    dispatch_async(dispatch_get_main_queue(), ^{
        id animation = objc_msgSend(NSClassFromString(@"CATransition"), @selector(animation));
        objc_msgSend(animation, @selector(setType:), @"kCATransitionFade");
        objc_msgSend(headerView.layer, @selector(addAnimation:forKey:), animation, nil);
        objc_msgSend(animation, @selector(setDuration:), 0.7);
        if (headerView.alpha == 1.0f) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideOrShowInfo) object:nil];
            headerView.alpha = 0.f;
            footerView.alpha = 0.f;
        }
        else {
            headerView.alpha = 1.f;
            footerView.alpha = 1.f;
            [self performSelector:@selector(hideOrShowInfo) withObject:nil afterDelay:7.0];
        }
    });
}
- (NSString*)secundToDuration:(int)duration{
    int seconds = duration % 60;
    int minutes = (duration / 60) % 60;
    int hours = duration / 3600;
    if (hours == 0) {
        return [NSString stringWithFormat:@"%d:%02d", minutes, seconds];
    }
    return [NSString stringWithFormat:@"%d:%02d:%02d",hours, minutes, seconds];
}
- (void)updateLabelAndSeeker {
    if (CMTIME_IS_VALID(foreGroundPlayer.currentTime)) {
        CMTime currentTime = self.foreGroundPlayer.currentTime;
        float seconds = CMTimeGetSeconds(currentTime);
        currentTimeLabel.text = [self secundToDuration:(int)seconds];

        CMTime durationTime = self.foreGroundPlayer.currentItem.asset.duration;
        float length = CMTimeGetSeconds(durationTime);
        [seeker setValue:seconds/length];
    }   
}

-(void)seekStart {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideOrShowInfo) object:nil];
}
-(void)seekVideoDone {
    [self.foreGroundPlayer play];
    [self performSelector:@selector(hideOrShowInfo) withObject:nil afterDelay:7.0];
    [self checkPlayButton];
}
-(void)seekVideo {
    [self.foreGroundPlayer pause];
    [self checkPlayButton];
    CMTime durationTime = self.foreGroundPlayer.currentItem.asset.duration;
    float length = CMTimeGetSeconds(durationTime);
    float currentDuration = length*seeker.value;
    CMTime time = CMTimeMakeWithSeconds(currentDuration, 1);
    [self.foreGroundPlayer seekToTime:time completionHandler:^(BOOL finished) {
        [self updateLabelAndSeeker];
    }];
}
-(void)startTimer {
    if ([timer isValid]) {
        [timer invalidate];
        timer = nil;
    }
    timer = [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(updateLabelAndSeeker) userInfo:nil repeats:YES];
}

-(void)willPlayVideo {
    CMTime duration = self.foreGroundPlayer.currentItem.asset.duration;
    float seconds = CMTimeGetSeconds(duration);
    totalTimeLabel.text = [self secundToDuration:(int)seconds];
    CMTime currentTime = self.foreGroundPlayer.currentTime;
    seconds = CMTimeGetSeconds(currentTime);
    currentTimeLabel.text = [self secundToDuration:(int)seconds];
    [self startTimer];
}

- (void) checkPlayButton {
    float rate = [self appLicationIsInBackground] ? backGroundPlayer.rate : foreGroundPlayer.rate;
    playButton.selected = (rate == 1.0) ? YES :NO;
}

#pragma mark Play Video

- (void) setMPNowPlayingInfoCenter {
    Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
    if (playingInfoCenter) {
        MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
        NSDictionary *songInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"GSBackGround Movie Player", MPMediaItemPropertyTitle,
                                  nil];
        center.nowPlayingInfo = songInfo;
    }
}
- (void) reloadBackGroundPlayer {
    if (self.backGroundPlayer) {
        @try {
            [backGroundPlayer removeObserver:self forKeyPath:@"status"];
        }
        @catch (NSException *exception) {
            
        }
        @finally {
            
        }
        [self.backGroundPlayer pause];
        backGroundPlayer = nil;
    }
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Dota2Final" ofType:@"mp4"];
    NSURL *assetURL = [NSURL fileURLWithPath:path];
    
    assert(assetURL);
    
    AVAsset *asset = [AVAsset assetWithURL:assetURL];
    assert(asset);
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    assert(playerItem);
    
    assert([asset tracks]);
    assert([[asset tracks] count]);
    
    self.backGroundPlayer = [AVPlayer playerWithPlayerItem:playerItem];
    [backGroundPlayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    assert(self.backGroundPlayer);
}

- (void)reloadForeGroundPlayer {
    if (foreGroundPlayer) {
        @try {
            [foreGroundPlayer removeObserver:self forKeyPath:@"status"];
        }
        @catch (NSException *exception) {
            
        }
        @finally {
            
        }
        [foreGroundPlayer pause];
        foreGroundPlayer = nil;
    }
    if (videoLayer) {
        
        [videoLayer removeFromSuperlayer];
        videoLayer = nil;
    }
    loadingView.hidden = NO;
    normalView.hidden = YES;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Dota2Final" ofType:@"mp4"];
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    {
        AVAsset *asset = [AVAsset assetWithURL:fileURL];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
        self.foreGroundPlayer = [AVPlayer playerWithPlayerItem:playerItem];
        [foreGroundPlayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    }
    {
        self.videoLayer = [AVPlayerLayer playerLayerWithPlayer:foreGroundPlayer];
        videoLayer.frame = self.view.bounds;
        [self.view.layer addSublayer:videoLayer];
    }
    [self.view bringSubviewToFront:footerView];
    [self.view bringSubviewToFront:headerView];
    
}
-(void)startPlayMovie {
    [self reloadBackGroundPlayer];
    [self reloadForeGroundPlayer];
    [self setMPNowPlayingInfoCenter];
}

#pragma mark UIAplicationState Change Notification

- (BOOL) appLicationIsInBackground {

    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        return NO;
    }
    else if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
        return YES;
    }
    else {
        if (self.playerStatus == PlayStatusLoadingInForeGroundThenSeekByBackGroundTime | self.playerStatus == PlayStatusLoadingInForeGroundThenSeekByBackGroundTimeAndPause | self.playerStatus == PlayStatusLoadingInForeGround | self.playerStatus == PlayStatusPlayingInForeGround | self.playerStatus == PlayStatusPausedInForeGround | self.playerStatus == PlayStatusFailedInForeGround) {
            return NO;
        }
        else {
            return YES;
        }
    }
}

-(void)setPlayerStatus:(PlayerStatus)_playerStatus {
    playerStatus = _playerStatus;
}


-(void)appLicationDidEnterForeGround {
    [self.backGroundPlayer pause];
    if (self.playerStatus == PlayStatusLoadingInBackgroundThenSeekByForeGroundTime) {
        [self.foreGroundPlayer play];
        self.playerStatus = PlayStatusPlayingInForeGround;
    }
    else if (self.playerStatus == PlayStatusLoadingInBackgroundThenSeekByForeGroundTimeAndPause) {
        [self.foreGroundPlayer pause];
        self.playerStatus = PlayStatusPausedInForeGround;
    }
    else if (self.playerStatus == PlayStatusLoadingInBackground) {
        [self.foreGroundPlayer play];
        self.playerStatus = PlayStatusPlayingInForeGround;
    }
    else if (self.playerStatus == PlayStatusPlayingInBackground) {
        if (CMTIME_IS_VALID(backGroundPlayer.currentTime)) {
            
            self.playerStatus = PlayStatusLoadingInForeGroundThenSeekByBackGroundTime;
            [self.foreGroundPlayer seekToTime:backGroundPlayer.currentTime completionHandler:^(BOOL finished) {
                [self.foreGroundPlayer play];
                self.playerStatus = PlayStatusPlayingInForeGround;
                [self checkPlayButton];
            }];
        }
        else {
            self.playerStatus = PlayStatusFailedInBackground;
        }
    }
    else if (self.playerStatus == PlayStatusPausedInBackground) {
        if (CMTIME_IS_VALID(backGroundPlayer.currentTime)) {
            self.playerStatus = PlayStatusLoadingInForeGroundThenSeekByBackGroundTimeAndPause;
            [self.foreGroundPlayer seekToTime:backGroundPlayer.currentTime completionHandler:^(BOOL finished) {
                [self.foreGroundPlayer pause];
                self.playerStatus = PlayStatusPausedInForeGround;
                [self checkPlayButton];
            }];
        }
        else {
            self.playerStatus = PlayStatusFailedInBackground;
        }
    }
    else if (self.playerStatus == PlayStatusFailedInBackground) {
        self.playerStatus = PlayStatusFailedInForeGround;
    }    
}
#pragma mark ObserveValueForKeyPath Notification
-(void)applicationDidEnterBackground {
    [self.foreGroundPlayer pause];
    if (self.playerStatus == PlayStatusLoadingInForeGroundThenSeekByBackGroundTime) {
        [self.backGroundPlayer play];
        self.playerStatus = PlayStatusPlayingInBackground;
    }
    else if (self.playerStatus == PlayStatusLoadingInForeGroundThenSeekByBackGroundTimeAndPause) {
        [self.backGroundPlayer pause];
        self.playerStatus = PlayStatusPausedInBackground;
    }
    else if (self.playerStatus == PlayStatusLoadingInForeGround) {
        [self.backGroundPlayer play];
        self.playerStatus = PlayStatusPlayingInBackground;
    }
    else if (self.playerStatus == PlayStatusPlayingInForeGround){
        if (CMTIME_IS_VALID(foreGroundPlayer.currentTime)) {
            [self.backGroundPlayer play];
            self.playerStatus = PlayStatusLoadingInBackgroundThenSeekByForeGroundTime;
            [self.backGroundPlayer seekToTime:foreGroundPlayer.currentTime completionHandler:^(BOOL finished) {
                [self.backGroundPlayer play];
                self.playerStatus = PlayStatusPlayingInBackground;
            }];
        }
        else {
            self.playerStatus = PlayStatusFailedInBackground;
        }
    }
    else if (self.playerStatus == PlayStatusPausedInForeGround){
        if (CMTIME_IS_VALID(foreGroundPlayer.currentTime)) {
            self.playerStatus = PlayStatusLoadingInBackgroundThenSeekByForeGroundTimeAndPause;
            [self.backGroundPlayer seekToTime:foreGroundPlayer.currentTime completionHandler:^(BOOL finished) {
                [self.backGroundPlayer pause];
                self.playerStatus = PlayStatusPausedInBackground;
            }];
        }
        else {
            self.playerStatus = PlayStatusFailedInBackground;
        }
    }
    else if (self.playerStatus == PlayStatusFailedInForeGround){
        self.playerStatus = PlayStatusFailedInBackground;
    }
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == backGroundPlayer && [keyPath isEqualToString:@"status"]) {
        if (backGroundPlayer.status == AVPlayerStatusReadyToPlay) {
            return;
            loadingView.hidden = YES;
            normalView.hidden = NO;
            [self willPlayVideo];
            if (self.playerStatus == PlayStatusLoadingInBackgroundThenSeekByForeGroundTime) {
                if (CMTIME_IS_VALID(foreGroundPlayer.currentTime)) {
                    [self.backGroundPlayer seekToTime:foreGroundPlayer.currentTime completionHandler:^(BOOL finished) {
                        [self.backGroundPlayer play];
                        self.playerStatus = PlayStatusPlayingInBackground;
                    }];
                }
            }
            else if (self.playerStatus == PlayStatusLoadingInBackgroundThenSeekByForeGroundTimeAndPause) {
                if (CMTIME_IS_VALID(foreGroundPlayer.currentTime)) {
                    [self.backGroundPlayer seekToTime:foreGroundPlayer.currentTime completionHandler:^(BOOL finished) {
                        [self.backGroundPlayer pause];
                        self.playerStatus = PlayStatusPausedInBackground;
                    }];
                }
            }
            else if (self.playerStatus == PlayStatusLoadingInBackground) {
                [self.backGroundPlayer play];
                self.playerStatus = PlayStatusPlayingInBackground;
            }
            else {
                [self.backGroundPlayer pause];
            }
        }
        else if (backGroundPlayer.status == AVPlayerStatusFailed) {
            self.playerStatus = PlayStatusFailedInBackground;
        }
    }

    else if (object == foreGroundPlayer && [keyPath isEqualToString:@"status"]){
        if (foreGroundPlayer.status == AVPlayerStatusReadyToPlay) {
            loadingView.hidden = YES;
            normalView.hidden = NO;
            [self willPlayVideo];
            if (self.playerStatus == PlayStatusLoadingInForeGround) {
                [self.foreGroundPlayer play];
                self.playerStatus = PlayStatusPlayingInForeGround;
            }            
        } else if (foreGroundPlayer.status == AVPlayerStatusFailed) {
            self.playerStatus = PlayStatusFailedInForeGround;
        }
    }
    [self checkPlayButton];
}

#pragma mark UIEventTypeRemoteControl Delegate

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    if (event.type == UIEventTypeRemoteControl) {
        if (event.subtype == UIEventSubtypeRemoteControlPlay) {            
            [self playAudio];
        } else if (event.subtype == UIEventSubtypeRemoteControlPause) {
            [self pauseAudio];
        } else if (event.subtype == UIEventSubtypeRemoteControlTogglePlayPause) {
            [self togglePlayPause];
        }
        else if (event.subtype == UIEventSubtypeRemoteControlNextTrack) {
            [self nextVideo];
        }
        else if (event.subtype == UIEventSubtypeRemoteControlPreviousTrack) {
            [self prevVideo];
        }
    }
}

#pragma mark UIGestureRecognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[UITextField class]] ||
        [touch.view isKindOfClass:[UIButton class]])
    {
        return NO;
    }
    return YES;
}

#pragma mark Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)viewDidUnload {
    seeker = nil;
    currentTimeLabel = nil;
    totalTimeLabel = nil;;
    headerView = nil;
    headerLabel = nil;
    normalView = nil;
    loadingView = nil;
    
    footerView = nil;
    playButton = nil;
    tapGesture = nil;
    
    [super viewDidUnload];
}

#pragma mark UIInterfaceOrientation

-(void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    UIScreen *screen = [UIScreen mainScreen];
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        videoLayer.frame = screen.bounds;
    }
    else {
        videoLayer.frame = CGRectMake(0, 0, screen.bounds.size.height, screen.bounds.size.width);
    }
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}
-(BOOL)shouldAutorotate {
    return YES;
}
- (NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}
@end
