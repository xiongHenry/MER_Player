//
//  MER_PlayerControlerView.m
//  MER_Player
//
//  Created by 汉子MacBook－Pro on 2016/11/23.
//  Copyright © 2016年 不会爬树的熊. All rights reserved.
//

#import "MER_PlayerControllerView.h"
#import "Masonry.h"
#import "ASValueTrackingSlider.h"
#import "AC_ProgressSlider.h"
#import "ZXVideoPlayerBrightnessView.h"
#import "ZXVideoPlayerVolumeView.h"
#import "MER_PlayModel.h"
#import "FeHourGlass.h"

static NSTimeInterval const showTime    = 10.0f;
static NSTimeInterval const hideTime    = 0.35f;
static CGFloat const listTableviewWidth = 250.0f;
static NSString *const identifier       = @"list";

@interface MER_PlayerControllerView ()<UITableViewDelegate,UITableViewDataSource>
/** 上部视图 */
@property (nonatomic, strong) UIView *topView;
/** 下部视图 */
@property (nonatomic, strong) UIView *bottomView;
/** 开始播放按钮 */
@property (nonatomic, strong) UIButton *startBtn;
/** 进度条 */
@property (nonatomic, strong) UISlider *videoSlider;
/** 当前时间label */
@property (nonatomic, strong) UILabel *currentLabel;
/** 总时间label */
@property (nonatomic, strong) UILabel *totalTimeLabel;
/** 全屏按钮 */
@property (nonatomic, strong) UIButton *fullScreenBtn;
/** 返回按钮 */
@property (nonatomic, strong) UIButton *backBtn;
/** 下一集按钮 */
@property (nonatomic, strong) UIButton *nextBtn;
/** 上一集按钮 */
@property (nonatomic, strong) UIButton *prevBtn;
/** 标题 */
@property (nonatomic, strong) UILabel *titleL;
/** 选集按钮 */
@property (nonatomic, strong) UIButton *alubumBtn;
/** 列表 */
@property (nonatomic, strong) UITableView *listTableview;
/** 缓冲进度条 */
@property (nonatomic, strong) UIProgressView *progressView;
/** 亮度提示view */
@property (nonatomic, strong) ZXVideoPlayerBrightnessView *brightnessView;
/** 音量提示view */
@property (nonatomic, strong) ZXVideoPlayerVolumeView *volumeView;
/** 占位view */
@property (nonatomic, strong) UIView *placeView;
/** 重播按钮 */
@property (nonatomic, strong) UIButton *replayBtn;
/** 快进/快退视图 */
@property (nonatomic, strong) UIView *fastView;
/** 快进/快退时间 */
@property (nonatomic, strong) UILabel *fastLabel;
/** 快进/快退的图片视图 */
@property (nonatomic, strong) UIImageView *fastImageView;
/** 记载动画 */
@property (nonatomic, strong) FeHourGlass *hourGlass;

#pragma mark - flag 基础的判断
/** 是否显示覆盖层 */
@property (nonatomic, assign) BOOL isShowOverlay;
/** 是否在拖拽slider */
@property (nonatomic, assign) BOOL isDraged;
/** 是否隐藏listtableview */
@property (nonatomic, assign) BOOL isHiddenListTableview;

@property (nonatomic, strong) MER_PlayModel *videoModel;

@end

@implementation MER_PlayerControllerView

#pragma mark - ----------------- 初始化 -------------------------
-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self prepareUI];
        [self addObserver];
        self.isHiddenListTableview = YES;
        self.backgroundColor       = [UIColor clearColor];
    }
    return self;
}

#pragma mark - ------------------- Public Method -----------------
///更新播放的时间信息
- (void)mer_updateControlCurrentTime:(NSInteger)currentTime totalTime:(NSInteger)totalTime sliderValue:(CGFloat)value{
    
    //当前时间
    NSInteger curSec    = currentTime % 60; //秒
    NSInteger curMini   = currentTime / 60; //分
    
    //总时间
    NSInteger totalSec  = totalTime % 60; //秒
    NSInteger totalMini = totalTime / 60; //分
    
    //slider 的value
    if (!self.isDraged) {//是否在拖拽进度条
        self.videoSlider.value = value;
        self.currentLabel.text   = [NSString stringWithFormat:@"%02zd:%02zd",curMini,curSec];
    }
    
    self.totalTimeLabel.text = [NSString stringWithFormat:@"%02zd:%02zd",totalMini,totalSec];
}

///拖拽更新信息
- (void)mer_updateControlCurrentTime:(NSInteger)currentTime totalTime:(NSInteger)totalTime direction:(FastDirection)direction{
    
    ///拖动的时候不显示加载动画
    [self hourGlassShowAnimation:NO];
    
    //正在拖拽slider
    self.isDraged = YES;
    //给slider赋值
    CGFloat value = (CGFloat)currentTime / (CGFloat)totalTime;
    self.videoSlider.value = value;
    
    //当前时间
    NSInteger curSec    = currentTime % 60; //秒
    NSInteger curMini   = currentTime / 60; //分
    
    //总时间
    NSInteger totalSec   = totalTime % 60;
    NSInteger totalMini  = totalTime / 60;
    
    self.currentLabel.text   = [NSString stringWithFormat:@"%02zd:%02zd",curMini,curSec];
    
    if (direction == Fast_forward) {//快进
       
        self.fastImageView.image = [UIImage imageNamed:@"MERPlayer_fastForward"];

    }else {                         //快退
    
        self.fastImageView.image = [UIImage imageNamed:@"MERPlayer_fastRewind"];
        
    }
    
    self.fastLabel.text = [NSString stringWithFormat:@"%02zd:%02zd/%02zd:%02zd",curMini,curSec,totalSec,totalMini];
    self.fastView.hidden = NO;
}

///结束拖拽
- (void)endDrage {
    
    self.isDraged        = NO;
    self.fastView.hidden = YES;
}

///设置缓冲区域
- (void)setProgress:(CGFloat)progress {
 
    [self.progressView setProgress:progress animated:YES];
}

///开始播放
- (void)startplay {
    
    self.startBtn.selected = YES;
}

///暂停播放
- (void)pauseplay{
    
    self.startBtn.selected = NO;
}

///播放完成
- (void)playEnd {
    
    self.placeView.hidden = NO;
    self.replayBtn.hidden = NO;
}

///选中的model跟数组的下标
- (void)setSlectedModel:(MER_PlayModel *)model index:(NSInteger)index {

    self.titleL.text = model.title;
    self.videoModel  = model;
    
    [self.listTableview reloadData];
}

///隐藏listview
- (void)hiddenListView {
    
    self.isHiddenListTableview = YES;
    self.alubumBtn.selected    = NO;
    [self listTableviewAnimation];
}

///是否显示加载动画
- (void)hourGlassShowAnimation:(BOOL)animatied {
    
    if (animatied) {
        [self.hourGlass show];
    }else {
        [self.hourGlass dismiss];
    }
    self.hourGlass.hidden = !animatied;
//    self.fastView.hidden  = animatied;
}

#pragma mark - ---------------- private method -----------------------
#pragma mark - UI
- (void)prepareUI {

    //self
    [self addSubview:self.placeView];
    [self addSubview:self.topView];
    [self addSubview:self.bottomView];
    [self addSubview:self.listTableview];
    [self addSubview:self.brightnessView];
    [self addSubview:self.volumeView];
    [self addSubview:self.replayBtn];
    [self addSubview:self.fastView];
    [self addSubview:self.hourGlass];
    
    //topview
    [self.topView addSubview:self.backBtn];
    [self.topView addSubview:self.titleL];
    [self.topView addSubview:self.alubumBtn];
    
    //bottomView
    [self.bottomView addSubview:self.startBtn];
    [self.bottomView addSubview:self.prevBtn];
    [self.bottomView addSubview:self.nextBtn];
    [self.bottomView addSubview:self.fullScreenBtn];
    [self.bottomView addSubview:self.progressView];
    [self.bottomView addSubview:self.videoSlider];
    [self.bottomView addSubview:self.currentLabel];
    [self.bottomView addSubview:self.totalTimeLabel];
    
    //fastView
    [self.fastView addSubview:self.fastImageView];
    [self.fastView addSubview:self.fastLabel];
    
    //刚创建选集按钮隐藏
    self.alubumBtn.hidden = YES;
    self.replayBtn.hidden = YES;
    self.placeView.hidden = YES;
    
    //self
    [self.placeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self);
    }];
    
    [self.brightnessView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self);
        make.width.height.mas_equalTo(118);
    }];
    
    [self.volumeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self);
        make.width.height.mas_equalTo(118);
    }];
    
    [self.replayBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self);
    }];
    
    [self.fastView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self);
        make.width.mas_equalTo(125);
        make.height.mas_equalTo(80);
    }];
    
    [self.hourGlass mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self);
    }];
    
    //topView
    [self.topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.top.mas_equalTo(self);
        make.height.mas_equalTo(50);
    }];
    
    [self.backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.topView).offset(8);
        make.top.mas_equalTo(self.topView).offset(8);
        make.width.height.mas_equalTo(43);
    }];
    
    [self.titleL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.backBtn.mas_trailing).offset(3);
        make.centerY.mas_equalTo(self.backBtn);
    }];
    
    [self.alubumBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(self.topView).offset(-10);
        make.centerY.mas_equalTo(self.backBtn);
        make.width.height.mas_equalTo(43);
    }];
    
    //bottomView
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.mas_equalTo(self);
        make.height.mas_equalTo(50);
    }];
    
    [self.startBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.bottomView).offset(5);
        make.bottom.mas_equalTo(self.bottomView).offset(-5);
        make.width.height.mas_equalTo(30);
    }];
    
    [self.nextBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.startBtn.mas_trailing).offset(3);
        make.centerY.mas_equalTo(self.startBtn);
        make.width.mas_equalTo(0);
    }];
    
    [self.currentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.startBtn);
        make.leading.mas_equalTo(self.nextBtn.mas_trailing).offset(3);
        make.width.mas_equalTo(43);
    }];
    
    [self.fullScreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.startBtn);
        make.trailing.mas_equalTo(self.bottomView).offset(-3);
        make.width.mas_equalTo(30);
    }];
    
    [self.totalTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.startBtn);
        make.trailing.mas_equalTo(self.fullScreenBtn.mas_leading).offset(-3);
        make.width.mas_equalTo(43);
    }];
    
    [self.videoSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.startBtn);
        make.leading.mas_equalTo(self.currentLabel.mas_trailing).offset(3);
        make.trailing.mas_equalTo(self.totalTimeLabel.mas_leading).offset(-3);
    }];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.startBtn).offset(1);
        make.leading.mas_equalTo(self.currentLabel.mas_trailing).offset(3);
        make.trailing.mas_equalTo(self.totalTimeLabel.mas_leading).offset(-3);
    }];
    
    //listTableview
    [self.listTableview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(self).offset(listTableviewWidth);
        make.top.bottom.mas_equalTo(self);
        make.width.mas_equalTo(listTableviewWidth);
    }];
    
    //fastView
    [self.fastImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.fastView);
        make.centerY.mas_equalTo(self.fastView.mas_centerY).offset(-5);
        make.height.mas_equalTo(24);
        make.width.mas_equalTo(44);
    }];
    
    [self.fastLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.fastView);
        make.top.mas_equalTo(self.fastImageView.mas_bottom).offset(5);
    }];
    
    [self hourGlassShowAnimation:YES];
}

#pragma mark - 监听
- (void)addObserver {
    
    ///监听设备旋转
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeviceOrientationChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

///监听设备旋转执行方法
- (void)onDeviceOrientationChange:(NSNotification *)notification {
    
    //获取当前设备方向
    UIDeviceOrientation orientation = self.getDeviceOrientation;
    
    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown) return;
    self.isShowOverlay         = NO;
    switch (orientation) {
        case UIDeviceOrientationPortrait:// home在下
        {
            self.alubumBtn.selected    = NO;
            self.alubumBtn.hidden      = YES;
            self.listTableview.hidden  = YES;
            self.isHiddenListTableview = YES;
            [self showOverlay];
            [self.nextBtn mas_updateConstraints:^(MASConstraintMaker *make) {
                make.width.mas_equalTo(0);
            }];
        }
            break;
        case UIDeviceOrientationLandscapeLeft:// home在左
        {
            self.alubumBtn.hidden      = NO;
            self.listTableview.hidden  = NO;
            self.isHiddenListTableview = YES;
            [self showOverlay];
            [self.nextBtn mas_updateConstraints:^(MASConstraintMaker *make) {
                make.width.mas_equalTo(43);
            }];
        }
            break;
        case UIDeviceOrientationLandscapeRight:// home在右
        {
            self.alubumBtn.hidden      = NO;
            self.listTableview.hidden  = NO;
            self.isHiddenListTableview = YES;
            [self showOverlay];
            [self.nextBtn mas_updateConstraints:^(MASConstraintMaker *make) {
                make.width.mas_equalTo(43);
            }];
            
        }
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            
            break;
            
        default:
            break;
    }
    
    //每次旋转都执行
    [self listTableviewAnimation];
}

#pragma mark - 获取当前设备方向
- (UIDeviceOrientation)getDeviceOrientation
{
    return [UIDevice currentDevice].orientation;
}

#pragma mark - listTableview的显示和隐藏
- (void)listTableviewAnimation {
    
    ///在竖屏情况下,本来就不显示
    if (self.listTableview.hidden == YES) {
        return;
    }
    
    [UIView animateWithDuration:hideTime animations:^{
       
        [self.listTableview mas_updateConstraints:^(MASConstraintMaker *make) {
            make.trailing.mas_equalTo(self).offset(self.isHiddenListTableview ? listTableviewWidth : 0);
        }];
        [self layoutIfNeeded];
    }];
    
    if (!self.isHiddenListTableview) {
        [self hiddenOverlay];
    }else {
        [self showOverlay];
    }
}

#pragma mark - top,bottomView的隐藏显示
///显示覆盖层
- (void)showOverlay {

    if (self.isShowOverlay) {
        [self hiddenOverlay];
        return;
    }
    
    self.isShowOverlay = YES;
    [UIView animateWithDuration:hideTime animations:^{
        self.topView.alpha = 1;
        self.bottomView.alpha = 1;
    } completion:^(BOOL finished) {
        [self autoOverlay];
    }];
}

///隐藏覆盖层
- (void)hiddenOverlay {

    if (!self.isShowOverlay) return;
    
    [UIView animateWithDuration:hideTime animations:^{
        self.topView.alpha = 0;
        self.bottomView.alpha = 0;
    } completion:^(BOOL finished) {
        self.isShowOverlay = NO;
    }];
    
    self.isHiddenListTableview = YES;
//    [self listTableviewAnimation];
}

///自动隐藏覆盖层
- (void)autoOverlay {
    
    if (!self.isShowOverlay) return;
    
    //取消之前执行的目标请求 延迟
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hiddenOverlay) object:nil];
    //延迟操作
    [self performSelector:@selector(hiddenOverlay) withObject:nil afterDelay:showTime];
}

#pragma mark - 重新布局
-(void)layoutSubviews {
    [super layoutSubviews];
//    [self showOverlay];
}

#pragma mark - listTableview的数据源,代理方法
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle  = UITableViewCellSelectionStyleNone;
    
    MER_PlayModel * model = self.datas[indexPath.row];
    if (self.videoModel == model) {
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.font      = [UIFont fontWithName:@"Helvetica-Bold" size:17];
    }else {
        cell.textLabel.textColor = [UIColor lightGrayColor];
        cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:17];
    }
    cell.textLabel.text = model.title;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.datas.count == 0) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(mer_listTableviewAction:selectedIndexPath:)]) {
        [self.delegate mer_listTableviewAction:self selectedIndexPath:indexPath];
    }
    
    self.videoModel  = self.datas[indexPath.row];
    self.titleL.text = self.videoModel.title;
    self.isHiddenListTableview =
    self.alubumBtn.selected =
    YES;
    self.isShowOverlay = NO;
    [self listTableviewAnimation];
    [self.listTableview reloadData];
    
    if ([self.delegate respondsToSelector:@selector(mer_albumClickAction:)]) {
        [self.delegate mer_albumClickAction:self];
    }
}

#pragma mark - 点击事件
- (void)startBtnAction:(UIButton *)button {

    if ([self.delegate respondsToSelector:@selector(mer_startBtnAction:button:)]) {
        [self.delegate mer_startBtnAction:self button:button];
    }
}

- (void)fullScreenBtnAction:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(mer_fullScreenBtnAction:button:)]) {
        [self.delegate mer_fullScreenBtnAction:self button:button];
    }
}

- (void)backBtnAction:(UIButton *)button {
    
    if ([self.delegate respondsToSelector:@selector(mer_backBtnAction:button:)]) {
        [self.delegate mer_backBtnAction:self button:button];
    }
}

- (void)nextBtnAction:(UIButton *)button {
    
    if ([self.delegate respondsToSelector:@selector(mer_nextBtnAction:button:)]) {
        [self.delegate mer_nextBtnAction:self button:button];
    }
}

- (void)videoSliderAction:(UISlider *)slider {
    NSLog(@"拖动,拖动");
    if ([self.delegate respondsToSelector:@selector(mer_sliderAction:slider:)]) {
        [self.delegate mer_sliderAction:self slider:slider];
    }
}

- (void)videiSliderEndAction:(UISlider *)slider {
    
    if ([self.delegate respondsToSelector:@selector(mer_sliderEndAction:sliderEndValue:)]) {
        [self.delegate mer_sliderEndAction:self sliderEndValue:slider.value];
    }
}

- (void)videoSliderTapAction:(UITapGestureRecognizer *)tap {

    if ([tap.view isKindOfClass:[UISlider class]]) {
        UISlider * slider = (UISlider *)tap.view;
        //获取点击的坐标
        CGPoint point = [tap locationInView:slider];
        //获取控件的长度
        CGFloat lenth = slider.frame.size.width;
        //计算出跳转的时间
        CGFloat value = point.x / lenth;
        
        if ([self.delegate respondsToSelector:@selector(mer_sliderTapAction:sliderTapValue:)]) {
            [self.delegate mer_sliderTapAction:self sliderTapValue:value];
        }
    }
}

- (void)prevBtnAction:(UIButton *)button {

}

- (void)albumBtnAction:(UIButton *)button {

    self.isHiddenListTableview = NO;
    [self listTableviewAnimation];
    button.selected = !button.isSelected;
    if ([self.delegate respondsToSelector:@selector(mer_albumBtnAction:albumBtn:)]) {
        [self.delegate mer_albumBtnAction:self albumBtn:button];
    }
}

- (void)replayBtnAction:(UIButton *)button {
    
    if ([self.delegate respondsToSelector:@selector(mer_replayBtnAction:replayBtn:)]) {
        [self.delegate mer_replayBtnAction:self replayBtn:button];
    }
}

#pragma mark - setter
-(void)setDatas:(NSArray *)datas {
    _datas = datas;
    [self.listTableview reloadData];
}

-(void)setIsHiddenVolumeIndicatorView:(BOOL)isHiddenVolumeIndicatorView {
    _isHiddenVolumeIndicatorView = isHiddenVolumeIndicatorView;
    self.volumeView.hidden       = isHiddenVolumeIndicatorView;
}

-(void)setIsHiddenbrightnessIndicatorView:(BOOL)isHiddenbrightnessIndicatorView {
    _isHiddenbrightnessIndicatorView = isHiddenbrightnessIndicatorView;
    self.brightnessView.hidden       = isHiddenbrightnessIndicatorView;
}

#pragma mark - getter
-(UIView *)topView {
    if (_topView == nil) {
        _topView = [[UIView alloc] init];
        _topView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"MERPlayer_top_shadow"]];
    }
    return _topView;
}

- (UIView *)bottomView {
    if (_bottomView == nil) {
        _bottomView = [[UIView alloc] init];
        _bottomView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"MERPlayer_bottom_shadow"]];
    }
    return _bottomView;
}

-(UIButton *)startBtn {
    if (_startBtn == nil) {
        _startBtn = [[UIButton alloc] init];
        [_startBtn addTarget:self action:@selector(startBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_startBtn setImage:[UIImage imageNamed:@"MERPlayer_play"] forState:UIControlStateNormal];
        [_startBtn setImage:[UIImage imageNamed:@"MERPlayer_pause"] forState:UIControlStateSelected];
        _startBtn.selected = YES;
    }
    return _startBtn;
}

-(UISlider *)videoSlider {
    if (_videoSlider == nil) {
        _videoSlider = [[UISlider alloc] init];
        [_videoSlider setThumbImage:[UIImage imageNamed:@"MERPlayer_slider"] forState:UIControlStateNormal];
        
        _videoSlider.minimumTrackTintColor = [UIColor whiteColor];
        _videoSlider.maximumTrackTintColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
        
        //拖动中...
        [_videoSlider addTarget:self action:@selector(videoSliderAction:) forControlEvents:UIControlEventValueChanged];
        //拖动结束
        [_videoSlider addTarget:self action:@selector(videiSliderEndAction:) forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchUpInside | UIControlEventTouchCancel];
        //tap事件
        UITapGestureRecognizer * sliderTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(videoSliderTapAction:)];
        [_videoSlider addGestureRecognizer:sliderTap];
        _videoSlider.minimumValue = 0.0f;
        _videoSlider.maximumValue = 1.0f;
    }
    return _videoSlider;
}

-(UILabel *)currentLabel {
    if (_currentLabel == nil) {
        _currentLabel = [[UILabel alloc] init];
        _currentLabel.textColor = [UIColor whiteColor];
        _currentLabel.font = [UIFont systemFontOfSize:14.0f];
        _currentLabel.text = @"00:00";
    }
    return _currentLabel;
}

-(UILabel *)totalTimeLabel {
    if (_totalTimeLabel == nil) {
        _totalTimeLabel = [[UILabel alloc] init];
        _totalTimeLabel.textColor = [UIColor whiteColor];
        _totalTimeLabel.font = [UIFont systemFontOfSize:14.0f];
        _totalTimeLabel.text = @"00:00";
    }
    return _totalTimeLabel;
}

- (UIButton *)fullScreenBtn {
    if (_fullScreenBtn == nil) {
        _fullScreenBtn = [[UIButton alloc] init];
        [_fullScreenBtn addTarget:self action:@selector(fullScreenBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_fullScreenBtn setImage:[UIImage imageNamed:@"MERPlayer_fullscreen.png"] forState:UIControlStateNormal];
    }
    return _fullScreenBtn;
}

- (UIButton *)backBtn {
    if (_backBtn == nil) {
        _backBtn = [[UIButton alloc] init];
        [_backBtn addTarget:self action:@selector(backBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_backBtn setImage:[UIImage imageNamed:@"MERPlayer_back_full.png"] forState:UIControlStateNormal];
    }
    return _backBtn;
}

-(UIButton *)nextBtn {
    if (_nextBtn == nil) {
        _nextBtn = [[UIButton alloc] init];
        [_nextBtn addTarget:self action:@selector(nextBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_nextBtn setImage:[UIImage imageNamed:@"MERPlayer_next"] forState:UIControlStateNormal];
    }
    return _nextBtn;
}

-(UIButton *)prevBtn {
    if (_prevBtn == nil) {
        _prevBtn = [[UIButton alloc] init];
        [_prevBtn addTarget:self action:@selector(prevBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_prevBtn setTitle:@"prev" forState:UIControlStateNormal];
    }
    return _prevBtn;
}

-(UILabel *)titleL {
    if (_titleL == nil) {
        _titleL = [[UILabel alloc] init];
        _titleL.font      = [UIFont systemFontOfSize:14];
        _titleL.textColor = [UIColor whiteColor];
        _titleL.text      = @"标题";
    }
    return _titleL;
}

-(UIButton *)alubumBtn {
    if (_alubumBtn == nil) {
        _alubumBtn = [[UIButton alloc] init];
        [_alubumBtn setTitle:@"选集" forState:UIControlStateNormal];
        [_alubumBtn addTarget:self action:@selector(albumBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _alubumBtn;
}

-(UITableView *)listTableview {
    if (_listTableview == nil) {
        _listTableview = [[UITableView alloc] initWithFrame:self.bounds style:UITableViewStylePlain];
        _listTableview.separatorStyle = UITableViewCellSeparatorStyleNone;
        _listTableview.dataSource = self;
        _listTableview.delegate = self;
        _listTableview.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    }
    return _listTableview;
}

-(UIProgressView *)progressView {
    if (_progressView == nil) {
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.progressTintColor = [UIColor lightGrayColor];
        _progressView.trackTintColor    = [UIColor clearColor];
    }
    return _progressView;
}

-(ZXVideoPlayerBrightnessView *)brightnessView {
    if (_brightnessView == nil) {
        _brightnessView = [[ZXVideoPlayerBrightnessView alloc] init];
    }
    return _brightnessView;
}

-(ZXVideoPlayerVolumeView *)volumeView {
    if (_volumeView == nil) {
        _volumeView = [[ZXVideoPlayerVolumeView alloc] init];
    }
    return _volumeView;
}

-(UIView *)placeView {
    if (_placeView == nil) {
        _placeView = [[UIView alloc] init];
        _placeView.backgroundColor = RGBA(0, 0, 0, 0.5);
    }
    return _placeView;
}

- (UIButton *)replayBtn {
    if (_replayBtn == nil) {
        _replayBtn = [[UIButton alloc] init];
        [_replayBtn setImage:[UIImage imageNamed:@"MERPlayer_repeat_video"] forState:UIControlStateNormal];
        [_replayBtn addTarget:self action:@selector(replayBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_replayBtn sizeToFit];
    }
    return _replayBtn;
}

-(UIView *)fastView {
    if (_fastView == nil) {
        _fastView = [[UIView alloc] init];
        _fastView.backgroundColor = RGBA(0, 0, 0, 0.7);
        _fastView.hidden = YES;
    }
    return _fastView;
}

-(UILabel *)fastLabel {
    if (_fastLabel == nil) {
        _fastLabel = [[UILabel alloc] init];
        _fastLabel.textColor = [UIColor whiteColor];
        _fastLabel.font = [UIFont systemFontOfSize:14];
        _fastLabel.text = @"00:00/00:00";
    }
    return _fastLabel;
}

-(UIImageView *)fastImageView {
    if (_fastImageView == nil) {
        _fastImageView = [[UIImageView alloc] init];
    }
    return _fastImageView;
}

-(FeHourGlass *)hourGlass {
    if (_hourGlass == nil) {
        _hourGlass = [[FeHourGlass alloc] initWithView:self];
    }
    return _hourGlass;
}

@end
