//
//  CQAssetsDisplayCell.h
//  Pods
//
//  Created by 陈长青 on 2017/5/10.
//
//

#import <UIKit/UIKit.h>

#define MinimumZoomScale 1
#define MaximumZoomScale 2

// MARK: - 单元格

@interface CQAssetsDisplayCell : UIScrollView

@property (strong, nonatomic) UIView *contentView;

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier;// 初始化
- (void)setImageUrl:(NSString *)remoteUrl andPlaceHolder:(UIImage *)placeHolder;// 设置远程图片和占位图
- (void)setVideoUrl:(NSString *)videoUrl;// 设置视频播放地址(远程地址)
- (void)setLocalVideoUrl:(NSURL *)localVideoUrl;// 设置视频播放地址(本地地址)

// 变为重用
- (void)changeToReuse;
// 恢复没有缩放
- (void)changeAssetViewToInitialState;
// 单击事件
- (void)toggleControls;
// 播放
- (void)playVideo;

@end
