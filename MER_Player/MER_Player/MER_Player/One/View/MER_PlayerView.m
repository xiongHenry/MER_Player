//
//  MER_PlayerView.m
//  MER_Player
//
//  Created by 汉子MacBook－Pro on 16/9/20.
//  Copyright © 2016年 不会爬树的熊. All rights reserved.
//

#import "MER_PlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MER_PlayerControllerView.h"//控制view
#import "MER_PlayModel.h"

@interface MER_PlayerView ()<MER_PlayerControlDelegate,UIGestureRecognizerDelegate>

@property (nonatomic, strong) AVURLAsset *urlAsset;
/** 播放器 */
@property (nonatomic, strong) AVPlayer *player;
/** 播放属性 */
@property (nonatomic, strong) AVPlayerItem *playerItem;
/** 用于播放的layer */
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
/** 系统音量滑竿 */
@property (nonatomic, strong) UISlider *volumeSlider;

@property (nonatomic, strong) id timeObserver;
#pragma mark - flag 记录判断
/** 是否自动更新进度 */
@property (nonatomic, assign,getter=isAutoUpdateProgress) BOOL autoUpdateProgress;

/** 是否全屏 */
@property (nonatomic, assign) BOOL isFullScreen;
/** 是否暂停*/
@property (nonatomic, assign) BOOL isPause;
/** 是否在调节音量或亮度 */
/*
 * yes : 音量 no:亮度
 */
@property (nonatomic, assign) BOOL isVolume;
/** 是否播放完成 */
@property (nonatomic, assign) BOOL isPlayEnd;
/** 判断是否显示listview */
@property (nonatomic, assign) BOOL isShowListView;
/** 是否显示控制层 */
@property (nonatomic, assign) BOOL isShowControlview;

#pragma mark - flag gesture
/** 单击手势 */
@property (nonatomic, strong) UITapGestureRecognizer *singleTag;
/** 双击手势 */
@property (nonatomic, strong) UITapGestureRecognizer *doubleTag;
/** 平移手势 */
@property (nonatomic, strong) UIPanGestureRecognizer *panGes;
/** 滑动手势的方向 */
@property (nonatomic, assign) PanDirection panDirection;

#pragma mark - flag 记录的数据
/** 保存快进的总时间 */
@property (nonatomic, assign) CGFloat sumTime;
/** 当前播放的数据源数组的下标 */
@property (nonatomic, assign) NSInteger index;

@end

@implementation MER_PlayerView

#pragma mark - cycle life
-(void)dealloc {
 
    [self removeObserver];
    
}

- (instancetype)initWithVideoURLs:(NSArray *)videoURLs {
    
    if (self = [super init]) {
        self.VideoURLs = videoURLs;
        [self prepareUI];
    }
    return self;
}

-(instancetype)initWithURL:(NSString *)URL {
    if (self = [super init]) {
        self.videoURL = URL;
        [self prepareUI];
    }
    return self;
}

#pragma mark - layoutsubviews
-(void)layoutSubviews {
    [super layoutSubviews];
    
    self.playerLayer.frame = self.bounds;
}


#pragma mark - ------------------ pulic method -----------------
///创建
+ (instancetype)mer_setControlView:(MER_PlayerControllerView *)controlView videoURLs:(NSArray *)videoURLs {

    MER_PlayerView * vv = [[MER_PlayerView alloc]init];
    [vv mer_setControlView:controlView videoURLs:videoURLs];
    return vv;
}

- (void)mer_setControlView:(MER_PlayerControllerView *)controlView videoURLs:(NSArray *)videoURLs {
    self.isFullScreen       = NO;
    self.autoUpdateProgress = YES;
    self.isShowListView     = NO;
    self.controlView        = controlView;
    self.VideoURLs          = videoURLs;
}

///跳转到指定的时间
- (void)seekToTime:(NSInteger)toTime complitionHander:(void(^)(BOOL finishi))completionHander {
    
    ///显示加载动画
//    [self.controlView hourGlassShowAnimation:YES];
    //当视频状态为AVPlayerStatusReadyToPlay时才处理（当视频没加载的时候，直接禁止掉滑块事件
    if (self.player.currentItem.status == AVPlayerStatusReadyToPlay) {

        //先暂停视频
        [self.player pause];
        
        CMTime dragedTime = CMTimeMake(toTime, 1);
         // seekTime:completionHandler:不能精确定位
//        [self.player seekToTime:dragedTime completionHandler:completionHander];
     
        __weak typeof(self) weakself = self;
        //这个更为精确
        [self.player seekToTime:dragedTime toleranceBefore:CMTimeMake(1, 1) toleranceAfter:CMTimeMake(1, 1) completionHandler:^(BOOL finished) {
            
            ///隐藏加载动画
//            [self.controlView hourGlassShowAnimation:NO];
            
            //判断回调
            if (completionHander) {
                completionHander(finished);
            }
            //开始播放视频
            [weakself.player play];
            //结束拖拽
            [weakself.controlView endDrage];
            
        }];
    }
}

///开始
- (void)play {

    self.isPause = NO;
    [self.controlView startplay];
    [self.player play];
}

///暂停
- (void)pause {

    self.isPause = YES;
    [self.controlView pauseplay];
    [self.player pause];
}

///切换播放源
- (void)replacePlay:(MER_PlayModel *)model {
    
    [self resetPlayer];
    [self creatPlayer:model.videoURL];
}

#pragma mark - ---------- private method  -----------
#pragma mark - UI
- (void)prepareUI {
    
//    [self creatPlayer];
    self.autoUpdateProgress = YES;
}

#pragma mark - 监听
- (void)addObserver {

    /********** NSNotificationCenter ************/
    
    ///监听设备旋转
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil
     ];
    
    
    ///监听播放完成
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playEndFinishi:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:nil
     ];
    
    /********** KVO ************/
    
    ///监听播放状态
    [self.playerItem addObserver:self
                      forKeyPath:@"status"
                         options:NSKeyValueObservingOptionNew
                         context:nil
     ];
    
    ///监听缓冲
    [self.playerItem addObserver:self
                      forKeyPath:@"loadedTimeRanges"
                         options:NSKeyValueObservingOptionNew
                         context:nil
     ];
    
    ///监听缓存不足了
    [self.playerItem addObserver:self
                      forKeyPath:@"playbackBufferEmpty"
                         options:NSKeyValueObservingOptionNew
                         context:nil
     ];
    
    ///缓存足够了,可以播放了
    [self.playerItem addObserver:self
                      forKeyPath:@"playbackLikelyToKeepUp"
                         options:NSKeyValueObservingOptionNew
                         context:nil
     ];
    
}

#pragma mark - KVO
/**
 *  KVO监听
 *
 *  @param keyPath 属性名称
 *  @param object  监听对象
 *  @param change  改变的内容
 *  @param context
 */
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    
    if ([keyPath isEqualToString:@"status"]) { //监听播放状态
        
        //    AVPlayerStatusUnknown,      未知
        //    AVPlayerStatusReadyToPlay,  数据缓存已经准备好,可以进行播放了
        //    AVPlayerStatusFailed        由于错误导致不能播放
        
        switch (self.player.status) {
            case AVPlayerStatusUnknown:
                NSLog(@"未知");
                break;
            case AVPlayerStatusReadyToPlay:
                NSLog(@"数据缓存已经准备好,可以进行播放了");
                //视频准备好开始播放,创建平移手势
                [self creatPanGesture];
                break;
            case AVPlayerStatusFailed:
                NSLog(@"由于错误导致不能播放");
                break;
                
            default:
                break;
        }
        
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]) { ///监听缓冲进度
        
        //计算缓冲区
        NSTimeInterval loadTime  = [self availableDuration];
        NSTimeInterval totalTime = CMTimeGetSeconds(self.playerItem.duration);
        [self.controlView setProgress:loadTime / totalTime];
    }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) { ///监听到缓存不足
    
        [self.controlView hourGlassShowAnimation:YES];
        [self pause];
        
    }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) { ///监听到缓存好了可以播放了
    
        [self.controlView hourGlassShowAnimation:NO];
        [self play];
    }
}

- (NSTimeInterval)availableDuration {
    
    NSArray *loadedTimeRanges = [self.playerItem loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    NSTimeInterval startSeconds = CMTimeGetSeconds(timeRange.start);
    NSTimeInterval durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

#pragma mark - 创建手势
- (void)creatGesture {
    
    //单击手势
    self.singleTag = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTagAction:)];
    self.singleTag.numberOfTouchesRequired  = 1;//手指数
    self.singleTag.numberOfTapsRequired     = 1; //点击次数
    [self addGestureRecognizer:self.singleTag];
    self.singleTag.delegate = self;
    
    //双击手势
    self.doubleTag = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTagAction:)];
    self.doubleTag.numberOfTouchesRequired  = 1;//手指
    self.doubleTag.numberOfTapsRequired     = 2;//点击两下
    [self addGestureRecognizer:self.doubleTag];
    self.singleTag.delegate = self;
    
    //点击当前view时响应其他控件的事件
    [self.singleTag setDelaysTouchesBegan:YES];
    [self.doubleTag setDelaysTouchesBegan:YES];
    
    //双击手势失效的时候响应单击手势事件
    [self.singleTag requireGestureRecognizerToFail:self.doubleTag];
    
}

///创建平移手势(当视频开始播放的时候再添加平移手势)
- (void)creatPanGesture {

    self.panGes = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panGesAction:)];
    self.panGes.maximumNumberOfTouches = 1;
    [self.panGes setDelaysTouchesBegan:YES];
    [self.panGes setDelaysTouchesEnded:YES];
    [self.panGes setCancelsTouchesInView:YES];
    
    [self addGestureRecognizer:self.panGes];
}

#pragma mark - 重置player
- (void)resetPlayer {

    /*
     githup上ZFPlayer 作者表示在iOS9后，AVPlayer的replaceCurrentItemWithPlayerItem方法在切换视频时底层会调用信号量等待然后导致当前线程卡顿，如果在UITableViewCell中切换视频播放使用这个方法，会导致当前线程冻结几秒钟。遇到这个坑还真不好在系统层面对它做什么，后来找到的解决方法是在每次需要切换视频时，需重新创建AVPlayer和AVPlayerItem
     */
    
    //暂停播放
    [self pause];
    //移除监听
    [self removeObserver];
    
    //播放完成
    self.isPlayEnd   = NO;
    
    //清除播放layer
    [self.playerLayer removeFromSuperlayer];
    
    //替换为nil
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.playerItem  = nil;
    self.player      = nil;
    self.playerLayer = nil;
    
    self.controlView = nil;
    
    //视频跳转为0
}

#pragma mark - 手势action
///单击手势事件
- (void)singleTagAction:(UIGestureRecognizer *)gesture {
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        if (self.isShowListView) {
            [self.controlView hiddenListView];
            self.isShowListView = NO;
        }else {
            [self.controlView showOverlay];
        }
    }
}

///双击手势事件
- (void)doubleTagAction:(UIGestureRecognizer *)gesture {
    
    [self.controlView showOverlay];
    if (self.isPause) {
        [self play];
    }else {
        [self pause];
    }
}

///平移手势
- (void)panGesAction:(UIPanGestureRecognizer *)gesture {

    //根据手势在view上的位置,获取坐标,判断调音还是调亮度
    CGPoint locationPoint = [gesture locationInView:self];
    
    //根据平移得到手势拖动的速率的point
    CGPoint veloctyPoint = [gesture velocityInView:self];
 
    //
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: //开始
        {
            //根据拖动速率的point,算出x,y值,然后判断移动的方向
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            if (x > y) { //平移
                self.panDirection = Pan_SlideHorizontally;
                CMTime time       = self.player.currentTime;
                //记录当前的时间
                self.sumTime      = (CGFloat)time.value / (CGFloat)time.timescale;
                
            }else {//垂直
                self.panDirection = Pan_SlideVertically;
                //判断在左边还是在右边来判断是调节音量还是调节亮度
                if (locationPoint.x < self.bounds.size.width / 2) { //调节音量
                    
                    self.isVolume = YES;
                    
                }else {//调节亮度
                
                    self.isVolume = NO;
                }
            }
        }
            break;
        case UIGestureRecognizerStateChanged: //正在移动变化
        {
            
            if (self.panDirection == Pan_SlideHorizontally) { //水平
                [self horMoved:veloctyPoint.x];
            }else {                                           //垂直
                [self verMoved:veloctyPoint.y];
            }
        
        }
            break;
        case UIGestureRecognizerStateEnded: //停止
        {
            
            if (self.panDirection == Pan_SlideHorizontally) { //水平
                //平移结束,就调至滑动到的时间的地方
                [self seekToTime:self.sumTime complitionHander:nil];
                //清空sumTime
                self.sumTime  = 0;
            }else {                                           //垂直
                //移动后不再控制音量
                self.isVolume = NO;
            }
        }
            break;
            
        default:
            break;
    }
}

///横向移动的拖动值
- (void)horMoved:(CGFloat)value {

    self.sumTime += value/200;
    
    //因为视频是有时间限制的,所以时间有一个范围,
    //获取视频总时间
    CMTime totalTime = self.playerItem.duration;
    CGFloat totalVideoDuration = (CGFloat)totalTime.value / (CGFloat)totalTime.timescale;
    
    //判断
    if (self.sumTime > totalVideoDuration) {
        self.sumTime = totalVideoDuration;
    }
    
    if (self.sumTime < 0) {
        self.sumTime = 0;
    }
    
    //这里判断方向,是快进,还是快退,根据value
    FastDirection direction = Fast_rewind;
    if (value < 0) {//快退
        direction = Fast_rewind;
    }
    
    if (value > 0) {//快进
        direction = Fast_forward;
    }
    
    //这个判断需要,不然显示会来回跳转
    if (value == 0) {
        return;
    }
    
    //给control赋值
    [self.controlView mer_updateControlCurrentTime:self.sumTime totalTime:totalVideoDuration direction:direction];
}

///竖向移动的拖动值
- (void)verMoved:(CGFloat)value {

    ///调节音量跟亮度
    self.isVolume ? (self.volumeSlider.value -= value/10000) : ([UIScreen mainScreen].brightness -= value/10000);
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {

    ///判断手势跟tableView的cell点击冲突
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellContentView"] || [NSStringFromClass([touch.view class]) isEqualToString:@"UIButton"]) {
        return NO;
    }
    return YES;
}

#pragma mark - 获取系统的音量
///获取系统音量
- (void)getVloume {
    
    MPVolumeView * volumeView = [[MPVolumeView alloc]init];
    for (UIView *view in volumeView.subviews) {
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]) {
            _volumeSlider = (UISlider *)view;
        }
        break;
    }
    
    ///在界面不现实系统音量的图标
    volumeView.frame = CGRectMake(-100, -100, 100, 100);
    [self addSubview:volumeView];
    
    NSError * audioCategoryError = nil;
    BOOL isSuccess = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&audioCategoryError];
    if (!isSuccess) {
        //错误
        NSLog(@"\n\naudioCategoryError = %@",audioCategoryError);
    }
    
    //监听耳机拔出
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeNotification:) name:AVAudioSessionRouteChangeNotification object:nil];
}

///监听耳机插入,拔出
- (void)audioRouteChangeNotification:(NSNotification *)notification {

    NSDictionary * info = notification.userInfo;
    
    NSInteger audioStatus = [[info valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (audioStatus) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            //耳机插入
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            //耳机拔出
            
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            
            break;
            
        default:
            break;
    }
    
}

#pragma mark - 移除监听
- (void)removeObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.player removeTimeObserver:self.timeObserver];
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    self.timeObserver = nil;
}

#pragma mark - 监听通知调用的方法
- (void)onDeviceOrientationChange {

    //没有初始化播放器 return
    if (!self.player) return;
    ///获取当前设备的方向
    UIDeviceOrientation orientation = self.getDeviceOrientation;
    
    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown) return;
    
    switch (orientation) {
        case UIDeviceOrientationPortrait://home 在下
        {
            if (self.isFullScreen) {//是全屏就旋转
                [self orientationChangeMasonry:UIDeviceOrientationPortrait];
                self.isFullScreen     = NO;
                self.isShowListView   = NO;
            }
        }
            break;
        case UIDeviceOrientationLandscapeLeft://home 在左
        {
            if (!self.isFullScreen) {
                [self orientationChangeMasonry:UIDeviceOrientationLandscapeLeft];
                self.isFullScreen = YES;
            }
        }
            break;
        case UIDeviceOrientationLandscapeRight://home 在右
        {
            if (!self.isFullScreen) {
                [self orientationChangeMasonry:UIDeviceOrientationLandscapeRight];
                self.isFullScreen = YES;
            }
        }
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            
            break;
            
        default:
            break;
    }
    
}

- (void)orientationChangeMasonry:(UIDeviceOrientation)orientation {

    
    if (orientation != UIDeviceOrientationPortrait) {//不是竖屏
//        [self mas_updateConstraints:^(MASConstraintMaker *make) {
//            
//        }];
        
    }
}

///监听播放完成
- (void)playEndFinishi:(NSNotification *)notification {

    self.isPlayEnd = YES;
    
    if (self.index == self.VideoURLs.count - 1 || self.VideoURLs.count == 0) {
        //播放完成,显示重播
        [self.controlView playEnd];
        return;
    }
    
    [self resetPlayer];
    self.currentModel = self.VideoURLs[++self.index];
}

#pragma mark - 创建播放器以及设置属性
- (void)creatPlayer:(NSString *)url {
    
    self.backgroundColor = [UIColor blackColor];
    
    self.urlAsset = [AVURLAsset assetWithURL:[NSURL URLWithString:url]];
    self.playerItem = [AVPlayerItem playerItemWithAsset:self.urlAsset];
    self.player = [[AVPlayer alloc]initWithPlayerItem:self.playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    
    //设置属性
    //此处默认是填充模式
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    //添加到view的layer上
    //如果直接加上,在切换的时候,会遮挡住控制视图,这样插入,放置在最后就不会有问题
//    [self.layer addSublayer:self.playerLayer];
    [self.layer insertSublayer:self.playerLayer atIndex:0];
    
    //监听时间
    [self obsercverTime];
    
    //开始播放
    [self play];
    
    //监听
    [self addObserver];
    
    //获取系统音量
    [self getVloume];
    
    //开始播放
    [self.controlView startplay];
    
}

///监听播放的时间进度
- (void)obsercverTime {
    
    //监听时间
    CMTime time = CMTimeMake(1, 100000); //这样block每隔0,1s调用一次
    //监听时间间隔,每间隔一段时间就执行一个block
    __weak typeof(self) weakself = self;
   self.timeObserver = [self.player addPeriodicTimeObserverForInterval:time queue:nil usingBlock:^(CMTime time) {
        
        //如果没有自动更新进度直接返回
        if (!weakself.isAutoUpdateProgress) {
            return ;
        }
        
        //获取视频的持续,视频是一种资源
        CMTime duration = weakself.player.currentItem.asset.duration;
        //换算成秒
        CGFloat currentTime  = CMTimeGetSeconds(weakself.player.currentTime);
        CGFloat durationTime = CMTimeGetSeconds(duration);
        CGFloat value        = currentTime / durationTime;
        //设置滑块的播放进度
        [weakself.controlView mer_updateControlCurrentTime:currentTime totalTime:durationTime sliderValue:value];
    }];
}

#pragma mark - MER_PlayerControlDelegate
///开始播放按钮事件
-(void)mer_startBtnAction:(UIView *)view button:(UIButton *)button {
    
    if (button.selected) {
        
//        [self.player pause];
        [self pause];
    }else {
        [self play];
//        [self.player play];
    }
}

///进度条滑动事件
-(void)mer_sliderAction:(UIView *)view slider:(UISlider *)slider {

    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        
        //获取资源的总时间
        CMTime totalTime   = self.player.currentItem.asset.duration;
        
        NSInteger totalTime_t = (CGFloat)totalTime.value / (CGFloat)totalTime.timescale;
        
        NSInteger currentTime = totalTime_t * slider.value;
//        [self.controlView mer_updateControlCurrentTime:currentTime totalTime:totalTime_t];
    }
}

///进度条拖动结束
- (void)mer_sliderEndAction:(UIView *)view sliderEndValue:(CGFloat)value {
    
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        
        //获取资源的总时间
        CMTime totalTime    = self.player.currentItem.asset.duration;
        NSInteger drageTime = ((CGFloat)totalTime.value / (CGFloat)totalTime.timescale) * value;
        
        [self seekToTime:drageTime complitionHander:nil];
        
    }
}

///全屏按钮事件
-(void)mer_fullScreenBtnAction:(UIView *)view button:(UIButton *)button {

    if (self.isFullScreen) {
        
        [self changeToOrientation:UIDeviceOrientationPortrait];
        self.isFullScreen = NO;
        
    }else {
        //获取设备当前的方向
        UIDeviceOrientation orientation = self.getDeviceOrientation;
        if (orientation == UIDeviceOrientationLandscapeLeft) {
            [self changeToOrientation:UIDeviceOrientationLandscapeRight];
        }else {
            [self changeToOrientation:UIDeviceOrientationLandscapeLeft];
        }
        self.isFullScreen = YES;
    }
}

///返回按钮事件
-(void)mer_backBtnAction:(UIView *)view button:(UIButton *)button {
    [self.player pause];
    if (self.isFullScreen) {
        self.isFullScreen = NO;
        [self changeToOrientation:UIDeviceOrientationPortrait];
    }else {
        if (self.backCallBack) {self.backCallBack();}
    }
}

///下一集事件
-(void)mer_nextBtnAction:(UIView *)view button:(UIButton *)button {

    self.isPlayEnd = YES;
    if (self.VideoURLs.count == 0 || self.index == self.VideoURLs.count - 1) {
        //播放完成,显示重播
        [self.controlView playEnd];
        return;
    }
    
    [self resetPlayer];
    self.currentModel = self.VideoURLs[++self.index];
}

///slider的tap点击事件
-(void)mer_sliderTapAction:(UIView *)view sliderTapValue:(CGFloat)value {

    //获取资源的总时间
    CMTime totalTime    = self.player.currentItem.asset.duration;
    NSInteger drageTime = ((CGFloat)totalTime.value / (CGFloat)totalTime.timescale) * value;
    
    [self seekToTime:drageTime complitionHander:nil];
}

///选集事件
-(void)mer_listTableviewAction:(UIView *)view selectedIndexPath:(NSIndexPath *)indexPath {

    self.index = indexPath.row;
    [self resetPlayer];
    self.currentModel = self.VideoURLs[indexPath.row];
}

///重播点击事件
-(void)mer_replayBtnAction:(UIView *)view replayBtn:(UIButton *)button {
    
    [self seekToTime:0 complitionHander:nil];
    button.hidden = YES;
}

///选集点击事件
- (void)mer_albumBtnAction:(UIView *)view albumBtn:(UIButton *)button {

    self.isShowListView = YES;
}

///listview的cell点击事件
- (void)mer_albumClickAction:(UIView *)view {

    self.isShowListView = NO;
}

#pragma mark - setter
-(void)setControlView:(MER_PlayerControllerView *)controlView {
    if (_controlView) return;
    _controlView = controlView;
    [self insertSubview:controlView aboveSubview:self];
    [controlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.top.bottom.mas_equalTo(self);
    }];
    controlView.delegate = self;
}

-(void)setVideoURL:(NSString *)videoURL {
    _videoURL = videoURL;
    
    //有了url再创建手势
    [self creatGesture];
    [self creatPlayer:videoURL];
}

-(void)setVideoURLs:(NSArray *)VideoURLs {
    _VideoURLs = VideoURLs;
    
    self.index = 0;
    //有了url再创建手势
    [self creatGesture];
    self.currentModel = VideoURLs[self.index];
    self.controlView.datas = VideoURLs;
}

-(void)setCurrentModel:(MER_PlayModel *)currentModel {
    _currentModel = currentModel;
    [self removeGestureRecognizer:self.singleTag];
    [self removeGestureRecognizer:self.doubleTag];
    [self removeGestureRecognizer:self.panGes];
    [self creatGesture];
    [self creatPlayer:currentModel.videoURL];
    [self.controlView setSlectedModel:currentModel index:self.index];
}

#pragma mark - 设备方向
/// 手动切换设备方向
- (void)changeToOrientation:(UIDeviceOrientation)orientation
{
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = orientation;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}

- (UIDeviceOrientation)getDeviceOrientation
{
    return [UIDevice currentDevice].orientation;
}

@end
