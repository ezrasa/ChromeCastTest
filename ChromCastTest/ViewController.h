//
//  ViewController.h
//  ChromCastTest
//
//  Created by Sandeep on 09/02/14.
//  Copyright (c) 2014 Sandeep. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CCPlayerView.h"
@interface ViewController : UIViewController

@property (nonatomic, weak) IBOutlet CCPlayerView *playerView;
@property (nonatomic, weak) IBOutlet UIButton *playButton;
@property (nonatomic, weak) IBOutlet UISlider *scrubber;
@property	(nonatomic, weak) IBOutlet UITableView *tableView;

@end
