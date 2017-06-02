//
//  CQCustomAssetsDisplayCell.m
//  CQAssetsDisplay
//
//  Created by 陈长青 on 2017/6/2.
//  Copyright © 2017年 chenchangqing198@126.com. All rights reserved.
//

#import "CQCustomAssetsDisplayCell.h"

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
    
    UILabel *pageLabel = [UILabel new];
    pageLabel.textAlignment = NSTextAlignmentCenter;
    pageLabel.textColor = [UIColor whiteColor];
    pageLabel.font = [UIFont systemFontOfSize:12];
    pageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:pageLabel];
    _pageLabel = pageLabel;
    
    views = NSDictionaryOfVariableBindings(pageLabel);
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[pageLabel(44)]" options:0 metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-100-[pageLabel]-100-|" options:0 metrics:nil views:views]];
}

@end
