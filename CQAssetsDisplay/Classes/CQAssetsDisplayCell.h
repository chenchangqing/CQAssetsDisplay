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

// MARK: - 资源协议

@protocol CQAssetProtocol <NSObject>

- (void)getImageURL:(void (^)(UIImage *,NSError *))completion withProgress:(void (^)(double))progress; // 获取远程图片

@end

// MARK: - 单元格

@interface CQAssetsDisplayCell : UIScrollView

@property (nonatomic, readonly, strong) UIImageView   *imageView;     // 显示图片

@property (nonatomic, copy, readonly) NSString *reuseIdentifier;                    // 重用id
@property (nonatomic, weak) id<CQAssetProtocol> asset;                              // 资源

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier;                // 初始化
- (void)fix;                                                                        // imageView适配cell

@end
