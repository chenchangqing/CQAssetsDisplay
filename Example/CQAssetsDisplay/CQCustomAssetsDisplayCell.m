//
//  CQCustomAssetsDisplayCell.m
//  CQAssetsDisplay
//
//  Created by 陈长青 on 2017/6/2.
//  Copyright © 2017年 chenchangqing198@126.com. All rights reserved.
//

#import "CQCustomAssetsDisplayCell.h"

@interface CQCustomAssetsDisplayCell ()

@property (weak, nonatomic) UIView *navigationView;// 导航栏

@property (weak, nonatomic) UIButton *backBtn;// 返回按钮
@property (weak, nonatomic) UIButton *shareBtn;// 分享按钮
@property (weak, nonatomic) UIButton *downloadBtn;// 下载按钮
@property (weak, nonatomic) UIButton *zhuanfaBtn;// 转发按钮
@property (weak, nonatomic) UILabel *titleL;// 标题
@property (weak, nonatomic) UILabel *contentL;// 内容

@end

@implementation CQCustomAssetsDisplayCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    
    NSDictionary *views;
    
    UIView *navigationView;// 导航栏
    navigationView = [UIView new];
    navigationView.hidden = YES;
    navigationView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:navigationView];
    _navigationView = navigationView;
    
    views = NSDictionaryOfVariableBindings(navigationView);
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[navigationView(64)]" options:0 metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[navigationView]-0-|" options:0 metrics:nil views:views]];
    
    UIButton *backBtn;// 返回按钮
    backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [backBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    backBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [_navigationView addSubview:backBtn];
    _backBtn = backBtn;
    
    views = NSDictionaryOfVariableBindings(backBtn);
    [_navigationView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[backBtn]-0-|" options:0 metrics:nil views:views]];
    [_navigationView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[backBtn(50)]" options:0 metrics:nil views:views]];
    
    UIButton *zhuanfaBtn;// 转发按钮
    zhuanfaBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [zhuanfaBtn setImage:[UIImage imageNamed:@"zhuanfa"] forState:UIControlStateNormal];
    zhuanfaBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [_navigationView addSubview:zhuanfaBtn];
    _zhuanfaBtn = zhuanfaBtn;
    
    views = NSDictionaryOfVariableBindings(zhuanfaBtn);
    [_navigationView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[zhuanfaBtn]-0-|" options:0 metrics:nil views:views]];
    [_navigationView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[zhuanfaBtn(40)]-15-|" options:0 metrics:nil views:views]];
    
    UIButton *downloadBtn;// 下载按钮
    downloadBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [downloadBtn setImage:[UIImage imageNamed:@"download"] forState:UIControlStateNormal];
    downloadBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [_navigationView addSubview:downloadBtn];
    _downloadBtn = downloadBtn;
    
    views = NSDictionaryOfVariableBindings(downloadBtn,zhuanfaBtn);
    [_navigationView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[downloadBtn]-0-|" options:0 metrics:nil views:views]];
    [_navigationView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[downloadBtn(40)]-0-[zhuanfaBtn]" options:0 metrics:nil views:views]];
    
    UIButton *shareBtn;// 分享按钮
    shareBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [shareBtn setImage:[UIImage imageNamed:@"share"] forState:UIControlStateNormal];
    shareBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [shareBtn addTarget:self action:@selector(shareAction) forControlEvents:UIControlEventTouchUpInside];
    [_navigationView addSubview:shareBtn];
    _shareBtn = shareBtn;
    
    views = NSDictionaryOfVariableBindings(downloadBtn,shareBtn);
    [_navigationView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[shareBtn]-0-|" options:0 metrics:nil views:views]];
    [_navigationView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[shareBtn(40)]-0-[downloadBtn]" options:0 metrics:nil views:views]];
    
    UILabel *titleL;// 标题
    titleL = [UILabel new];
    titleL.textAlignment = NSTextAlignmentLeft;
    titleL.textColor = [UIColor whiteColor];
    titleL.font = [UIFont systemFontOfSize:14];
    titleL.text = @"titleL";
    titleL.translatesAutoresizingMaskIntoConstraints = NO;
    [_navigationView addSubview:titleL];
    _titleL = titleL;
    
    views = NSDictionaryOfVariableBindings(titleL,backBtn,shareBtn);
    [_navigationView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[titleL(22)]" options:0 metrics:nil views:views]];
    [_navigationView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[backBtn]-0-[titleL]-0-[shareBtn]" options:0 metrics:nil views:views]];
    
    UILabel *contentL;// 内容
    contentL = [UILabel new];
    contentL.textAlignment = NSTextAlignmentLeft;
    contentL.textColor = [UIColor whiteColor];
    contentL.font = [UIFont systemFontOfSize:12];
    contentL.translatesAutoresizingMaskIntoConstraints = NO;
    contentL.text = @"contentL";
    [_navigationView addSubview:contentL];
    _contentL = contentL;
    
    views = NSDictionaryOfVariableBindings(titleL,contentL,backBtn,shareBtn);
    [_navigationView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[titleL]-0-[contentL(22)]" options:0 metrics:nil views:views]];
    [_navigationView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[backBtn]-0-[contentL]-0-[shareBtn]" options:0 metrics:nil views:views]];
}

- (void)changeToReuse {
    [super changeToReuse];
    _navigationView.hidden = YES;
}

- (void)changeAssetViewToInitialState {
    [super changeAssetViewToInitialState];
    _navigationView.hidden = YES;
}

// 单击事件
- (void)toggleControls {
    [super toggleControls];
    _navigationView.hidden = !_navigationView.hidden;
}

// 播放
- (void)playVideo {
    [super playVideo];
    _navigationView.hidden = YES;
}

- (void)shareAction {
    NSLog(@"123shareAction");
}

@end
