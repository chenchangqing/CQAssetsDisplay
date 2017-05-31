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

@interface CQAssetsDisplayCell ()

@property (nonatomic, weak) UIImageView     *imageView;     // 显示图片
@property (copy, nonatomic) NSString        *videoUrl;      // 视频地址
@property (copy, nonatomic) NSString        *imageURL;      // 图片地址
@property (strong, nonatomic) UIImage       *placeHolder;   // 占位图片

@property (nonatomic, assign) NSInteger index;

@property (weak, nonatomic) UIView                  *placeView;             // 约束cell做边距的视图
@property (weak, nonatomic) ESPictureProgressView   *progressView;          // 进度
@property (strong, nonatomic) CQVideoPlayer         *videoPlayer;           // 播放器
@property (weak, nonatomic) CQVideoPlayerView       *videoPlayerView;       // 播放视频
@property (weak, nonatomic) UIButton                *videoPlayBtn;          // 播放按钮

@property (weak, nonatomic) NSLayoutConstraint *placeViewWith;              // 左边距约束
@property (nonatomic, copy, readonly) NSString *reuseIdentifier;            // 重用id

// 播放
- (void)playVideo;
// 加载图片
- (void)loadImageDataWithCompletion:(void(^)(BOOL))callback;
// 设置播放按钮
- (void)setHidePlayerIconWithLoadImageOk:(BOOL)loadImageOK;
// 变为重用
- (void)changeToReuse;
// 恢复没有缩放
- (void)changeAssetViewToInitialState;
// imageView适配cell
- (void)fix;

@end