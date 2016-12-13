//
//  MER_PlayerControlDelegate.h
//  MER_Player
//
//  Created by 汉子MacBook－Pro on 2016/11/23.
//  Copyright © 2016年 不会爬树的熊. All rights reserved.
//

#ifndef MER_PlayerControlDelegate_h
#define MER_PlayerControlDelegate_h


#endif /* MER_PlayerControlDelegate_h */

@protocol MER_PlayerControlDelegate <NSObject>

/** 开始按钮事件 */
- (void)mer_startBtnAction:(UIView *)view button:(UIButton *)button;
/** 全屏按钮事件 */
- (void)mer_fullScreenBtnAction:(UIView *)view button:(UIButton *)button;
/** 按钮返回事件 */
- (void)mer_backBtnAction:(UIView *)view button:(UIButton *)button;
/** 下一集按钮事件 */
- (void)mer_nextBtnAction:(UIView *)view button:(UIButton *)button;
/** 进度条滑动事件 */
- (void)mer_sliderAction:(UIView *)view slider:(UISlider *)slider;
/** 进度条拖动结束 */
- (void)mer_sliderEndAction:(UIView *)view sliderEndValue:(CGFloat)value;
/** 进度条点击事件 */
- (void)mer_sliderTapAction:(UIView *)view sliderTapValue:(CGFloat)value;
/** 重播按钮点击事件 */
- (void)mer_replayBtnAction:(UIView *)view replayBtn:(UIButton *)button;
/** 选集点击事件 */
- (void)mer_albumBtnAction:(UIView *)view albumBtn:(UIButton *)button;
/** 点击了listview的cell */
- (void)mer_albumClickAction:(UIView *)view;

/** 选集点击事件 */
- (void)mer_listTableviewAction:(UIView *)view selectedIndexPath:(NSIndexPath *)indexPath;

@end
