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

- (void)videoPlayerPrepareToLoadAsset:(CQVideoPlayer *)videoPlayer;// 准备资源（开始loading)
- (void)videoPlayerProgressToLoadAsset:(CQVideoPlayer *)videoPlayer withProgress:(double)progress;// 下载进度（更新下载进度）
- (void)videoPlayerPrepareToPlay:(CQVideoPlayer *)videoPlayer andAVPlayer:(AVPlayer *)avPlayer;// 准备播放（开始设置avPlayer）
- (void)videoPlayerSuccessToPlay:(CQVideoPlayer *)videoPlayer;// 成功播放（隐藏图片）
- (void)videoPlayerFailureToPlay:(CQVideoPlayer *)videoPlayer;// 失败播放（显示错误提示）

@end

// MARK: - 播放器

@interface CQVideoPlayer : NSObject

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
