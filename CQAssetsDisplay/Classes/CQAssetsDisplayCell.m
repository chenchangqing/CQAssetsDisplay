//
//  CQAssetsDisplayCell.m
//  Pods
//
//  Created by 陈长青 on 2017/5/10.
//
//

#import "CQAssetsDisplayCell.h"

@interface CQAssetsDisplayCell ()

@property (strong, nonatomic) UIView *fixView;

@end

@implementation CQAssetsDisplayCell
@synthesize imageView = _imageView;
@synthesize textLabel = _textLabel;

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
    }
    return self;
}

- (UILabel *)textLabel {
    
    if (!_textLabel) {
        
        UILabel *textLabel = [UILabel new];
        textLabel.textAlignment = NSTextAlignmentCenter;
        textLabel.font = [UIFont systemFontOfSize:12];
        textLabel.textColor = [UIColor redColor];
        [self addSubview:textLabel];
        _textLabel = textLabel;
        
        _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_textLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_textLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        
    }
    return _textLabel;
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
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self layoutImageView:frame.size];
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

@end
