//
//  MER_MoviePlayerViewController.m
//  MER_Player
//
//  Created by 汉子MacBook－Pro on 16/9/20.
//  Copyright © 2016年 不会爬树的熊. All rights reserved.
//

#import "MER_MoviePlayerViewController.h"

#import <AVFoundation/AVFoundation.h>
#import "MER_PlayerView.h"
#import "MER_PlayerControllerView.h"
#import "Masonry.h"
#import "MER_PlayModel.h"

@interface MER_MoviePlayerViewController ()
/** 播放的视图 */
@property (nonatomic, strong) MER_PlayerView *playerView;

//@property (nonatomic, strong) NSMutableArray *datas;

@end

@implementation MER_MoviePlayerViewController

-(void)dealloc {
    NSLog(@"销毁了");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"MoviePlayer";
    
    self.view.backgroundColor = [UIColor colorWithRed:((float)arc4random_uniform(256) / 255.0) green:((float)arc4random_uniform(256) / 255.0) blue:((float)arc4random_uniform(256) / 255.0) alpha:1.0];
    
//    self.datas = [NSMutableArray array];
//    MER_PlayModel * model = [[MER_PlayModel alloc]init];
//    model.title = @"第一季";
//    model.videoURL = @"http://baobab.wdjcdn.com/1456653443902B.mp4";
//    
//    MER_PlayModel * model2 = [[MER_PlayModel alloc]init];
//    model2.title = @"第二季";
//    model2.videoURL = @"http://baobab.wdjcdn.com/1456734464766B(13).mp4";
//    
//    MER_PlayModel * model3 = [[MER_PlayModel alloc]init];
//    model3.title = @"第三季";
//    model3.videoURL = @"http://baobab.wdjcdn.com/1455614108256t(2).mp4";
//    
//    [self.datas addObject:model];
//    [self.datas addObject:model2];
//    [self.datas addObject:model3];
    
    [self prepareUI];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    self.tabBarController.tabBar.hidden = YES;
}

#pragma mark - UI
- (void)prepareUI {
    
    MER_PlayerControllerView * controlView = [[MER_PlayerControllerView alloc]init];
    __weak typeof(self) weakself = self;
    self.playerView = [MER_PlayerView mer_setControlView:controlView videoURLs:self.datas];
    [self.view addSubview:self.playerView];
    [self.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view);
        make.leading.trailing.mas_equalTo(0);
        // 这里宽高比16：9
        make.height.mas_equalTo(self.playerView.mas_width).multipliedBy(9.0f/16.0f);
    }];
    
    //返回按钮的回调
    self.playerView.backCallBack = ^{
        [weakself.navigationController popViewControllerAnimated:YES];
    };
}


@end
