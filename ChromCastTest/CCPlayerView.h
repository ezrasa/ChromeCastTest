//
//  CCPlayerView.h
//  ChromCastTest
//
//  Created by Sandeep on 16/02/14.
//  Copyright (c) 2014 Sandeep. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AVPlayer;

@interface CCPlayerView : UIView
	@property (nonatomic, retain) AVPlayer *player;
@end
