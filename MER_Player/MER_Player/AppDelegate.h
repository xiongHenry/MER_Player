//
//  AppDelegate.h
//  MER_Player
//
//  Created by 汉子MacBook－Pro on 2016/12/9.
//  Copyright © 2016年 不会爬树的熊. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

