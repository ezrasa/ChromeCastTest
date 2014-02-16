//
//  CCPlayerView.m
//  ChromCastTest
//
//  Created by Sandeep on 16/02/14.
//  Copyright (c) 2014 Sandeep. All rights reserved.
//

#import "CCPlayerView.h"
#import <AVFoundation/AVFoundation.h>

@implementation CCPlayerView

+ (Class)layerClass{
  return [AVPlayerLayer class];
}

- (AVPlayer*)player{
  return [(AVPlayerLayer*)self.layer player];
}

- (void)setPlayer:(AVPlayer *)player{
  [(AVPlayerLayer*)self.layer setPlayer:player];
}


@end
