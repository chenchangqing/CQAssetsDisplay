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
- (void)showWithFromView:(UIView *)fromView andCellPadding:(CGFloat)cellPadding andCurrentPage:(NSInteger)currentPage;    // 显示
- (void)exit;                                                                       // 退出
- (CQAssetsDisplayCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;  // 得到可复用视图


@end
