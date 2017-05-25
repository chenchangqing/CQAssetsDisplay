//
//  CQPlayer.m
//  Pods
//
//  Created by green on 16/6/19.
//
//

#import "CQVideoPlayer.h"
#import <AVFoundation/AVFoundation.h>

// AVPlayerItem's status property
#define STATUS_KEYPATH @"status"

// Refresh interval for timed observations of AVPlayer
#define REFRESH_INTERVAL 0.5f

// Define this constant for the key-value observation context.
static const NSString *PlayerItemStatusContext;

/// MARK: - 从后台或别的场景切换回来恢复之前播放状态

typedef NS_ENUM(NSInteger, CQVPWillChangeStatus) {
    CQVPWillChangeStatusPause,// 暂停
    CQVPWillChangeStatusPlaying // 正在播放
};

@interface CQVideoPlayer ()<AVPlayerItemOutputPullDelegate> {
    
    AVPlayerItemVideoOutput* videoOutput;
    dispatch_queue_t videoOutputQueue;
}

@property (strong, nonatomic) AVAsset *asset;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayer *player;

@property (weak, nonatomic) id timeObserver;
@property (weak, nonatomic) id itemEndObserver;
@property (assign, nonatomic) float lastPlaybackRate;

@property (assign, nonatomic) BOOL isCanChangeVideoControlView;// 是否可以改变播放界面控件
@property (assign, nonatomic) BOOL isAlreadyFree;// 已经释放

@property (assign, nonatomic) BOOL isLoadAsset;// 正在加载资源

//从后台或别的场景切换回来恢复之前播放状态

@property (assign, nonatomic) CQVPWillChangeStatus willChangeStatus;

// 当前播放时间

@property (assign, nonatomic) NSTimeInterval currentTime;

// 视频总时间

@property (assign, nonatomic) NSTimeInterval totalDuration;
@property (assign, nonatomic) BOOL isAddObserverStatusKeyPath;

@end

@implementation CQVideoPlayer

#pragma mark - Setup

- (instancetype)init {
    self = [super init];
    if (self) {
        
        _isAddObserverStatusKeyPath = NO;
        _isAlreadyFree = NO;
        _willChangeStatus = CQVPWillChangeStatusPause;
        
        // 通知
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(recordPause) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(recordResume) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

-(void)recordPause{
    
    BOOL isPlaying = [self isPlaying];
    self.willChangeStatus = isPlaying ? CQVPWillChangeStatusPlaying : CQVPWillChangeStatusPause;
    [self pause];
}

-(void)recordResume{
    
    if (self.willChangeStatus == CQVPWillChangeStatusPlaying) {
        [self play];
    }
}

- (void)prepareToPlay {
    
    if (_isLoadAsset) {
        
        return;
    }
    
    if (_player) {
        
        if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
            
            if ([self.delegate respondsToSelector:@selector(videoPlayerSuccessToPlay:)]) {
                
                [self.delegate videoPlayerSuccessToPlay:self];
            }
        }
        return;
    }
    
    if (_isLoadAsset) {
        
        return;
    }
    
    if ([_delegate respondsToSelector:@selector(videoPlayerPrepareToLoadAsset:)]) {
        
        [_delegate videoPlayerPrepareToLoadAsset:self];
    }
    
    if (self.asset) {
        
        [self prepareToPlayAfterLoadAsset];
    } else {
        
        if (_delegate) {
            
            _isLoadAsset = YES;
            __weak typeof(self) weakSelf = self;
            [_delegate getVideoURL:^(NSURL *url) {
                
                weakSelf.isLoadAsset = NO;
                if (url) {
                    
                    weakSelf.asset = [AVAsset assetWithURL:url];
                    [weakSelf prepareToPlayAfterLoadAsset];
                    
                } else {
                    
                    if ([weakSelf.delegate respondsToSelector:@selector(videoPlayerFailureToPlay:)]) {
                        
                        [weakSelf.delegate videoPlayerFailureToPlay:weakSelf];
                    }
                }
            } withProgress:^(double progress) {
                
                if ([weakSelf.delegate respondsToSelector:@selector(videoPlayerProgressToLoadAsset:withProgress:)]) {
                    [weakSelf.delegate videoPlayerProgressToLoadAsset:weakSelf withProgress:progress];
                }
                
            }];
        } else {
            
            if ([_delegate respondsToSelector:@selector(videoPlayerFailureToPlay:)]) {
                
                [_delegate videoPlayerFailureToPlay:self];
            }
        }
    }
}

- (void)prepareToPlayAfterLoadAsset {
    
    NSDictionary *pixelBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
    videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixelBuffAttributes];
    videoOutputQueue = dispatch_queue_create("PlayerViewControllerQueue", DISPATCH_QUEUE_SERIAL);
    
    [videoOutput setDelegate:self queue:videoOutputQueue];
    
    NSArray *keys = @[
                      @"tracks",
                      @"duration",
                      @"commonMetadata",
                      @"availableMediaCharacteristicsWithMediaSelectionOptions"
                      ];
    
    self.playerItem = [AVPlayerItem playerItemWithAsset:self.asset
                           automaticallyLoadedAssetKeys:keys];
    _isAddObserverStatusKeyPath = YES;

    [self.playerItem addObserver:self
                      forKeyPath:STATUS_KEYPATH
                         options:0
                         context:&PlayerItemStatusContext];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    if ([_delegate respondsToSelector:@selector(videoPlayerPrepareToPlay:)]) {
        
        [_delegate videoPlayerPrepareToPlay:self andAVPlayer:self.player];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if (context == &PlayerItemStatusContext) {
        
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            
            if (weakSelf.isAddObserverStatusKeyPath) {
                weakSelf.isAddObserverStatusKeyPath = NO;
                [weakSelf.playerItem removeObserver:weakSelf forKeyPath:STATUS_KEYPATH];
            }
            
            if (weakSelf.playerItem.status == AVPlayerItemStatusReadyToPlay) {
                
                if ([weakSelf.delegate respondsToSelector:@selector(videoPlayerSuccessToPlay:)]) {
                    
                    [weakSelf.delegate videoPlayerSuccessToPlay:weakSelf];
                }
                
                [self->_playerItem addOutput:self->videoOutput];
                [self->videoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:0.03];
                
                // Set up time observers.
                [weakSelf addPlayerItemTimeObserver];
                [weakSelf addItemEndObserverForPlayerItem];
                
                CMTime duration = weakSelf.playerItem.duration;
                
                // Synchronize the time display
                
//                if ([weakSelf.toolBar respondsToSelector:@selector(setCurrentTime:duration:)]
//                    && weakSelf.isCanChangeVideoControlView) {
//                    
//                    weakSelf.totalDuration = CMTimeGetSeconds(duration);
//                    [weakSelf.toolBar setCurrentTime:CMTimeGetSeconds(kCMTimeZero)
//                                                 duration:CMTimeGetSeconds(duration)];
//                }
                
                [weakSelf.player play];
                
            } else {
                
                if ([weakSelf.delegate respondsToSelector:@selector(videoPlayerFailureToPlay:)]) {
                    
                    [weakSelf.delegate videoPlayerFailureToPlay:self];
                }
            }
        });
    }
}

- (void)free {
    
    if (_isAlreadyFree) {
        
        return;
    }
    _isAlreadyFree = YES;
    
    if (_isAddObserverStatusKeyPath) {
        _isAddObserverStatusKeyPath = NO;
        [self.playerItem removeObserver:self forKeyPath:STATUS_KEYPATH];
    }
    
    if (self.itemEndObserver) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc removeObserver:self.itemEndObserver
                      name:AVPlayerItemDidPlayToEndTimeNotification
                    object:self.player.currentItem];
        self.itemEndObserver = nil;
    }
    
    if (self.timeObserver) {
        
        [self.player removeTimeObserver:self.timeObserver];
    }
    [self.player replaceCurrentItemWithPlayerItem:nil];
    
    // 处理videoOutput代理
    [videoOutput setDelegate:nil queue:videoOutputQueue];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
    
    NSLog(@"%s",__FUNCTION__);
}

/// MARK: - Override Getters/Setters

- (AVPlayer *)player {
    
    return _player;
}

- (BOOL)isCanChangeVideoControlView {
    
    return YES;
}

#pragma mark - Time Observers

- (void)addPlayerItemTimeObserver {
    
    // Create 0.5 second refresh interval - REFRESH_INTERVAL == 0.5
    CMTime interval = CMTimeMakeWithSeconds(REFRESH_INTERVAL, NSEC_PER_SEC);
    
    // Main dispatch queue
    dispatch_queue_t queue = dispatch_get_main_queue();
    
    // Create callback block for time observer
    __weak CQVideoPlayer *weakSelf = self;
    void (^callback)(CMTime time) = ^(CMTime time) {
        weakSelf.currentTime = CMTimeGetSeconds(time);
        weakSelf.totalDuration = CMTimeGetSeconds(weakSelf.playerItem.duration);
//        if ([weakSelf.toolBar respondsToSelector:@selector(setCurrentTime:duration:)]
//            && weakSelf.isCanChangeVideoControlView) {
//            
////            [weakSelf.toolBar setCurrentTime:weakSelf.currentTime duration:weakSelf.totalDuration];
//        }

    };
    
    // Add observer and store pointer for future use
    self.timeObserver =
    [self.player addPeriodicTimeObserverForInterval:interval
                                              queue:queue
                                         usingBlock:callback];
}

- (void)addItemEndObserverForPlayerItem {
    
    NSString *name = AVPlayerItemDidPlayToEndTimeNotification;
    
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    
    __weak CQVideoPlayer *weakSelf = self;
    void (^callback)(NSNotification *note) = ^(NSNotification *notification) {
        [weakSelf.player seekToTime:kCMTimeZero
                  completionHandler:^(BOOL finished) {
//                      if ([weakSelf.toolBar respondsToSelector:@selector(playbackComplete)]
//                          && self.isCanChangeVideoControlView) {
//                          
////                          [weakSelf.toolBar playbackComplete];
//                      }
                  }];
    };
    
    self.itemEndObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:name
                                                      object:self.playerItem
                                                       queue:queue
                                                  usingBlock:callback];
}

#pragma mark - CQVideoPlayerProtocol

- (void)play {
    
    [self prepareToPlay];
    [self.player play];
//    if ([self.toolBar respondsToSelector:@selector(setToPlaying:)]
//        && self.isCanChangeVideoControlView) {
//        
////        [self.toolBar setToPlaying:YES];
//    }
}

- (void)pause {
    
    self.lastPlaybackRate = self.player.rate;
    [self.player pause];
//    if ([self.toolBar respondsToSelector:@selector(setToPlaying:)]
//        && self.isCanChangeVideoControlView) {
//        
////        [self.toolBar setToPlaying:NO];
//    }
}

- (void)stop {
    
    [self.player setRate:0.0f];
//    if ([self.toolBar respondsToSelector:@selector(playbackComplete)]
//        && self.isCanChangeVideoControlView) {
//        
////        [self.toolBar playbackComplete];
//    }
}

- (void)scrubbingDidStart {
    
    self.lastPlaybackRate = self.player.rate;
    [self.player pause];
    [self.player removeTimeObserver:self.timeObserver];
}

- (void)scrubbedToTime:(NSTimeInterval)time {
    
    [self.playerItem cancelPendingSeeks];
    [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)scrubbingDidEnd {
    
    [self addPlayerItemTimeObserver];
    if (self.lastPlaybackRate > 0.0f) {
        [self.player play];
    }
}

- (void)jumpedToTime:(NSTimeInterval)time {
    [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
}

- (CVPixelBufferRef)getPixelBuffer {
    
    CVPixelBufferRef pixelBuffer = [videoOutput copyPixelBufferForItemTime:[_playerItem currentTime] itemTimeForDisplay:nil];
    
    return pixelBuffer;
}

- (BOOL)isPlaying {
    
    return _player.rate == 1;
}

@end
