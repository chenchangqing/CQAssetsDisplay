//
//  CQAssetsDisplayItem.m
//  Pods
//
//  Created by 陈长青 on 2017/5/24.
//
//

#import "CQAssetsDisplayItem.h"
#import "MCDownloadManager.h"

@interface CQAssetsDisplayItem ()<CQVideoPlayerDelegate>

@end

@implementation CQAssetsDisplayItem

// MARK: - CQVideoPlayerDelegate

- (void)videoPlayerPrepareToLoadAsset:(CQVideoPlayer *)videoPlayer// 准备资源（开始loading)
{
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
    _cell.hidden = YES;
    _progressView.hidden = YES;
    _progressView.progress = 1;
    
}
- (void)videoPlayerFailureToPlay:(CQVideoPlayer *)videoPlayer// 失败播放（显示错误提示）
{
    [_progressView showError];
}
- (void)getVideoURL:(void (^)(NSURL *))completion withProgress:(void (^)(double))progress// 下载资源(实现先下载，后播放)
{
    
    NSString *downloadURL = [_cell valueForKey:@"videoUrl"];
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
- (void)suspendDownload:(NSString *)downloadURL {
    
    MCDownloadReceipt *receipt = [[MCDownloadManager defaultInstance] downloadReceiptForURL:downloadURL];
    if (receipt.state == MCDownloadStateDownloading) {
        [[MCDownloadManager defaultInstance] suspendWithDownloadReceipt:receipt];
    }
}

@end
