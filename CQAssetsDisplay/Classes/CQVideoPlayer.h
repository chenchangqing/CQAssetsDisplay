//
//  CQPlayer.h
//  Pods
//
//  Created by green on 16/6/19.
//
//
#import <AVFoundation/AVFoundation.h>

// MARK: - 播放器代理

@class CQVideoPlayer;
@protocol CQVideoPlayerDelegate <NSObject>

- (void)getVideoURL:(void (^)(NSURL *))completion withProgress:(void (^)(double))progress;// 下载资源(实现先下载，后播放)

- (void)videoPlayerWillLoadAsset:(CQVideoPlayer *)videoPlayer;// 将要加载资源
- (void)videoPlayerLoadingAsset:(CQVideoPlayer *)videoPlayer withProgress:(double)progress;// 正在加载资源
- (void)videoPlayerDidLoadAsset:(CQVideoPlayer *)videoPlayer andSuccess:(BOOL)success;// 资源加载完成

- (void)videoPlayerWillPlay:(CQVideoPlayer *)videoPlayer;// 将要播放
- (void)videoPlayerPreparePlay:(CQVideoPlayer *)videoPlayer;// 准备播放
- (void)videoPlayerPlaying:(CQVideoPlayer *)videoPlayer andCurrentTime:(NSTimeInterval)time duratoin:(NSTimeInterval)duration;// 正在播放
- (void)videoPlayerPause:(CQVideoPlayer *)videoPlayer;// 播放暂停
- (void)videoPlayerStop:(CQVideoPlayer *)videoPlayer;// 播放停止
- (void)videoPlayerDidPlay:(CQVideoPlayer *)videoPlayer andSuccess:(BOOL)success;// 播放完成

@end

// MARK: - 播放器

@interface CQVideoPlayer : NSObject


@property (strong, nonatomic) AVPlayer *avPlayer;
@property (weak, nonatomic) id<CQVideoPlayerDelegate> delegate;// 代理

- (void)free;// 释放
- (BOOL)isPlaying;// 是否正在播放
- (void)play;// 播放
- (void)pause;// 暂停
- (void)stop;// 停止
- (void)scrubbingDidStart;// 开始滑动进度条
- (void)scrubbedToTime:(NSTimeInterval)time;// 正在滑动进度条
- (void)scrubbingDidEnd;// 结束滑动进度条
- (void)jumpedToTime:(NSTimeInterval)time;// 调整播放时间
- (CVPixelBufferRef)getPixelBuffer;// 获取视频数据

@end
