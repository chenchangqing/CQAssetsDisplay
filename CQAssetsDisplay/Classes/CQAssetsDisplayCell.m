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

@interface CQAssetsDisplayCell ()<CQVideoPlayerDelegate>

@property (strong, nonatomic) UIView *fixView;

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
    
    if (_videoPlayer) {
        
        [_videoPlayer free];
        _videoPlayer = nil;
    }
    [self suspendDownload];
    [_imageView removeObserver:self forKeyPath:@"image"];
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
    
    //NSLog(@"%@", NSStringFromCGRect(self.frame));
}

// 更新图片布局
//- (void)setFrame:(CGRect)frame {
//    [super setFrame:frame];
//    [self layoutImageView:frame.size];
//}

- (void)layoutImageView:(CGSize)size {
    
//    NSLog(@"ImageViewSize:%@",NSStringFromCGSize(size));
    
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
    
    if (_videoPlayer) {
        
        [_videoPlayer free];
        _videoPlayer = nil;
    }
    
    _videoPlayer = [CQVideoPlayer new];
    _videoPlayer.delegate = self;
    [_videoPlayer play];
}

// MARK: - CQVideoPlayerDelegate

- (void)videoPlayerPrepareToLoadAsset:(CQVideoPlayer *)videoPlayer// 准备资源（开始loading)
{
    _videoPlayBtn.hidden = YES;
    _progressView.hidden = NO;
    _progressView.progress = 0.01;
}
- (void)videoPlayerProgressToLoadAsset:(CQVideoPlayer *)videoPlayer withProgress:(double)progress// 下载进度（更新下载进度）
{
    _progressView.progress = progress ;
}
- (void)videoPlayerPrepareToPlay:(CQVideoPlayer *)videoPlayer andAVPlayer:(AVPlayer *)avPlayer// 准备播放（开始设置avPlayer）
{
    [_videoPlayerView setAVPlayer:avPlayer];
}
- (void)videoPlayerSuccessToPlay:(CQVideoPlayer *)videoPlayer// 成功播放（隐藏图片）
{
    self.hidden = YES;
    _progressView.hidden = YES;
    _progressView.progress = 1;
    
}
- (void)videoPlayerFailureToPlay:(CQVideoPlayer *)videoPlayer// 失败播放（显示错误提示）
{
    [_progressView showError];
}
- (void)getVideoURL:(void (^)(NSURL *))completion withProgress:(void (^)(double))progress// 下载资源(实现先下载，后播放)
{
    
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

- (void)videoPlayerFinishToPlay:(CQVideoPlayer *)videoPlayer {
    
    self.hidden = NO;
    if (self.videoUrl) {// 避免播放显示错误
        
        _videoPlayBtn.hidden = NO;
    } else {
        
        _videoPlayBtn.hidden = YES;
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

@end
