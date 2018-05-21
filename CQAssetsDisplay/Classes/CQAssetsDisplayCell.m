//
//  CQAssetsDisplayCell.m
//  Pods
//
//  Created by 陈长青 on 2017/5/10.
//
//

#import "CQAssetsDisplayCell.h"
#import "CQAssetsDisplayCellPrivate.h"
#import "MCDownloadManager.h"
#import <YYWebImage/YYWebImage.h>
#import "NSTimer+Additions.h"
#import <CQVRPlayer/CQScene.h>
#import <CQVRPlayer/CQSphere.h>
#import <CQVRPlayer/CQPlane.h>

@interface CQAssetsDisplayCell ()<CQVideoPlayerDelegate,CQVideoControlViewDelegate,CQVideoControlViewDataSource>

@property (strong, nonatomic) UIView *fixView;
@property (strong, nonatomic) NSTimer *timer;// 计时器
@property (weak, nonatomic) UIPanGestureRecognizer *panGesture;

@end

@implementation CQAssetsDisplayCell

#pragma mark - 生命周期

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [self initWithFrame:CGRectZero];
    if (self) {
        
        _reuseIdentifier = reuseIdentifier;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor blackColor];
        self.pagingEnabled = NO;
        self.delaysContentTouches = YES;
        self.canCancelContentTouches = YES;
        self.bounces = YES;
        self.bouncesZoom = YES;
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        
        // 添加 imageView
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.clipsToBounds = true;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.userInteractionEnabled = true;
        imageView.backgroundColor = [UIColor clearColor];
        [self addSubview:imageView];
        _imageView = imageView;
        
        // 增加kvo
        [_imageView addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc {
//    [self free];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (_imageView.image) {
        
        [self layoutImageView:self.bounds.size];
    }
}

- (void)setImageUrl:(NSString *)remoteUrl andPlaceHolder:(UIImage *)placeHolder {
    
    _imageURL = remoteUrl;
    _placeHolder = placeHolder;
}

- (void)setVideoUrl:(NSString *)videoUrl {
    _videoUrl = videoUrl;
}

- (void)setLocalVideoUrl:(NSURL *)localVideoUrl {
    _localVidUrl = localVideoUrl;
}

- (void)fix {
    
    _fixView = [UIView new];
    [self addSubview:_fixView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 更新图片布局
    if (_fixView) {
        [_fixView removeFromSuperview];
        _fixView = nil;
        [self layoutImageView:self.bounds.size];
    }
}

- (void)layoutImageView:(CGSize)size {
    
    if (!_imageView.image) {
        return;
    }
    
    CGSize _imageSize = _imageView.image.size;
    
    //竖屏状态
    if (size.width < size.height) {
        _imageSize = CGSizeMake(size.width, size.width/_imageSize.width * _imageSize.height);
        CGFloat _y = (size.height > _imageSize.height) ? (size.height - _imageSize.height)/2 : 0;
        _imageView.frame = CGRectMake(0, _y, size.width, _imageSize.height);
        
    }else {
        _imageSize = CGSizeMake(_imageSize.width *size.height / _imageSize.height ,size.height);
        
        //太窄了，显示为一个超细条，此处给它加宽到SCREEN_WIDTH
        if (_imageSize.width < size.width/10) {
            _imageSize = CGSizeMake(size.width ,size.width/_imageSize.width *_imageSize.height);
            CGFloat _x = (size.width - _imageSize.width) / 2;
            _imageView.frame = CGRectMake(_x, 0, _imageSize.width, _imageSize.height);
            
            //完全在这个范围内，刚刚好
        }else if (_imageSize.width <= size.width) {
            CGFloat _x = (size.width - _imageSize.width) / 2;
            _imageView.frame = CGRectMake(_x, 0, _imageSize.width, _imageSize.height);
            
            //太宽了，这是必须保证宽度合适
        }else {
            _imageSize = CGSizeMake(size.width, size.width/_imageSize.width * _imageSize.height);
            CGFloat _y = (size.height - _imageSize.height)/2;
            _imageView.frame = CGRectMake(0, _y, _imageSize.width, _imageSize.height);
        }
        
    }
    
    self.contentSize = _imageSize;
    
    //设置缩放范围
    self.minimumZoomScale = MinimumZoomScale;
    CGFloat scale1 = _imageSize.width < size.width ? (size.width / _imageSize.width) : 0;
    CGFloat scale2 = _imageSize.height < size.height ? (size.height / _imageSize.height) : 0;
    
    self.maximumZoomScale = MAX(MAX(scale1, scale2), MaximumZoomScale);
}

- (void)playVideo {
    
    if (!_videoUrl && !_localVidUrl) {
        return;
    }
    
    // 重置关闭按钮、toolbar
    _videoControlView.hidden = YES;
    _closeBtn.hidden = YES;
    _sceneTypeSeg.hidden = YES;
    
    _videoPlayer = [self vrRenderView:_videoPlayerView playerForSceneAtIndex:_index];
    _videoPlayer.delegate = self;
    [_videoPlayer play];
    
    [self setupGesture];
}

// 单击事件
- (void)toggleControls {
    
    _videoControlView.hidden = !_videoControlView.hidden;
    _closeBtn.hidden = !_closeBtn.hidden;
    _sceneTypeSeg.hidden = !_sceneTypeSeg.hidden;
}

- (void)resetTimer {
    [self.timer invalidate];
    self.timer = nil;
    if (!self.videoControlView.scrubbing) {
        __weak typeof(self) weakSelf = self;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:3.0 firing:^{
            if (weakSelf.timer.isValid && !_videoControlView.hidden) {
                [weakSelf toggleControls];
            }
        }];
    }
}

- (void)removeFromSuperview {
    [self free];
    [super removeFromSuperview];
}

- (UIView *)contentView {
    
    if (!_contentView) {
        _contentView = [UIView new];
    }
    return _contentView;
}

- (void)setupGesture {
    if (_sceneTypeSeg.selectedSegmentIndex != 2) {
        if (!_panGesture) {
            UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
            [_contentView addGestureRecognizer:panGesture];
            _panGesture = panGesture;
        }
    }
}

- (void)removeGesture {
    [_contentView removeGestureRecognizer:_panGesture];
}

- (void)panGesture:(UIPanGestureRecognizer *) panGesture {
    
    CGPoint currentPoint = [panGesture locationInView:panGesture.view];
    
    switch (panGesture.state) {
        case UIGestureRecognizerStateEnded: {
            
            break;
        }
        case UIGestureRecognizerStateBegan: {
            
            _videoPlayerView.velocityValue = NSStringFromCGPoint(CGPointZero);
            break;
        }
        case UIGestureRecognizerStateChanged: {
            
            // 改变 yaw、pitch
            _videoPlayerView.velocityValue = NSStringFromCGPoint([panGesture velocityInView:panGesture.view]);
            break;
        }
        default:
            break;
    }
}

- (void)selectedPlaneSceneType {
    CQScene *currentScene = [self vrRenderView:_videoPlayerView sceneAtIndex:0];
    currentScene.sceneType = CQSceneTypePlane;
    if (_videoPlayer.isPaused) {
        self.hidden = YES;
    } else {
        if (_videoPlayer.isPlaying) {
            self.hidden = YES;
        } else {
            self.hidden = NO;
        }
    }
    [self removeGesture];
}

- (void)selectedHalSphereSceneType {
    CQScene *currentScene = [self vrRenderView:_videoPlayerView sceneAtIndex:0];
    currentScene.sceneType = CQSceneTypeHalSphere;
    if (_videoPlayer.isPaused) {
        self.hidden = YES;
        [self setupGesture];
    } else {
        if (_videoPlayer.isPlaying) {
            self.hidden = YES;
            [self setupGesture];
        } else {
            self.hidden = NO;
            [self removeGesture];
        }
    }
}

- (void)selectedSphereSceneType {
    CQScene *currentScene = [self vrRenderView:_videoPlayerView sceneAtIndex:0];
    currentScene.sceneType = CQSceneTypeSphere;
    if (_videoPlayer.isPaused) {
        self.hidden = YES;
        [self setupGesture];
    } else {
        if (_videoPlayer.isPlaying) {
            self.hidden = YES;
            [self setupGesture];
        } else {
            self.hidden = NO;
            [self removeGesture];
        }
    }
}

// MARK: - CQVideoPlayerDelegate

- (void)videoPlayerWillLoadAsset:(CQVideoPlayer *)videoPlayer// 准备资源（开始loading)
{
    _videoPlayBtn.hidden = YES;
    _progressView.hidden = NO;
    _progressView.progress = 0.01;
}
- (void)videoPlayerLoadingAsset:(CQVideoPlayer *)videoPlayer withProgress:(double)progress// 下载进度（更新下载进度）
{
    _progressView.progress = progress ;
}
- (void)videoPlayerDidLoadAsset:(CQVideoPlayer *)videoPlayer andSuccess:(BOOL)success// 准备播放（开始设置avPlayer）
{
    if (success) {
        
//        [_videoPlayerView setAVPlayer:videoPlayer.avPlayer];
    } else {
        [self videoPlayerDidPlay:videoPlayer andSuccess:NO];
    }
}

- (void)videoPlayerWillPlay:(CQVideoPlayer *)videoPlayer// 将要播放
{
    [self.videoControlView setToPlaying:YES];
}

- (void)videoPlayerPreparePlay:(CQVideoPlayer *)videoPlayer// 成功播放（隐藏图片）
{
    self.hidden = YES;
    _videoPlayBtn.hidden = YES;
    _progressView.hidden = YES;
    _progressView.progress = 1;
    
}

- (void)videoPlayerPlaying:(CQVideoPlayer *)videoPlayer andCurrentTime:(NSTimeInterval)time duratoin:(NSTimeInterval)duration {
    [self.videoControlView setCurrentTime:time duration:duration];
}

- (void)videoPlayerPause:(CQVideoPlayer *)videoPlayer {
    [self.videoControlView setToPlaying:NO];
}

- (void)videoPlayerStop:(CQVideoPlayer *)videoPlayer {
    [self suspendDownload];
    self.progressView.hidden = YES;
    self.hidden = NO;
    if (self.videoUrl || self.localVidUrl) {// 避免播放显示错误(复用回调)
        
        _videoPlayBtn.hidden = NO;
    } else {
        
        _videoPlayBtn.hidden = YES;
    }
}

- (void)videoPlayerDidPlay:(CQVideoPlayer *)videoPlayer andSuccess:(BOOL)success
{
    if (success) {
        
        self.hidden = NO;
        if (self.videoUrl||self.localVidUrl) {// 避免播放显示错误(复用回调)
            
            _videoPlayBtn.hidden = NO;
        } else {
            
            _videoPlayBtn.hidden = YES;
        }
    } else {
        
        [_progressView showError];
    }
    [self removeGesture];
}
- (void)videoPlayerGetVideoURL:(id<CQVideoPlayerProtocol>)videoPlayer andCompletion:(void (^)(NSURL *))completion withProgress:(void (^)(double))progress {
    
    if (_localVidUrl) {
        completion(_localVidUrl);
        return;
    }
    
    NSString *downloadURL = self.videoUrl;
    MCDownloadReceipt *receipt = [[MCDownloadManager defaultInstance] downloadReceiptForURL:downloadURL];
    
    if (receipt.state == MCDownloadStateDownloading) {// 正在下载
        
    } else if (receipt.state == MCDownloadStateCompleted) {// 已经下载完成
        if (receipt.filePath) {
            NSURL *localFileUrl = [NSURL fileURLWithPath:receipt.filePath];
            completion(localFileUrl);
        }else{
            completion(nil);
        }
    } else {// 开始下载
        
        __weak typeof(self) weakSelf = self;
        [weakSelf startDownload:downloadURL success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSURL * _Nonnull filePath) {
            if (receipt.filePath) {
                completion([NSURL fileURLWithPath:receipt.filePath]);
            }else{
                completion(nil);
            }
            //            [[NSNotificationCenter defaultCenter] postNotificationName:MWVIDEO_LOADING_DID_END_NOTIFICATION object:nil];
        } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
            completion(nil);
        } progress:^(NSProgress * _Nonnull downloadProgress, MCDownloadReceipt *receipt) {
            
            if ([receipt.url isEqualToString:downloadURL]) {
                if (progress) {
                    progress(downloadProgress.fractionCompleted);
                }
                NSLog(@"下载速度==%@/s,下载进度==%.2f,已下载/总大小==%0.2fm/%0.2fm",
                      receipt.speed,
                      downloadProgress.fractionCompleted,
                      downloadProgress.completedUnitCount/1024.0/1024,
                      downloadProgress.totalUnitCount/1024.0/1024);
            }
        }];
    }
}

// MARK: - 下载

// 开始下载
- (void)startDownload:(NSString *)downloadURL success:(MCSucessBlock) successBlock failure:(MCFailureBlock) failureBlock progress:(MCProgressBlock) progressBlock{
    
    MCDownloadReceipt *receipt = [[MCDownloadManager defaultInstance] downloadReceiptForURL:downloadURL];
    
    if (receipt.state != MCDownloadStateDownloading
        && receipt.state != MCDownloadStateCompleted) {
        
        [[MCDownloadManager defaultInstance] downloadFileWithURL:downloadURL
                                                        progress:progressBlock
                                                     destination:nil
                                                         success:successBlock
                                                         failure:failureBlock];
    }
}

// 暂停下载
- (void)suspendDownload {
    
    
    NSString *downloadURL = self.videoUrl;
    if (downloadURL) {
        
        MCDownloadReceipt *receipt = [[MCDownloadManager defaultInstance] downloadReceiptForURL:downloadURL];
        if (receipt.state == MCDownloadStateDownloading) {
            [[MCDownloadManager defaultInstance] suspendWithDownloadReceipt:receipt];
        }
    }
}

// MARK: -

- (void)loadImageDataWithCompletion:(void (^)(BOOL))callback {
    
    NSString *imageURLStr = self.imageURL;
    UIImage *placeHolder = self.placeHolder;
    UIImageView *imageView = self.imageView;
    if (placeHolder) {
        imageView.image = placeHolder;
    }
    if (imageURLStr) {
        
        self.videoPlayBtn.hidden = YES;
        self.progressView.hidden = NO;
        self.progressView.progress = 0.01;
        NSURL *imageURL = [[NSURL alloc] initWithString:imageURLStr];
        __weak typeof(self) weakSelf = self;
        [imageView yy_setImageWithURL:imageURL placeholder:placeHolder options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            
            weakSelf.progressView.progress = (CGFloat)receivedSize / expectedSize ;
        } transform:nil completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
            
            if (error) {
                callback(NO);
                [weakSelf.progressView showError];
            } else {
                
                if (stage == YYWebImageStageFinished) {
                    
                    if (image != nil) {
                        weakSelf.progressView.progress = 1;
                        weakSelf.progressView.hidden = YES;
                        callback(YES);
                    } else {
                        callback(NO);
                    }
                } else {
                    callback(NO);
                }
            }
        }];
    } else {
        callback(NO);
    }
}

- (void)setHidePlayerIconWithLoadImageOk:(BOOL)loadImageOK andIndex:(NSInteger)page{
    
    // 解决复用问题
    if (page != _index) {
        return;
    }
    
    BOOL videoPlayBtnHidden = (self.videoUrl != nil || self.localVidUrl != nil) ? NO : YES;
    if (videoPlayBtnHidden) {
        
        if (loadImageOK) {
            self.progressView.hidden = YES;
        } else {
            if (_imageURL) {
                [self.progressView showError];
                self.progressView.hidden = NO;
            } else {
                self.progressView.hidden = YES;
            }
        }
        
        self.videoPlayBtn.hidden = YES;
    } else {
        
        self.progressView.progress = 0.01;
        self.progressView.hidden = YES;
        self.videoPlayBtn.hidden = NO;
    }
}

// 变为重用
- (void)changeToReuse {
    
    [self.imageView yy_cancelCurrentImageRequest];
    self.imageView.image = nil;
    [_videoPlayer free];
    self.videoPlayBtn.hidden = YES;
    self.progressView.hidden = YES;
    self.closeBtn.hidden = YES;
    self.sceneTypeSeg.hidden = YES;
    self.videoControlView.hidden = YES;
    [self suspendDownload];
    [self setVideoUrl:nil];
    [self setLocalVideoUrl:nil];
    [self setImageURL:nil];
    [self vrRenderView:_videoPlayerView sceneAtIndex:0].sceneType = CQSceneTypePlane;
    _sceneTypeSeg.selectedSegmentIndex = 2;
    _videoPlayerView.userInteractionEnabled = NO;
}
// 恢复没有缩放
- (void)changeAssetViewToInitialState {
    
    if (self.zoomScale >= 1 + FLT_EPSILON) {
        self.scrollEnabled = NO;
        [self setZoomScale:1.0 animated:NO];
        self.scrollEnabled = YES;
    }
    
    if (self.videoPlayer) {
        
        [self.videoPlayer stop];
    }
    self.closeBtn.hidden = YES;
    self.sceneTypeSeg.hidden = YES;
    self.videoControlView.hidden = YES;
}
// 释放
- (void)free {
    
    [self suspendDownload];
    [self.imageView yy_cancelCurrentImageRequest];
    
    [_imageView removeObserver:self forKeyPath:@"image"];
    
    [_placeView removeFromSuperview];
    _placeView = nil;
    
    [_progressView removeFromSuperview];
    _progressView = nil;
    
    [_videoPlayer free];
    _videoPlayer = nil;
    
    [_videoPlayerView removeFromSuperview];
    _videoPlayerView = nil;
    
    [_videoPlayBtn removeFromSuperview];
    _videoPlayBtn = nil;
    
    [_contentView removeFromSuperview];
    _contentView = nil;
    
    [_videoControlView removeFromSuperview];
    _videoControlView = nil;
    
    [self.timer invalidate];
    self.timer = nil;
}

// MARK: - CQVideoControlViewDelegate

- (void)play// 播放
{
    [self.videoPlayer play];
}
- (void)pause// 暂停
{
    [self.videoPlayer pause];
}
- (void)scrubbingDidStart// 开始滑动进度条
{
    [self resetTimer];
    [self.videoPlayer scrubbingDidStart];
}
- (void)scrubbedToTime:(NSTimeInterval)time// 正在滑动进度条
{
    [self.videoPlayer scrubbedToTime:time];
}
- (void)scrubbingDidEnd// 结束滑动进度条
{
    [self resetTimer];
    [self.videoPlayer scrubbingDidEnd];
}

// MARK: - CQVideoControlViewDataSource

- (BOOL)isDidLoadAssetSuccess// 是否成功加载资源
{
    return [self.videoPlayer isDidLoadAssetSuccess];
}

- (BOOL)getIsHorizontalScreenDirection {
    return YES;
}



#pragma mark - CQVRRenderViewDelegate

- (void)vrRenderView:(id<CQVRRenderViewProtocol>)vrRenderView didDisplayingScene:(CQScene *)scene forSceneIndex:(NSInteger)sceneIndex {
    
    // 更新控制UI
    CQScene *currentScene = [self vrRenderView:vrRenderView sceneAtIndex:vrRenderView.currentSceneIndex];
    [_videoControlView selectedZhongliBtn:currentScene.gyroscopeEnabled];
    [_videoControlView selectedHalfScreenBtn:currentScene.duralScreenEnabled];
    if (currentScene.sceneType == CQSceneTypeSphere) {
        [_videoControlView selectedSphereSceneType];
    }
    if (currentScene.sceneType == CQSceneTypeHalSphere) {
        [_videoControlView selectedHalSphereSceneType];
    }
    if (currentScene.sceneType == CQSceneTypePlane) {
        [_videoControlView selectedPlaneSceneType];
    }
    
    // 更新当前播放器控制界面
    [_videoControlView setToPlaying:NO];
    [_videoControlView setCurrentTime:0 duration:0];
    [_videoControlView setTitle:nil];
    
    id<CQVideoPlayerProtocol> player = [self vrRenderView:vrRenderView playerForSceneAtIndex:sceneIndex];
    if (player) {
        player.delegate = self;
        if (player.willChangeStatus == CQVPWillChangeStatusPlaying) {
            [player play];
        }
        [_videoControlView setTitle:player.videoTitle];
        [_videoControlView setCurrentTime:player.currentTime duration:player.totalDuration];
    }
}

#pragma mark - CQVRRenderViewDataSource

- (NSInteger)numberOfScenesInVRPlayer:(CQVRRenderView *)vrRenderView {
    
    if (_videoUrl || _localVidUrl) {
        return 1;
    }
    return 1;
}

- (NSInteger)vrRenderView:(CQVRRenderView *)vrRenderView numberOfModelsInScene:(NSInteger)sceneIndex {
    
    if (_videoUrl || _localVidUrl) {
        return 2;
    }
    return 0;
}

- (CQScene *)vrRenderView:(CQVRRenderView *)vrRenderView sceneAtIndex:(NSInteger)sceneIndex {
    
    NSString *identifier = [NSString stringWithFormat:@"scene%ld",(long)sceneIndex];
    if (sceneIndex == 0) {
        CQScene *scene = (CQScene *)[vrRenderView dequeueReusableSceneWithIdentifier:identifier];
        if (scene == nil) {
            scene = [[CQScene alloc] initWithReuseIdentifier:identifier];
            scene.sceneType = CQSceneTypePlane;
            scene.backgroundImg = self.placeHolder;
        }
        return scene;
    }
    return nil;
}

- (CQModel *)vrRenderView:(CQVRRenderView *)vrRenderView modelForSceneAtIndex:(NSIndexPath *)indexPath {

    return nil;
}

//返回播放器

- (id<CQVideoPlayerProtocol>)vrRenderView:(id<CQVRRenderViewProtocol>)vrRenderView playerForSceneAtIndex:(NSInteger)sceneIndex {
    NSString *identifier = [NSString stringWithFormat:@"player%ld",_index];
    id<CQVideoPlayerProtocol> player = [vrRenderView dequeueReusablePlayerWithIdentifier:identifier];
    if (sceneIndex == 0) {
        if (player == nil) {
            player = [[CQVideoPlayer alloc] initWithReuseIdentifier:identifier];
            player.remoteVidUrlStr = _videoUrl;
            player.localVidUrl = _localVidUrl;
            player.willChangeStatus = CQVPWillChangeStatusPause;// 这句话会影响播放器按钮显示
        }
    }
    return player;
}

@end
