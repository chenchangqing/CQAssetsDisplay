//
//  CQAssetsDisplayController.m
//  Pods
//
//  Created by 陈长青 on 2017/5/10.
//
//

#import "CQAssetsDisplayController.h"
#import "CQAssetsDisplayCellPrivate.h"
#import "CQAssetsDisplayCell.h"
#import "CQVideoControlView.h"

//默认动画时间，单位秒
#define DEFAULT_DURATION 0.25

typedef void(^DelayBlock)();

typedef NSMutableArray<CQAssetsDisplayCell *> AssetsDisplayCells;
typedef NSMutableDictionary<NSString *, UIView *> LeftPlaceholdViewDic;

@interface CQAssetsDisplayController ()<UIScrollViewDelegate> {
    
}

@property (nonatomic, weak) UIScrollView       *scrollView;                 // scrollView控件
@property (nonatomic, weak) UIView             *scrollViewContentView;      // scrollView内容视图
@property (nonatomic, weak) NSLayoutConstraint *scrollViewContentViewWidth; // scrollView内容视图宽

@property (nonatomic, strong) AssetsDisplayCells    *alreadyShowCells;      // 正在 显示的cell数组（最多3个）
@property (nonatomic, strong) AssetsDisplayCells    *prepareShowCells;      // 准备 显示的cell数组(复用)
@property (nonatomic, weak)   CQAssetsDisplayCell   *preCell;               // 前一个cell
@property (nonatomic, weak)   CQAssetsDisplayCell   *currentCell;           // 当前cell
@property (nonatomic, weak)   CQAssetsDisplayCell   *nextCell;              // 后一个cell

@property (nonatomic, strong) DelayBlock scrollToPageBlock;                 // scrollview还没加载，延迟设置当前页
@property (nonatomic, strong) DelayBlock animateShowBlock;                  // 动画显示
@property (nonatomic, strong) DelayBlock animateHideBlock;                  // 动画隐藏
@property (nonatomic, assign, readonly) NSInteger numberOfCells;            // 单元格格数
@property (nonatomic, strong) UIViewController *currentVC;                  // 当前控制器
@property (nonatomic, weak) UIView *fromView;                               // 来自哪个view
@property (nonatomic, assign) CGFloat cellPadding;                          // cell之间的间隔
@property (nonatomic, assign) BOOL showCloseBtnWhenVideo;                   // 当为视频时是否显示关闭按钮
@property (nonatomic, assign) BOOL isRoting;                                // 是否正在旋转

@end

@implementation CQAssetsDisplayController


#pragma mark - 生命周期

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
    // 动画隐藏
    if (_animateHideBlock) {
        _animateHideBlock();
        _animateHideBlock = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    // 延迟设置当前页
    if (_scrollToPageBlock) {
        _scrollToPageBlock();
        _scrollToPageBlock = nil;
    }
    
    // 动画显示
    if (_animateShowBlock) {
        _animateShowBlock();
        _animateShowBlock = nil;
    }
    
    //禁止左滑动返回
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}

- (BOOL)shouldAutorotate{
    return NO;
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// MARK: - UI

- (void)setup {
    
    self.view.backgroundColor = [UIColor blackColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    // 初始化数组、字典及其他
    _alreadyShowCells = [AssetsDisplayCells array];
    _prepareShowCells = [AssetsDisplayCells array];
    
    // scrollView控件
    UIScrollView *scrollView = [UIScrollView new];
    [self.view addSubview:scrollView];
    _scrollView = scrollView;
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrollView.pagingEnabled = YES;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.directionalLockEnabled = YES;
    _scrollView.delegate = self;
    _scrollView.delaysContentTouches = YES;
    _scrollView.canCancelContentTouches = YES;
    
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(_scrollView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_scrollView]" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_scrollView]-0-|" options:0 metrics:nil views:views]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_scrollView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1 constant:_cellPadding]];
    
    // scrollView内容视图
    UIView *scrollViewContentView = [UIView new];
    [_scrollView addSubview:scrollViewContentView];
    _scrollViewContentView = scrollViewContentView;
    _scrollViewContentView.translatesAutoresizingMaskIntoConstraints = NO;
    views = NSDictionaryOfVariableBindings(_scrollViewContentView);
    [scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_scrollViewContentView]-0-|" options:0 metrics:nil views:views]];
    [scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_scrollViewContentView]-0-|" options:0 metrics:nil views:views]];
    [scrollView addConstraint:[NSLayoutConstraint constraintWithItem:_scrollViewContentView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_scrollView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    // 监听设备方向
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    // 增加手势
    [self addGestures];
    
}

// 增加手势
- (void)addGestures {
    //添加Gesture
    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGR.numberOfTapsRequired = 1;
    tapGR.numberOfTouchesRequired = 1;
    tapGR.delegate = self;
    [self.view addGestureRecognizer:tapGR];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleZoom:)];
    tapGesture.numberOfTapsRequired = 2;
    tapGesture.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tapGesture];
    
    [tapGR requireGestureRecognizerToFail:tapGesture];
}

// 响应单击
- (void)handleTapGesture:(UITapGestureRecognizer *)tap {

//    if (self.currentCell.videoUrl||self.currentCell.localVidUrl) {
//
//        [self.currentCell toggleControls];
//    } else {
//        [self exit];
//    }
    [self.currentCell toggleControls];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    [self.currentCell resetTimer];
    
    NSMutableArray *marray = [[NSMutableArray alloc] initWithCapacity:0];
    if (!self.currentCell.videoControlView.hidden) {
        
        [marray addObject:self.currentCell.videoControlView];
        BOOL valid = ![marray containsObject:touch.view]
        && ![marray containsObject:touch.view.superview];
        return valid;
    }
    return YES;
}

// MARK: - 刷新

// 刷新
- (void)reloadData {
    
    // 清除cells
    [self clearCells];
    
    // 重置contentSize
    [self resetScrollViewContentSize];
    
    // 显示
    [self setCurrentPage:_currentPage];
}

// 清除cells
- (void)clearCells {
    
    // 清除正在显示的cells
    for (CQAssetsDisplayCell *cell in _alreadyShowCells) {
        [cell removeFromSuperview];
    }
    [_alreadyShowCells removeAllObjects];
    
    // 清除准备显示的cells
    for (CQAssetsDisplayCell *cell in _prepareShowCells) {
        [cell removeFromSuperview];
    }
    [_prepareShowCells removeAllObjects];
}

// 重置 scrollView 的 contentSize
- (void)resetScrollViewContentSize {
    
    // 重置contentSize
    if (_scrollViewContentViewWidth)
        [self.scrollView removeConstraint:_scrollViewContentViewWidth];
    NSLayoutConstraint *scrollViewContentViewWidth = [NSLayoutConstraint constraintWithItem:_scrollViewContentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_scrollView attribute:NSLayoutAttributeWidth multiplier:self.numberOfCells constant:0];
    [self.scrollView addConstraint:scrollViewContentViewWidth];
    _scrollViewContentViewWidth = scrollViewContentViewWidth;
    [self.scrollView layoutIfNeeded];
    [self.scrollView setContentSize:_scrollViewContentView.frame.size];
}


// MARK: - 适配设备方向

// 处理旋转
- (void)orientationChanged:(NSNotification *)note  {
    
    _isRoting = YES;
    UIDeviceOrientation o = [[UIDevice currentDevice] orientation];
    switch (o) {
        case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
            
            
            [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:NO];
            [self fitOrientation:CGAffineTransformIdentity];
            break;
        case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
            
            break;
        case UIDeviceOrientationLandscapeLeft:      // Device oriented horizontally, home button on the right
            [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:NO];
            [self fitOrientation:CGAffineTransformMakeRotation(M_PI*0.5)];
            break;
        case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
            [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeLeft animated:NO];
            [self fitOrientation:CGAffineTransformMakeRotation(-M_PI*0.5)];
            
            break;
        default:
            
            break;
    }
    _isRoting = NO;
}

// 适配旋转
- (void)fitOrientation:(CGAffineTransform) transform {
    
    if (CGAffineTransformEqualToTransform([UIApplication sharedApplication].keyWindow.transform, transform)) {// 防止滑动无效
        
        return;
    }
    
    CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
    [UIView animateWithDuration:duration animations:^{
        
        CGFloat min = MIN(CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds));
        CGFloat max = MAX(CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds));
        
        [UIApplication sharedApplication].keyWindow.transform = transform;
        if (CGAffineTransformEqualToTransform(transform, CGAffineTransformIdentity)) {
            
            [UIApplication sharedApplication].keyWindow.bounds = CGRectMake(0, 0, min, max);
        } else {
            
            [UIApplication sharedApplication].keyWindow.bounds = CGRectMake(0, 0, max, min);
        }
    } completion:^(BOOL finished) {
        
    }];
    
    [self resetScrollViewContentSize];
    
    // 更新图片大小
    for (CQAssetsDisplayCell *cell in _alreadyShowCells) {
        [cell fix];
    }
    
    [self scrollToCurrentPage];
}

// MARK: - 显示 or 退出

// 退出
- (void)exit {
    
    if (!CGAffineTransformEqualToTransform(CGAffineTransformIdentity, [UIApplication sharedApplication].keyWindow.transform)) {
        [self fitOrientation:CGAffineTransformIdentity];
    }
    [self.navigationController popViewControllerAnimated:NO];
    
    __weak typeof(self) weakSelf = self;
    _animateHideBlock = ^() {
        
        UIView *endView;
        if ([_dataSource respondsToSelector:@selector(getEndView:)]) {
            endView = [_dataSource getEndView:weakSelf];
        }
        
        if (endView) {
            
            UIImageView *targetView = weakSelf.currentCell.imageView;
            [weakSelf.currentVC.view addSubview:targetView];
            [UIView animateWithDuration:DEFAULT_DURATION delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                
                targetView.frame = [endView convertRect:endView.bounds toView:weakSelf.currentVC.view];
                
            } completion:^(BOOL finished) {
                [targetView removeFromSuperview];
            }];
        } else {
            
            UIView *blackView = [[UIView alloc] initWithFrame:weakSelf.currentVC.view.bounds];
            blackView.backgroundColor = [UIColor blackColor];
            [weakSelf.currentVC.view addSubview:blackView];
            
            UIImageView *targetView = weakSelf.currentCell;
            [weakSelf.currentVC.view addSubview:targetView];
            [UIView animateWithDuration:DEFAULT_DURATION delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                
                blackView.alpha = 0;
                targetView.alpha = 0;
                
            } completion:^(BOOL finished) {
                [blackView removeFromSuperview];
                [targetView removeFromSuperview];
            }];
        }
    };
}

// 显示
- (void)showWithFromView:(UIView *)fromView andCellPadding:(CGFloat)cellPadding andCurrentPage:(NSInteger)currentPage andShowCloseBtnWhenVideo:(BOOL)showCloseBtnWhenVideo andIsAutoPlay:(BOOL)isAutoPlay{

    if ([self.currentVC isKindOfClass:[UINavigationController class]]) {
        
        UINavigationController *navController = (UINavigationController *)self.currentVC;
        [navController pushViewController:self animated:NO];
    }else if (self.currentVC.navigationController) {
        
        [self.currentVC.navigationController pushViewController:self animated:NO];
    } else {
        
        [self.currentVC presentViewController:self animated:NO completion:nil];
    }
    
    _cellPadding = cellPadding > 0 ? cellPadding : 0;
    _fromView = fromView;
    _showCloseBtnWhenVideo = showCloseBtnWhenVideo;
    
    __weak typeof(self) weakSelf = self;
    _animateShowBlock = ^() {
        
        // 重置contentSize
        [weakSelf resetScrollViewContentSize];
        [weakSelf setCurrentPage:currentPage andIsScrollToCurrentPage:YES andCallback:^(CQAssetsDisplayCell *item, BOOL loadImageOK) {
            
            UIImageView *imageView = weakSelf.currentCell.imageView;
            CGRect frame = imageView.frame;
            CGRect startFrame = [fromView convertRect:fromView.bounds toView:[UIApplication sharedApplication].keyWindow];
            if (!CGRectEqualToRect(frame, CGRectZero) && weakSelf.currentPage == currentPage/**滑动后，判断当前页**/) {
                
                imageView.frame = startFrame;
                [UIApplication sharedApplication].delegate.window.userInteractionEnabled = NO;
                [UIView animateWithDuration:DEFAULT_DURATION
                                      delay:0
                                    options:UIViewAnimationOptionCurveEaseInOut
                                 animations:^{
                    imageView.frame = frame;
                } completion:^(BOOL finished) {
                     
                    [UIApplication sharedApplication].delegate.window.userInteractionEnabled = YES;
                    [item setHidePlayerIconWithLoadImageOk:loadImageOK andIndex:currentPage];
                    if (isAutoPlay && (item.videoUrl || item.localVidUrl)) { [item playVideo]; }
                }];
            } else {
                
                [item setHidePlayerIconWithLoadImageOk:loadImageOK andIndex:currentPage];
                if (isAutoPlay &&  (item.videoUrl || item.localVidUrl)) { [item playVideo]; }
            }
        }];
    };
}

// MARK: -

//获取当前屏幕显示的 View Controller
//- (UIViewController *)currentVC
//{
//    if (!_currentVC) {
//        UIViewController *result = nil;
//        UIWindow * window        = [[UIApplication sharedApplication] keyWindow];
//        if (window.windowLevel != UIWindowLevelNormal) {
//            NSArray *windows = [[UIApplication sharedApplication] windows];
//            for(UIWindow * tmpWin in windows) {
//                if (tmpWin.windowLevel == UIWindowLevelNormal) {
//                    window = tmpWin;
//                    break;
//                }
//            }
//        }
//
//        UIView *frontView = [[window subviews] objectAtIndex:0];
//        id nextResponder  = [frontView nextResponder];
//
//        if ([nextResponder isKindOfClass:[UIViewController class]])
//            result = nextResponder;
//        else
//            result = window.rootViewController;
//
//        _currentVC = result;
//        //    _currentVC = [TopVC shared].top;
//    }
//
//    return _currentVC;
//}

- (UIViewController *)currentVC {
    UIViewController *topRootViewController = [[UIApplication  sharedApplication] keyWindow].rootViewController;
    
    // 在这里加一个这个样式的循环
    while (topRootViewController.presentedViewController)
    {
        // 这里固定写法
        topRootViewController = topRootViewController.presentedViewController;
    }
    return  topRootViewController;
}

// 得到可复用视图
- (CQAssetsDisplayCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier {
    
    CQAssetsDisplayCell *cell;
    
    AssetsDisplayCells *_prepareShowCellByFilter = [_prepareShowCells filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"reuseIdentifier MATCHES %@", identifier]];
    
    if (_prepareShowCellByFilter.count == 0) {
        
        return nil;
    }else {
        
        cell = [_prepareShowCellByFilter firstObject];
        [_prepareShowCells removeObject:[_prepareShowCellByFilter firstObject]];
    }
    return cell;
}

// 获取单元格格数
- (NSInteger)numberOfCells {
    
    NSInteger numberOfCells = 0;
    if ([_dataSource respondsToSelector:@selector(numberOfCellsInAssetsDisplayController:)])
        numberOfCells = [_dataSource numberOfCellsInAssetsDisplayController:self];
    return numberOfCells;
}

- (CQAssetsDisplayCell *)currentCell {
    
    return [self cellForIndex:_currentPage];
}

- (CQAssetsDisplayCell *)preCell {
    
    return [self cellForIndex:_currentPage - 1];
}

- (CQAssetsDisplayCell *)nextCell {
    
    return [self cellForIndex:_currentPage + 1];
}

- (CQAssetsDisplayCell *)cellForIndex:(NSInteger) page {
    
    AssetsDisplayCells *currentShowCellByFilter = [_alreadyShowCells filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"index == %d", page]];
    if (currentShowCellByFilter.count > 0) {
        return currentShowCellByFilter[0];
    }
    return nil;
}

// MARK: - 处理左右滑动

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (_scrollView == scrollView && !_isRoting) {
        
        CGPoint centerPoint = CGPointMake(scrollView.frame.size.width/2, scrollView.frame.size.height/2);
        CGPoint point = [self.view convertPoint:centerPoint toView:self.scrollView];
        
//        NSLog(@"中心点：%@", NSStringFromCGPoint(point));
//        NSLog(@"self.scrollView.frame:%@",NSStringFromCGRect(self.scrollView.frame));
//        NSLog(@"scrollView.contentOffset.x：%f",scrollView.contentOffset.x);
//        NSLog(@"self.preCell.frame:%@",NSStringFromCGRect(self.preCell.frame));
//        NSLog(@"self.nextCell.frame:%@",NSStringFromCGRect(self.nextCell.frame));
//        NSLog(@"self.scrollViewContentView.frame:%@",NSStringFromCGRect(self.scrollViewContentView.frame));
        
        if (CGRectContainsPoint(self.preCell.frame, point)) {// 左滑
            
            NSInteger willGoPage = _currentPage-1;
            if (willGoPage >=0) {
                
                [self setCurrentPage:willGoPage andIsScrollToCurrentPage:NO andCallback:^(CQAssetsDisplayCell *cell, BOOL loadImageOk) {
                    [cell setHidePlayerIconWithLoadImageOk:loadImageOk andIndex:willGoPage];
                }];
            }
        }
        
        if (CGRectContainsPoint(self.nextCell.frame, point)) {// 右滑
            
            NSInteger willGoPage = _currentPage+1;
            if (willGoPage < self.numberOfCells) {
                
                [self setCurrentPage:willGoPage andIsScrollToCurrentPage:NO andCallback:^(CQAssetsDisplayCell *cell, BOOL loadImageOk) {
                    [cell setHidePlayerIconWithLoadImageOk:loadImageOk andIndex:willGoPage];
                }];
            }
        }
    }
}

// 设置当前页
- (void)setCurrentPage:(NSInteger)currentPage{
    [self setCurrentPage:currentPage andIsScrollToCurrentPage:YES andCallback:^(CQAssetsDisplayCell *item, BOOL loadImageOK){
        [item setHidePlayerIconWithLoadImageOk:loadImageOK andIndex:currentPage];
    }];
}


// 设置当前页
- (void)setCurrentPage:(NSInteger)currentPage
    andIsScrollToCurrentPage:(BOOL)isScrollToCurrentPage/* 当载scrollViewDidScroll方法中设置当前页，不需要改变*/
    andCallback:(void(^)(CQAssetsDisplayCell *,BOOL loadImageOk))callback {
    
    // 延迟设置
    __weak typeof(self) weakSelf = self;
    if (!_scrollView) {
        
        _scrollToPageBlock = ^() {
            weakSelf.currentPage = currentPage;
        };
        return;
    }
    
    // 更新当前页
    if (self.numberOfCells > 0
        && currentPage <= self.numberOfCells - 1
        && currentPage >= 0
        && _scrollView) {
        
        [self.currentCell changeAssetViewToInitialState];
        _currentPage = currentPage;
        
        AssetsDisplayCells *exists = [_alreadyShowCells filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"index == %d", currentPage]];
        if (exists.count==0) {
            CQAssetsDisplayCell *citem = [self setCellForIndex:_currentPage];
            __weak typeof(citem) weakCitem = citem;
            [weakCitem loadImageDataWithCompletion:^(BOOL loadImageOK){
                callback(weakCitem,loadImageOK);
            }];
        }
        
        // 设置右边的视图
        if (currentPage + 1 < self.numberOfCells) {
            
            exists = [_alreadyShowCells filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"index == %d", currentPage+1]];
            if (exists.count==0) {
                
                CQAssetsDisplayCell *ritem = [self setCellForIndex:currentPage + 1];
                __weak typeof(ritem) weakRitem = ritem;
                [weakRitem loadImageDataWithCompletion:^(BOOL loadImageOK){
                    [weakRitem setHidePlayerIconWithLoadImageOk:loadImageOK andIndex:currentPage + 1];
                }];
            }
        }
        
        // 设置左边的视图
        if (currentPage > 0) {
            
            exists = [_alreadyShowCells filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"index == %d", currentPage-1]];
            if (exists.count==0) {
                
                CQAssetsDisplayCell *litem = [self setCellForIndex:currentPage - 1];
                __weak typeof(litem) weakLitem = litem;
                [weakLitem loadImageDataWithCompletion:^(BOOL loadImageOK){
                    [weakLitem setHidePlayerIconWithLoadImageOk:loadImageOK andIndex:currentPage - 1];
                }];
            }
        }
        
        // 滑动到当前页
        if (isScrollToCurrentPage) {
            
            [self scrollToCurrentPage];
        }
    }
}

// 滑动到当前页
- (void)scrollToCurrentPage {
    
    CGFloat width = _scrollViewContentView.frame.size.width/self.numberOfCells;
    [_scrollView setContentOffset:CGPointMake(width*_currentPage, 0) animated:NO];
}

// 设置重用
- (void)removeCellToReUse {
    
    NSMutableArray *tempArray = [NSMutableArray array];
    for (CQAssetsDisplayCell *cell in _alreadyShowCells) {
        // 判断某个view的页数与当前页数相差值为2的话，那么让这个view从视图上移除
        if (abs((int)cell.index - (int)_currentPage) >= 2){
            [tempArray addObject:cell];
            
            // item属性重置
            [cell changeToReuse];
            
            // 增加重用
            [_prepareShowCells addObject:cell];
        }
    }
    // 移除显示
    [_alreadyShowCells removeObjectsInArray:tempArray];
}

// 设置cell
- (CQAssetsDisplayCell * )setCellForIndex:(NSInteger)index {
    
    // 设置重用
    [self removeCellToReUse];
    
    // item
    CQAssetsDisplayCell *cell;
    if ([_dataSource respondsToSelector:@selector(assetsDisplayController:cellForIndex:)]) {
        
        cell = [_dataSource assetsDisplayController:self cellForIndex:index];
        cell.delegate = self;
    }
    if (cell == nil) return nil;
    if (cell.placeView) {
        
        [_scrollView removeConstraint:cell.placeViewWith];
        
        NSLayoutConstraint *placeViewWith = [NSLayoutConstraint constraintWithItem:cell.placeView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_scrollView attribute:NSLayoutAttributeWidth multiplier:index constant:0];
        [_scrollView addConstraint:placeViewWith];
        cell.placeViewWith = placeViewWith;
    } else {
        
        // 创建占位
        UIView *placeView = [UIView new];
        placeView.backgroundColor = [UIColor clearColor];
        [_scrollViewContentView insertSubview:placeView atIndex:0];
        cell.placeView = placeView;
        
        placeView.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(placeView);
        [_scrollViewContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[placeView]-0-|" options:0 metrics:nil views:views]];
        [_scrollViewContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[placeView]" options:0 metrics:nil views:views]];
        
        NSLayoutConstraint *placeViewWith = [NSLayoutConstraint constraintWithItem:placeView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_scrollView attribute:NSLayoutAttributeWidth multiplier:index constant:0];
        [_scrollView addConstraint:placeViewWith];
        cell.placeViewWith = placeViewWith;
        
        // 增加playerView
        CQVRRenderView *playerView = [CQVRRenderView new];
        playerView.userInteractionEnabled = YES;
        playerView.translatesAutoresizingMaskIntoConstraints = NO;
        playerView.backgroundColor = [UIColor clearColor];
        playerView.delegate = cell;
        playerView.dataSource = cell;
        [_scrollViewContentView addSubview:playerView];
        cell.videoPlayerView = playerView;
        
        views = @{@"playerView":playerView};
        [_scrollViewContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[playerView]-0-|" options:0 metrics:nil views:views]];
        [_scrollView addConstraint:[NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_scrollView attribute:NSLayoutAttributeWidth multiplier:1 constant:-_cellPadding]];
        [_scrollViewContentView addConstraint:[NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:cell.placeView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
        
        // 视频控制区
        CQVideoControlView *videoControlView = [[CQVideoControlView alloc] init];
        videoControlView.translatesAutoresizingMaskIntoConstraints = NO;
        videoControlView.delegate = cell;
        videoControlView.dataSource = cell;
        videoControlView.hidden = YES;
        [_scrollViewContentView addSubview:videoControlView];
        cell.videoControlView = videoControlView;

        views = @{@"videoControlView":videoControlView};
        [_scrollViewContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[videoControlView(60)]-0-|" options:0 metrics:nil views:views]];
        [_scrollView addConstraint:[NSLayoutConstraint constraintWithItem:videoControlView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_scrollView attribute:NSLayoutAttributeWidth multiplier:1 constant:-_cellPadding]];
        [_scrollViewContentView addConstraint:[NSLayoutConstraint constraintWithItem:videoControlView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:cell.placeView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
        
        // 增加cell
        [_scrollViewContentView addSubview:cell];
        
        [cell fix];
        
        cell.translatesAutoresizingMaskIntoConstraints = NO;
        views = NSDictionaryOfVariableBindings(cell);
        [_scrollViewContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[cell]-0-|" options:0 metrics:nil views:views]];
        [_scrollView addConstraint:[NSLayoutConstraint constraintWithItem:cell attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_scrollView attribute:NSLayoutAttributeWidth multiplier:1 constant:-_cellPadding]];
        
        // 获得占位，然后设置cell的左边约束
        [_scrollViewContentView addConstraint:[NSLayoutConstraint constraintWithItem:cell attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:cell.placeView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
        
        // 内容视图
        UIView *contentView = cell.contentView;
        contentView.userInteractionEnabled = NO;
        contentView.translatesAutoresizingMaskIntoConstraints = NO;
        contentView.backgroundColor = [UIColor clearColor];
        [_scrollViewContentView addSubview:contentView];
        
        views = @{@"contentView":contentView};
        [_scrollViewContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[contentView]-0-|" options:0 metrics:nil views:views]];
        [_scrollView addConstraint:[NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_scrollView attribute:NSLayoutAttributeWidth multiplier:1 constant:-_cellPadding]];
        [_scrollViewContentView addConstraint:[NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:cell.placeView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
        
        // 进度视图
        ESPictureProgressView *progressView = [[ESPictureProgressView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        progressView.userInteractionEnabled = NO;
        progressView.translatesAutoresizingMaskIntoConstraints = NO;
        [_scrollViewContentView addSubview:progressView];
        cell.progressView = progressView;
        
        [_scrollViewContentView addConstraint:[NSLayoutConstraint constraintWithItem:progressView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [_scrollViewContentView addConstraint:[NSLayoutConstraint constraintWithItem:progressView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        [_scrollViewContentView addConstraint:[NSLayoutConstraint constraintWithItem:progressView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1 constant:50]];
        [_scrollViewContentView addConstraint:[NSLayoutConstraint constraintWithItem:progressView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1 constant:50]];
        
        // 播放按钮
        UIButton *videoPlayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        videoPlayBtn.tintColor = [UIColor whiteColor];
        [videoPlayBtn addTarget:cell action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
        videoPlayBtn.translatesAutoresizingMaskIntoConstraints = NO;
        videoPlayBtn.hidden = YES;
        [videoPlayBtn setImage:[self videoPlayImage] forState:UIControlStateNormal];
        [_scrollViewContentView addSubview:videoPlayBtn];
        cell.videoPlayBtn = videoPlayBtn;
        
        [_scrollViewContentView addConstraint:[NSLayoutConstraint constraintWithItem:videoPlayBtn attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [_scrollViewContentView addConstraint:[NSLayoutConstraint constraintWithItem:videoPlayBtn attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        [_scrollViewContentView addConstraint:[NSLayoutConstraint constraintWithItem:videoPlayBtn attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1 constant:100]];
        [_scrollViewContentView addConstraint:[NSLayoutConstraint constraintWithItem:videoPlayBtn attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1 constant:100]];
        
        // 关闭按钮
        if (_showCloseBtnWhenVideo) {
            
            UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            closeBtn.hidden = YES;
            closeBtn.tintColor = [UIColor whiteColor];
            [closeBtn setImage:[self videoCloseImage] forState:UIControlStateNormal];
            [closeBtn addTarget:self action:@selector(exit) forControlEvents:UIControlEventTouchUpInside];
            closeBtn.translatesAutoresizingMaskIntoConstraints = NO;
            [_scrollViewContentView addSubview:closeBtn];
            cell.closeBtn = closeBtn;
            
            views = NSDictionaryOfVariableBindings(closeBtn,placeView);
            [_scrollViewContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(-10)-[closeBtn(100)]" options:0 metrics:nil views:views]];
            [_scrollViewContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[placeView]-(-10)-[closeBtn(100)]" options:0 metrics:nil views:views]];
        }
        
        // 切换场景
        UISegmentedControl *sceneTypeSeg = [[UISegmentedControl alloc] initWithItems:@[@"360",@"180",@"2D"]];
        sceneTypeSeg.tintColor = [UIColor whiteColor];
        sceneTypeSeg.hidden = YES;
        sceneTypeSeg.translatesAutoresizingMaskIntoConstraints = NO;
        sceneTypeSeg.selectedSegmentIndex = 2;
        [sceneTypeSeg addTarget:self action:@selector(sceneTypeSegChange:) forControlEvents:UIControlEventValueChanged];
        [_scrollViewContentView addSubview:sceneTypeSeg];
        cell.sceneTypeSeg = sceneTypeSeg;
        
        views = NSDictionaryOfVariableBindings(sceneTypeSeg,placeView);
        [_scrollViewContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(28)-[sceneTypeSeg(28)]" options:0 metrics:nil views:views]];
        [_scrollViewContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[placeView]-(150)-[sceneTypeSeg(100)]" options:0 metrics:nil views:views]];
    }
    
    // 属性重置
    cell.frame = CGRectMake(self.scrollViewContentView.frame.size.width/self.numberOfCells*index, 0, self.scrollViewContentView.frame.size.width/self.numberOfCells-_cellPadding/** 关键 **/, self.scrollViewContentView.frame.size.height);
    cell.index = index;
    [_alreadyShowCells addObject:cell];
    
    return cell;
}

- (void)sceneTypeSegChange:(UISegmentedControl *)sender {
    
    if (sender.selectedSegmentIndex == 0) {
        [self.currentCell selectedSphereSceneType];
        _scrollView.scrollEnabled = NO;
    }
    if (sender.selectedSegmentIndex == 1) {
        [self.currentCell selectedHalSphereSceneType];
        _scrollView.scrollEnabled = NO;
    }
    if (sender.selectedSegmentIndex == 2) {
        [self.currentCell selectedPlaneSceneType];
        _scrollView.scrollEnabled = YES;
    }
}

// MARK: - 资源

- (NSBundle *)assetsBundle
{
    NSBundle *assetsBundle = nil;
    if (assetsBundle == nil) {
        // 这里不使用mainBundle是为了适配pod 1.x和0.x
        assetsBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"CQAssetsDisplay" ofType:@"bundle"]];
    }
    return assetsBundle;
}

- (UIImage *)videoPlayImage
{
    UIImage *arrowImage = nil;
    if (arrowImage == nil) {
        arrowImage = [[UIImage imageWithContentsOfFile:[[self assetsBundle] pathForResource:@"video_play@3x" ofType:@"png"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return arrowImage;
}

- (UIImage *)videoCloseImage
{
    UIImage *arrowImage = nil;
    if (arrowImage == nil) {
        arrowImage = [[UIImage imageWithContentsOfFile:[[self assetsBundle] pathForResource:@"video_close@3x" ofType:@"png"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return arrowImage;
}

#pragma mark - 处理缩放

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if (![scrollView isKindOfClass:[CQAssetsDisplayCell class]])
        return nil;
    if (self.currentCell.videoUrl || self.currentCell.localVidUrl) {
        return nil;
    }
    return ((CQAssetsDisplayCell *)scrollView).imageView;
}

//处理双击放大、缩小
- (void)handleZoom:(UITapGestureRecognizer *)tap {
    
    if (self.currentCell.isZooming)return;
    CGFloat zoomScale = self.currentCell.zoomScale;
    
    if(zoomScale < 1.0 + FLT_EPSILON) {
        CGPoint loc = [tap locationInView: self.currentCell];
        CGRect rect = CGRectMake(loc.x - 0.5, loc.y - 0.5, 1, 1);
        
        [self.currentCell zoomToRect:rect animated:YES];
    }else {
        [self.currentCell setZoomScale:1 animated:YES];
    }
    
}

- (void)scrollViewDidZoom:(CQAssetsDisplayCell *)scrollView {
    
    if (![scrollView isKindOfClass:[CQAssetsDisplayCell class]])
        return ;
    UIImageView *zoomImageView = (UIImageView *)[self viewForZoomingInScrollView: scrollView];
    
    CGRect frame = zoomImageView.frame;
    
    //当视图不能填满整个屏幕时，让其居中显示
    frame.origin.x = (CGRectGetWidth(self.view.frame) > CGRectGetWidth(frame)) ? (CGRectGetWidth(self.view.frame) - CGRectGetWidth(frame))/2 : 0;
    frame.origin.y = (CGRectGetHeight(self.view.frame) > CGRectGetHeight(frame)) ? (CGRectGetHeight(self.view.frame) - CGRectGetHeight(frame))/2 : 0;
    if (fabs(scrollView.zoomScale - 1.0) < FLT_EPSILON) {
        [scrollView fix];
    }
    
    zoomImageView.frame = frame;
    
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
