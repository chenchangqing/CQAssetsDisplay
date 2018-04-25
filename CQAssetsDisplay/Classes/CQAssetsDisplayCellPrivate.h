//
//  CQAssetsDisplayCellPrivate.h
//  Pods
//
//  Created by 陈长青 on 2017/5/30.
//
//
#import "ESPictureProgressView.h"
#import <CQVRPlayer/CQVideoPlayer.h>
#import <CQVRPlayer/CQVRRenderView.h>
#import <CQVRPlayer/CQVideoControlView_VR.h>

@interface CQAssetsDisplayCell ()<CQVRRenderViewDelegate,CQVRRenderViewDataSource>

@property (nonatomic, weak) UIImageView     *imageView;     // 显示图片
@property (copy, nonatomic) NSString        *videoUrl;      // 视频地址
@property (strong, nonatomic) NSURL         *localVidUrl;   // 本地地址
@property (copy, nonatomic) NSString        *imageURL;      // 图片地址
@property (strong, nonatomic) UIImage       *placeHolder;   // 占位图片

@property (nonatomic, assign) NSInteger index;

@property (weak, nonatomic) UIView                  *placeView;             // 约束cell做边距的视图
@property (weak, nonatomic) ESPictureProgressView   *progressView;          // 进度
@property (weak, nonatomic) CQVideoPlayer         *videoPlayer;           // 播放器
@property (weak, nonatomic) CQVRRenderView          *videoPlayerView;       // 播放视频
@property (weak, nonatomic) UIButton                *videoPlayBtn;          // 播放按钮
@property (weak, nonatomic) UIView<CQVideoControlViewProtocol> *videoControlView;      // 视频控制区
@property (weak, nonatomic) UIButton                *closeBtn;              // 关闭按钮
@property (weak, nonatomic) UISegmentedControl      *sceneTypeSeg;// 切换场景

@property (weak, nonatomic) NSLayoutConstraint *placeViewWith;              // 左边距约束
@property (nonatomic, copy, readonly) NSString *reuseIdentifier;            // 重用id

// 加载图片
- (void)loadImageDataWithCompletion:(void(^)(BOOL))callback;
// 设置播放按钮
- (void)setHidePlayerIconWithLoadImageOk:(BOOL)loadImageOK andIndex:(NSInteger)page;
// imageView适配cell
- (void)fix;
// 重置计时器
- (void)resetTimer;

@end
