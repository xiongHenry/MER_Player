//
//  MER_PlayerControlerView.h
//  MER_Player
//
//  Created by 汉子MacBook－Pro on 2016/11/23.
//  Copyright © 2016年 不会爬树的熊. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef NS_ENUM(NSInteger,FastDirection) {
    Fast_forward, //快进
    Fast_rewind   //快退
};

@class MER_PlayModel;
@interface MER_PlayerControllerView : UIView

/** 代理 */
@property (nonatomic, weak) id<MER_PlayerControlDelegate> delegate;
/** 返回按钮回调 */
@property (nonatomic, copy) void (^backCallBack)();
/** 列表数据源 */
@property (nonatomic, strong) NSArray *datas;

@property (nonatomic, assign) BOOL isHiddenTimeIndicatorView;

@property (nonatomic, assign) BOOL isHiddenVolumeIndicatorView;

@property (nonatomic, assign) BOOL isHiddenbrightnessIndicatorView;

///更新播放的时间信息
- (void)mer_updateControlCurrentTime:(NSInteger)currentTime totalTime:(NSInteger)totalTime sliderValue:(CGFloat)value;

///拖拽更新信息
- (void)mer_updateControlCurrentTime:(NSInteger)currentTime totalTime:(NSInteger)totalTime direction:(FastDirection)direction;

///显示覆盖层
- (void)showOverlay;

///隐藏覆盖层
- (void)hiddenOverlay;

///隐藏listview
- (void)hiddenListView;

///结束拖拽
- (void)endDrage;

///设置缓冲区域
- (void)setProgress:(CGFloat)progress;

///开始播放
- (void)startplay;

///暂停播放
- (void)pauseplay;

///播放完成
- (void)playEnd;

///选中的model跟数组的下标
- (void)setSlectedModel:(MER_PlayModel *)model index:(NSInteger)index;

///是否显示加载动画
- (void)hourGlassShowAnimation:(BOOL)animatied;

@end
