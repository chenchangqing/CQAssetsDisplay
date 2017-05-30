//
//  CQAssetsDisplayCellPrivate.h
//  Pods
//
//  Created by 陈长青 on 2017/5/30.
//
//

#ifndef CQAssetsDisplayCellPrivate_h
#define CQAssetsDisplayCellPrivate_h

@interface CQAssetsDisplayCell ()

@property (weak, nonatomic) CQAssetsDisplayItem *item;
@property (nonatomic, weak) UIImageView   *imageView;
@property (copy, nonatomic) NSString *videoUrl;
@property (copy, nonatomic) NSString *imageURL;
@property (strong, nonatomic) UIImage *placeHolder;

@end

#endif /* CQAssetsDisplayCellPrivate_h */
