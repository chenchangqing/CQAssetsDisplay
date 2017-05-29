//
//  CQViewController.m
//  CQAssetsDisplay
//
//  Created by chenchangqing198@126.com on 05/16/2017.
//  Copyright (c) 2017 chenchangqing198@126.com. All rights reserved.
//

#import "CQViewController.h"
#import "CQCollectionViewCell.h"
#import "CQAssetsDisplayController.h"
#import <YYWebImage/YYWebImage.h>

#define kAlbumY                  64                                         // 相册上边距
#define kAlbumW                  CGRectGetWidth(self.view.bounds)           // 相册宽度
#define kAlbumH                  CGRectGetHeight(self.view.bounds)-kAlbumY  // 相册高度
#define kAlbumCell               @"albumCell"                               // 重用cell key
#define kAlbumCellW              (kAlbumW - 20) / 3                         // cell宽度
#define kAlbumCellRowSpacing     5                                          // 行间距
#define kAlbumCellColumnSpacing  5                                          // 列间距
#define kAlbumSectionSpacing     5                                          // 节外边距
#define kAlbumPlistName          @"album.plist"                             // 图片数组
#define kAssetsDisplayCell       @"assetsDisplayCell"                       // 图片浏览器cell key

@interface CQViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,CQAssetsDisplayControllerDataSource>

@property (weak, nonatomic) UICollectionView *album;
@property (strong, nonatomic) NSArray *albumArray;

@end

@implementation CQViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
	
    // 相册
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc]init];
    
    flowLayout.minimumInteritemSpacing  = kAlbumCellRowSpacing;
    flowLayout.minimumLineSpacing       = kAlbumCellColumnSpacing;
    flowLayout.itemSize                 = (CGSize){kAlbumCellW,kAlbumCellW};
    flowLayout.sectionInset             = UIEdgeInsetsMake(kAlbumSectionSpacing, kAlbumSectionSpacing, kAlbumSectionSpacing, kAlbumSectionSpacing);
    flowLayout.scrollDirection          = UICollectionViewScrollDirectionVertical;
    
    UICollectionView *album = [[UICollectionView alloc]initWithFrame:CGRectMake(0, kAlbumY, kAlbumW, kAlbumH)
                                                collectionViewLayout:flowLayout];
    album.delegate = self;
    album.dataSource = self;
    album.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:album];
    _album = album;
    
    // 重用cell
    [_album registerClass:[CQCollectionViewCell class] forCellWithReuseIdentifier:kAlbumCell];
    
    // 加载数据
    [self loadAlbumArray];
    
    // 清除缓存
    [self clearImagesCache];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

// 加载相册数据
- (void)loadAlbumArray {
    
    NSString *albumDataFilePath = [[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:kAlbumPlistName];
    NSArray *albumArray = [[NSArray alloc] initWithContentsOfFile:albumDataFilePath];
    _albumArray = albumArray;
    
}

// 清图片缓存
- (void)clearImagesCache {
    
    YYImageCache *cache = [YYWebImageManager sharedManager].cache;
    [cache.memoryCache removeAllObjects];
    [cache.diskCache removeAllObjects];
    
}

// MARK: - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _albumArray ? _albumArray.count : 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    CQCollectionViewCell *photoCell = [collectionView dequeueReusableCellWithReuseIdentifier:kAlbumCell forIndexPath:indexPath];
    
    photoCell.imageView.backgroundColor = [UIColor blackColor];
    
    NSString *photoStr = [_albumArray objectAtIndex:indexPath.row];
    NSURL *photoURL = [[NSURL alloc] initWithString:photoStr];
    
    [photoCell.imageView yy_cancelCurrentImageRequest];
    [photoCell.imageView yy_setImageWithURL:photoURL placeholder:nil];
    
    return photoCell;
}

// MARK: - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    // 清除缓存
//    [self clearImagesCache];
    
    CQCollectionViewCell *cell = (CQCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    CQAssetsDisplayController *assetsDisplayController = [[CQAssetsDisplayController alloc] init];
    assetsDisplayController.dataSource = self;
    [assetsDisplayController showWithFromView:cell andCellPadding:50 andCurrentPage:indexPath.row];
}

// MARK: - CQAssetsDisplayControllerDataSource

- (NSInteger)numberOfCellsInAssetsDisplayController:(CQAssetsDisplayController *)controller {
    
    return _albumArray ? _albumArray.count : 0;
}

- (CQAssetsDisplayCell *)assetsDisplayController:(CQAssetsDisplayController *)controller cellForIndex:(NSInteger)index {
    
    CQAssetsDisplayCell *cell = [controller dequeueReusableCellWithIdentifier:kAssetsDisplayCell];
    if (cell == nil) {
        
        cell = [[CQAssetsDisplayCell alloc] initWithReuseIdentifier:kAssetsDisplayCell];
    }
    
    NSString *photoStr = [_albumArray objectAtIndex:index];
    [cell setImageUrl:photoStr andPlaceHolder:nil];
    if (index == 1
        || index == 3
        || index == 5
        || index == 7
        || index == 11) {
        
        [cell setVideoUrl:@"http://olaxmae4w.bkt.clouddn.com/avthumb/mp4/dynamic/201705/Fi-C5_lnMmrIyCijc5tlwiZjRVbX.mp4"];
    } else {
        
        [cell setVideoUrl:nil];
    }
    
    return cell;
}

- (UIView *)getEndView:(CQAssetsDisplayController *)controller {
    
    CQCollectionViewCell *photoCell = (CQCollectionViewCell *)[_album cellForItemAtIndexPath:[NSIndexPath indexPathForRow:controller.currentPage inSection:0]];
    return photoCell;
}

@end
