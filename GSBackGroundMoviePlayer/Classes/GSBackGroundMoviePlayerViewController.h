//
//  GSBackGroundMoviePlayerViewController.h
//  DJTube
//
//  Created by Gantulga Tsendsuren on 8/1/13.
//  Copyright (c) 2013 Sorako. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum{
    PlayStatusLoadingInForeGroundThenSeekByBackGroundTime = 1,
    PlayStatusLoadingInForeGroundThenSeekByBackGroundTimeAndPause = 2,

	PlayStatusLoadingInForeGround = 3,
    PlayStatusPlayingInForeGround = 4,
    PlayStatusPausedInForeGround = 5,
    PlayStatusFailedInForeGround = 6,

    PlayStatusLoadingInBackgroundThenSeekByForeGroundTime = 7,
    PlayStatusLoadingInBackgroundThenSeekByForeGroundTimeAndPause = 8,

    PlayStatusLoadingInBackground = 9,
    PlayStatusPlayingInBackground = 10,
    PlayStatusPausedInBackground = 11,
    PlayStatusFailedInBackground = 12,
    PlayStatusBackGround = 13,


} PlayerStatus;

@interface GSBackGroundMoviePlayerViewController : UIViewController
@property (nonatomic, assign) PlayerStatus playerStatus;

-(void)stop;
- (void)playAudio ;
- (void)pauseAudio ;
- (void)nextVideo ;
- (void)prevVideo ;
- (void)togglePlayPause ;
@end
