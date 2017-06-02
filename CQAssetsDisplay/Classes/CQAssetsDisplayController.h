//
//  CQAssetsDisplayController.h
//  Pods
//
//  Created by 陈长青 on 2017/5/10.
//
//

#import <UIKit/UIKit.h>
#import "CQAssetsDisplayCell.h"

// MARK: - DataSource

@class CQAssetsDisplayController;

@protocol CQAssetsDisplayControllerDataSource <NSObject>

@required
- (NSInteger)numberOfCellsInAssetsDisplayController:(CQAssetsDisplayController *)controller;                            // 单元格格数
- (CQAssetsDisplayCell *)assetsDisplayController:(CQAssetsDisplayController *)controller cellForIndex:(NSInteger)index; // 返回单元格
- (UIView *)getEndView:(CQAssetsDisplayController *)controller;                                                         // 退出动画的endView

@end

// MARK: - 资源浏览器

@interface CQAssetsDisplayController : UIViewController

@property (nonatomic, weak) id<CQAssetsDisplayControllerDataSource> dataSource;     // 数据源
@property (nonatomic, assign) NSInteger currentPage;                                // 当前页数

- (void)reloadData;                                                                 // 刷新

// 显示
- (void)showWithFromView:(UIView *)fromView// 被点击的视图
          andCellPadding:(CGFloat)cellPadding// 单元格间距
          andCurrentPage:(NSInteger)currentPage// 当前页
andShowCloseBtnWhenVideo:(BOOL)showCloseBtnWhenVideo// 当显示视频是否显示关闭按钮
           andIsAutoPlay:(BOOL)isAutoPlay;// 当点击视频时，是否自动播放

- (void)exit;                                                                       // 退出
- (CQAssetsDisplayCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;  // 得到可复用视图


@end
