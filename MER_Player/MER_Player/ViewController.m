//
//  ViewController.m
//  MER_Player
//
//  Created by 汉子MacBook－Pro on 2016/12/9.
//  Copyright © 2016年 不会爬树的熊. All rights reserved.
//

#import "ViewController.h"
#import "MER_MoviePlayerViewController.h"
#import "MER_PlayModel.h"

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *datas;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"首页";
    
    
    self.datas = [NSMutableArray array];
    MER_PlayModel * model = [[MER_PlayModel alloc]init];
    model.title = @"第一季";
    model.videoURL = @"http://baobab.wdjcdn.com/1456653443902B.mp4";
    
    MER_PlayModel * model2 = [[MER_PlayModel alloc]init];
    model2.title = @"第二季";
    model2.videoURL = @"http://baobab.wdjcdn.com/1456734464766B(13).mp4";
    
    MER_PlayModel * model3 = [[MER_PlayModel alloc]init];
    model3.title = @"第三季";
    model3.videoURL = @"http://baobab.wdjcdn.com/1455614108256t(2).mp4";
    
    [self.datas addObject:model];
    [self.datas addObject:model2];
    [self.datas addObject:model3];
    
}

- (IBAction)pushBtnAction:(UIButton *)sender {
    
    MER_MoviePlayerViewController * moviePlayerVC = [[MER_MoviePlayerViewController alloc]init];
    
    moviePlayerVC.datas = self.datas;
    
    [self.navigationController pushViewController:moviePlayerVC animated:YES];
    
}


@end
