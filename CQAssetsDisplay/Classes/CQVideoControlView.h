//
//  CQVideoControlView.h
//  Pods
//
//  Created by 陈长青 on 2017/5/31.
//
//

#import <UIKit/UIKit.h>

// 视频播放控制代理

@protocol CQVideoControlViewDelegate <NSObject>

- (void)play;// 播放
- (void)pause;// 暂停
- (void)scrubbingDidStart;// 开始滑动进度条
- (void)scrubbedToTime:(NSTimeInterval)time;// 正在滑动进度条
- (void)scrubbingDidEnd;// 结束滑动进度条
- (BOOL)isDidLoadAssetSuccess;// 是否成功加载资源

@end


// 视频播放控制

@interface CQVideoControlView : UIView

@property (weak, nonatomic) id<CQVideoControlViewDelegate> delegate;

@property (assign) BOOL scrubbing;// 是否正在滑动
-(void)setCurrentTime:(NSTimeInterval)time duration:(NSTimeInterval)duration;//更新播放进度
-(void)playbackComplete;//处理播放完成
-(void)setToPlaying:(BOOL) isPlaying;//处理播放暂停

@end
