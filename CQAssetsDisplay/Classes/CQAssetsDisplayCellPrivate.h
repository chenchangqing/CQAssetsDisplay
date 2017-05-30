//
//  CQAssetsDisplayCellPrivate.h
//  Pods
//
//  Created by 陈长青 on 2017/5/30.
//
//
#import "ESPictureProgressView.h"
#import "CQVideoPlayer.h"
#import "CQVideoPlayerView.h"

#ifndef CQAssetsDisplayCellPrivate_h
#define CQAssetsDisplayCellPrivate_h

@interface CQAssetsDisplayCell ()

@property (nonatomic, weak) UIImageView   *imageView;
@property (copy, nonatomic) NSString *videoUrl;
@property (copy, nonatomic) NSString *imageURL;
@property (strong, nonatomic) UIImage *placeHolder;

@property (nonatomic, assign) NSInteger index;

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

#endif /* CQAssetsDisplayCellPrivate_h */
