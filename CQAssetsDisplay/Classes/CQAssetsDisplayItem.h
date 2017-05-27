//
//  CQAssetsDisplayItem.h
//  Pods
//
//  Created by 陈长青 on 2017/5/24.
//
//

#import <Foundation/Foundation.h>
#import "CQAssetsDisplayCell.h"
#import "ESPictureProgressView.h"
#import "CQVideoPlayer.h"
#import "CQVideoPlayerView.h"

@interface CQAssetsDisplayItem : NSObject

@property (nonatomic, assign) NSInteger index;

@property (weak, nonatomic) CQAssetsDisplayCell *cell;
@property (weak, nonatomic) UIView *placeView;
@property (weak, nonatomic) ESPictureProgressView *progressView;
@property (weak, nonatomic) UIView *contentView;
@property (strong, nonatomic) CQVideoPlayer *videoPlayer;
@property (weak, nonatomic) CQVideoPlayerView *videoPlayerView;
@property (weak, nonatomic) UIButton *videoPlayBtn;

@property (weak, nonatomic) NSLayoutConstraint *placeViewWith;

- (void)playVideo;

- (void)suspendDownload;
@end
