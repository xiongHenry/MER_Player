//
//  MER_PlayerView.h
//  MER_Player
//
//  Created by 汉子MacBook－Pro on 16/9/20.
//  Copyright © 2016年 不会爬树的熊. All rights reserved.
//

#import <UIKit/UIKit.h>

#define ZFPlayerDeprecated(instead)         DEPRECATED_MSG_ATTRIBUTE(" Use " # instead " instead")

///平移手势的方向
typedef NS_ENUM(NSInteger, PanDirection) {
    Pan_SlideHorizontally, //水平滑动
    Pan_SlideVertically    //垂直滑动
};

@class MER_PlayerControllerView,MER_PlayModel;
@interface MER_PlayerView : UIView
/** 控制的视图 */
@property (nonatomic, strong) MER_PlayerControllerView *controlView;
/** 返回按钮回调 */
@property (nonatomic, copy) void (^backCallBack)();
/** 视频url */
@property (nonatomic, copy) NSString *videoURL;
/** 视频url数组 */
@property (nonatomic, strong) NSArray *VideoURLs;
/** 当前播放的model */
@property (nonatomic, strong) MER_PlayModel *currentModel;

- (instancetype)initWithVideoURLs:(NSArray *)videoURLs;
- (instancetype)initWithURL:(NSString *)URL;
+ (instancetype)mer_setControlView:(MER_PlayerControllerView *)controlView videoURLs:(NSArray *)videoURLs;

///切换播放源
- (void)replacePlay:(MER_PlayModel *)model;

@end
