//
//  CQAssetsDisplayController.m
//  Pods
//
//  Created by 陈长青 on 2017/5/10.
//
//

#import "CQAssetsDisplayController.h"

//默认动画时间，单位秒
#define DEFAULT_DURATION 0.25

typedef void(^DelayBlock)();

typedef NSMutableArray<CQAssetsDisplayCell *> AssetsDisplayCells;
typedef NSMutableDictionary<NSString *, UIView *> LeftPlaceholdViewDic;

@interface CQAssetsDisplayController ()<UIScrollViewDelegate> {
    
    BOOL _isFromScrollViewDidScroll;// 当载scrollViewDidScroll方法中设置当前页，不需要改变contentoffset
}

@property (nonatomic, weak) UIScrollView       *scrollView;                 // scrollView控件
@property (nonatomic, weak) UIView             *scrollViewContentView;      // scrollView内容视图
@property (nonatomic, weak) NSLayoutConstraint *scrollViewContentViewWidth; // scrollView内容视图宽

@property (nonatomic, strong) AssetsDisplayCells    *alreadyShowCells;      // 正在 显示的cell数组（最多3个）
@property (nonatomic, strong) AssetsDisplayCells    *prepareShowCells;      // 准备 显示的cell数组(复用)
@property (nonatomic, strong) LeftPlaceholdViewDic  *leftPlaceholdViewDic;  // 正在 显示的cell左边占位视图(约束要用)
@property (nonatomic, weak)   CQAssetsDisplayCell   *currentCell;           // 当前cell

@property (nonatomic, strong) DelayBlock scrollToPageBlock;                 // scrollview还没加载，延迟设置当前页
@property (nonatomic, strong) DelayBlock animateShowBlock;                  // 动画显示
@property (nonatomic, strong) DelayBlock animateHideBlock;                  // 动画隐藏
@property (nonatomic, assign, readonly) NSInteger numberOfCells;            // 单元格格数
@property (nonatomic, strong) UIViewController *currentVC;                  // 当前控制器
@property (nonatomic, weak) UIView *fromView;                               // 来自哪个view

@end

@implementation CQAssetsDisplayController


#pragma mark - 生命周期

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    [self reloadData];
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
    _leftPlaceholdViewDic = [LeftPlaceholdViewDic dictionary];
    _currentPage = _currentPage == 0 ? -1 : _currentPage;
    _cellPadding = 10;
    _isFromScrollViewDidScroll = NO;
    
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
    [self.view addGestureRecognizer:tapGR];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleZoom:)];
    tapGesture.numberOfTapsRequired = 2;
    tapGesture.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tapGesture];
    
    [tapGR requireGestureRecognizerToFail:tapGesture];
}

// 响应单击
- (void)handleTapGesture:(UITapGestureRecognizer *)tap {

    [self exit];
}

// MARK: - 刷新

// 刷新
- (void)reloadData {
    
    // 清除cells
    [self clearCells];
    
    // 重置contentSize
    [self resetScrollViewContentSize];
    
    // 显示
    [self setCurrentPage:_currentPage == -1 ? 0 : _currentPage];
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
    
    // 清除占位的cells
    for (UIView *placeView in _leftPlaceholdViewDic.allValues) {
        [placeView removeFromSuperview];
    }
    [_leftPlaceholdViewDic removeAllObjects];
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
}

// 适配旋转
- (void)fitOrientation:(CGAffineTransform) transform {
    
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
    [self scrollToCurrentPage];
    
    // 更新图片大小
    for (CQAssetsDisplayCell *cell in _alreadyShowCells) {
        [cell fix];
    }
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
- (void)showWithFromView:(UIView *)fromView {

    if ([self.currentVC isKindOfClass:[UINavigationController class]]) {
        
        UINavigationController *navController = (UINavigationController *)self.currentVC;
        [navController pushViewController:self animated:NO];
    }else if (self.currentVC.navigationController) {
        
        [self.currentVC.navigationController pushViewController:self animated:NO];
    } else {
        
        [self.currentVC presentViewController:self animated:NO completion:nil];
    }
    
    _fromView = fromView;
    __weak typeof(self) weakSelf = self;
    _animateShowBlock = ^() {
        
        CGRect frame = weakSelf.currentCell.imageView.frame;
        if (!CGRectEqualToRect(frame, CGRectZero)) {
            
            weakSelf.currentCell.imageView.frame = [fromView convertRect:fromView.bounds toView:fromView.window];
            [UIApplication sharedApplication].delegate.window.userInteractionEnabled = NO;
            [UIView animateWithDuration:DEFAULT_DURATION
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                weakSelf.currentCell.imageView.frame = frame;
            } completion:^(BOOL finished) {
                 
                [UIApplication sharedApplication].delegate.window.userInteractionEnabled = YES;
            }];
        }
    };
}

// MARK: -

//获取当前屏幕显示的 View Controller
- (UIViewController *)currentVC
{
    if (!_currentVC) {
        UIViewController *result = nil;
        UIWindow * window        = [[UIApplication sharedApplication] keyWindow];
        if (window.windowLevel != UIWindowLevelNormal) {
            NSArray *windows = [[UIApplication sharedApplication] windows];
            for(UIWindow * tmpWin in windows) {
                if (tmpWin.windowLevel == UIWindowLevelNormal) {
                    window = tmpWin;
                    break;
                }
            }
        }
        
        UIView *frontView = [[window subviews] objectAtIndex:0];
        id nextResponder  = [frontView nextResponder];
        
        if ([nextResponder isKindOfClass:[UIViewController class]])
            result = nextResponder;
        else
            result = window.rootViewController;
        
        _currentVC = result;
        //    _currentVC = [TopVC shared].top;
    }
    
    return _currentVC;
}

// 得到可复用视图
- (CQAssetsDisplayCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier {
    
    CQAssetsDisplayCell *cell;
    
    AssetsDisplayCells *_prepareShowCellByFilter = [_prepareShowCells filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"reuseIdentifier MATCHES %@", identifier]];
    
    if (_prepareShowCellByFilter.count == 0) {
        
        return nil;
    }else {
        
        cell = [_prepareShowCellByFilter firstObject];
        [_prepareShowCells removeObject:cell];
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
    
    AssetsDisplayCells *currentShowCellByFilter = [_alreadyShowCells filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"index == %d", _currentPage]];
    if (currentShowCellByFilter.count > 0) {
        return currentShowCellByFilter[0];
    }
    return nil;
}

// MARK: - 处理左右滑动

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGPoint centerPoint = CGPointMake(scrollView.frame.size.width/2, scrollView.frame.size.height/2);
    CGPoint point = [self.view convertPoint:centerPoint toView:self.scrollView];
    for (CQAssetsDisplayCell *cell in _alreadyShowCells) {
        if (CGRectContainsPoint(cell.frame, point) && cell.index != _currentPage) {
            
            _isFromScrollViewDidScroll = YES;
            NSInteger tpage = (int)scrollView.contentOffset.x/(int)scrollView.frame.size.width;
            if (tpage == _currentPage) {
                break;
            }
            self.currentPage = tpage;
            break;
        }
    }
}

// 设置当前页
- (void)setCurrentPage:(NSInteger)currentPage {
    
    // 延迟设置
    if (!_scrollView) {
        
        __weak typeof(self) weakSelf = self;
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
        
        [self changeAssetViewToInitialState:self.currentCell];
        _currentPage = currentPage;
        
        [self setCellForIndex:_currentPage];
        
        // 设置右边的视图
        if (currentPage + 1 < self.numberOfCells) {
            [self setCellForIndex:currentPage + 1];
        }
        
        // 设置左边的视图
        if (currentPage > 0) {
            [self setCellForIndex:currentPage - 1];
        }
        
        // 滑动到当前页
        [self scrollToCurrentPage];
    }
}

// 滑动到当前页
- (void)scrollToCurrentPage {
    
    if (_isFromScrollViewDidScroll) {
        _isFromScrollViewDidScroll = NO;
        return;
    }
    
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
            
            // 移除占位图
            UIView *leftView = [_leftPlaceholdViewDic objectForKey:[NSString stringWithFormat:@"%d",cell.index]];
            [leftView removeFromSuperview];
            [_leftPlaceholdViewDic removeObjectForKey:[NSString stringWithFormat:@"%d",cell.index]];
            // 移除内容视图
            [cell.contentView removeFromSuperview];
            // 移除进度
            [cell.progressView removeFromSuperview];
            // 增加重用
            [_prepareShowCells addObject:cell];
        }
    }
    // 移除显示
    [_alreadyShowCells removeObjectsInArray:tempArray];
}

// 创建占位图
- (UIView *)createCellLeftPlaceholderView:(NSInteger) index {
    
    UIView *leftView = [_leftPlaceholdViewDic objectForKey:[NSString stringWithFormat:@"%d",index]];
    
    if (!leftView) {
        
        leftView = [UIView new];
        leftView.backgroundColor = [UIColor clearColor];
        [_scrollViewContentView insertSubview:leftView atIndex:0];
        [_leftPlaceholdViewDic setObject:leftView forKey:[NSString stringWithFormat:@"%d",index]];
        
        leftView.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(leftView);
        [_scrollViewContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[leftView]-0-|" options:0 metrics:nil views:views]];
        [_scrollViewContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[leftView]" options:0 metrics:nil views:views]];
        
        [_scrollView addConstraint:[NSLayoutConstraint constraintWithItem:leftView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_scrollView attribute:NSLayoutAttributeWidth multiplier:index constant:0]];
        
    }
    return leftView;
}

// 设置cell
- (CQAssetsDisplayCell * )setCellForIndex:(NSInteger)index {
    
    // 已经设置过
    AssetsDisplayCells *exists = [_alreadyShowCells filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"index == %d", index]];
    if (exists.count!=0) {
        return exists[0];
    }
    
    // 设置重用
    [self removeCellToReUse];
    
    // 获取cell
    CQAssetsDisplayCell *cell;
    if ([_dataSource respondsToSelector:@selector(assetsDisplayController:cellForIndex:)]) {
        
        cell = [_dataSource assetsDisplayController:self cellForIndex:index];
    }
    if (cell == nil)
        return nil;
    
    // 设置索引
    cell.index = index;
    cell.delegate = self;
    
    // 增加cell
    [_scrollViewContentView addSubview:cell];
    [_alreadyShowCells addObject:cell];
    
    // 更新图片大小
    cell.frame = CGRectMake(self.scrollViewContentView.frame.size.width/self.numberOfCells*index, 0, self.scrollViewContentView.frame.size.width/self.numberOfCells, self.scrollViewContentView.frame.size.height);
    [cell fix];
    
    // cell约束
    cell.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(cell);
    [_scrollViewContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[cell]-0-|" options:0 metrics:nil views:views]];
    [_scrollView addConstraint:[NSLayoutConstraint constraintWithItem:cell attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_scrollView attribute:NSLayoutAttributeWidth multiplier:1 constant:-_cellPadding]];
    
    // 获得占位，然后设置cell的左边约束
    UIView *leftView = [self createCellLeftPlaceholderView:index];
    [_scrollViewContentView addConstraint:[NSLayoutConstraint constraintWithItem:cell attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:leftView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    
    // 设置内容视图
    UIView *contentView = [UIView new];
    contentView.userInteractionEnabled = NO;
    [_scrollViewContentView addSubview:contentView];
    cell.contentView = contentView;
    
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    contentView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.3];
    views = NSDictionaryOfVariableBindings(contentView);
    [_scrollViewContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[contentView]-0-|" options:0 metrics:nil views:views]];
    [_scrollView addConstraint:[NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_scrollView attribute:NSLayoutAttributeWidth multiplier:1 constant:-_cellPadding]];
    [_scrollViewContentView addConstraint:[NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:leftView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    
    // 设置进度
    ESPictureProgressView *progressView = [[ESPictureProgressView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    progressView.userInteractionEnabled = NO;
    progressView.progress = 0.5;
    [_scrollViewContentView addSubview:progressView];
    cell.progressView = progressView;
    
    progressView.translatesAutoresizingMaskIntoConstraints = NO;
    [_scrollViewContentView addConstraint:[NSLayoutConstraint constraintWithItem:progressView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [_scrollViewContentView addConstraint:[NSLayoutConstraint constraintWithItem:progressView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    [_scrollViewContentView addConstraint:[NSLayoutConstraint constraintWithItem:progressView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1 constant:40]];
    [_scrollViewContentView addConstraint:[NSLayoutConstraint constraintWithItem:progressView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1 constant:40]];
    
    
    return nil;
}

#pragma mark - 处理缩放

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if (![scrollView isKindOfClass:[CQAssetsDisplayCell class]])
        return nil;
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

// 恢复没有缩放
- (void)changeAssetViewToInitialState:(CQAssetsDisplayCell *)assetsDisplayCell {
    
    if (assetsDisplayCell.zoomScale >= 1 + FLT_EPSILON) {
        assetsDisplayCell.scrollEnabled = NO;
        [assetsDisplayCell setZoomScale:1.0 animated:NO];
        assetsDisplayCell.scrollEnabled = YES;
    }
}

@end
