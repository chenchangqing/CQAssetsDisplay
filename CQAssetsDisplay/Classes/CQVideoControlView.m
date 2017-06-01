//
//  CQVideoControlView.m
//  Pods
//
//  Created by 陈长青 on 2017/5/31.
//
//

#import "CQVideoControlView.h"

@interface CQVideoControlView()

@property (weak, nonatomic) UIImageView *bgView;// 背景图
@property (weak, nonatomic) UIButton *togglePlaybackButton;// 播放/暂停按钮
@property (weak, nonatomic) UISlider *scrubberSlider;// 播放进度
@property (weak, nonatomic) UILabel *timeLabel;// 当前时间／总时间

@end

@implementation CQVideoControlView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    
    UIImageView *bgView;// 背景图
    bgView = [UIImageView new];
    bgView.contentMode = UIViewContentModeScaleAspectFill;
    bgView.image = [self toolbarBgImage];
    bgView.translatesAutoresizingMaskIntoConstraints = NO;
    bgView.tintColor = [UIColor blackColor];
    [self addSubview:bgView];
    _bgView = bgView;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(bgView);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[bgView]-0-|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(-30)-[bgView]-0-|" options:0 metrics:nil views:views]];
    
    UIButton *togglePlaybackButton;// 播放/暂停按钮
    togglePlaybackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [togglePlaybackButton setImage:[self videoPlaySmallImage] forState:UIControlStateNormal];
    [togglePlaybackButton setImage:[self videoStopSmallImage] forState:UIControlStateSelected];
    togglePlaybackButton.translatesAutoresizingMaskIntoConstraints = NO;
    togglePlaybackButton.tintColor = [UIColor whiteColor];
    [self addSubview:togglePlaybackButton];
    _togglePlaybackButton = togglePlaybackButton;
    
    views = NSDictionaryOfVariableBindings(togglePlaybackButton);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(-15)-[togglePlaybackButton(80)]" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-6-[togglePlaybackButton]-8-|" options:0 metrics:nil views:views]];
    
    UISlider *scrubberSlider;// 播放进度
    scrubberSlider = [[UISlider alloc] init];
    scrubberSlider.minimumValue = 0;
    scrubberSlider.maximumValue = 1;
    scrubberSlider.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:scrubberSlider];
    _scrubberSlider = scrubberSlider;
    
    views = NSDictionaryOfVariableBindings(scrubberSlider,togglePlaybackButton);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[togglePlaybackButton]-0-[scrubberSlider]" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[scrubberSlider]-0-|" options:0 metrics:nil views:views]];
    
    UILabel *timeLabel;// 当前时间／总时间
    timeLabel = [UILabel new];
    timeLabel.textAlignment = NSTextAlignmentCenter;
    timeLabel.textColor = [UIColor whiteColor];
    timeLabel.font = [UIFont systemFontOfSize:10];
    timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    timeLabel.text = @"00:00/00:00";
    [self addSubview:timeLabel];
    _timeLabel = timeLabel;
    
    views = NSDictionaryOfVariableBindings(timeLabel,scrubberSlider);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[scrubberSlider]-21-[timeLabel(70)]-8-|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[timeLabel]-0-|" options:0 metrics:nil views:views]];
    
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

- (UIImage *)videoPlaySmallImage
{
    UIImage *arrowImage = nil;
    if (arrowImage == nil) {
        arrowImage = [[UIImage imageWithContentsOfFile:[[self assetsBundle] pathForResource:@"video_play_small@3x" ofType:@"png"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return arrowImage;
}

- (UIImage *)videoStopSmallImage
{
    UIImage *arrowImage = nil;
    if (arrowImage == nil) {
        arrowImage = [[UIImage imageWithContentsOfFile:[[self assetsBundle] pathForResource:@"video_stop_small@3x" ofType:@"png"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return arrowImage;
}

- (UIImage *)toolbarBgImage
{
    UIImage *arrowImage = nil;
    if (arrowImage == nil) {
        arrowImage = [[UIImage imageWithContentsOfFile:[[self assetsBundle] pathForResource:@"toolbar_bg" ofType:@"png"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return arrowImage;
}

@end
