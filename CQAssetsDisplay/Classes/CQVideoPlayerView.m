//
//  CQVideoPlayerView.m
//  Pods
//
//  Created by 陈长青 on 2017/5/25.
//
//

#import "CQVideoPlayerView.h"

@implementation CQVideoPlayerView

- (void)setAVPlayer:(AVPlayer *)avPlayer {
    AVPlayerLayer *avPlayerLayer = (AVPlayerLayer *)self.layer;
    avPlayerLayer.player = avPlayer;
}

+ (Class)layerClass {
    
    // 使用视频播放Layer
    return [AVPlayerLayer class];
}

@end
