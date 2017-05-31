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

@property (weak, nonatomic) UIView *contentView;

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier;// 初始化
- (void)setImageUrl:(NSString *)remoteUrl andPlaceHolder:(UIImage *)placeHolder;// 设置远程图片和占位图
- (void)setVideoUrl:(NSString *)videoUrl;// 设置视频播放地址

@end
