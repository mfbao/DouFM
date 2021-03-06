//
//  RootViewController.m
//  DouFM
//
//  Created by Pasco on 16/5/9.
//  Copyright © 2016年 Pasco. All rights reserved.
//

#import "RootViewController.h"
#import "TabBarViewController.h"
#import "MenuViewController.h"
#import "ExploreTableViewController.h"
#import "FirstUseGuideView.h"

@interface RootViewController ()<UIGestureRecognizerDelegate, CloseSideMenuDelegate>

@property (strong, nonatomic) TabBarViewController *tabBarViewController;
@property (strong, nonatomic) MenuViewController *menuViewController;
@property (strong, nonatomic) UIImageView *backgroundImageView;
@property (strong, nonatomic) UIButton *backgroundButton;
@property (strong, nonatomic) FirstUseGuideView *firstUseGuideView;
@property (assign, nonatomic) BOOL isSlided;
@property (assign, nonatomic) CGFloat viewOffset;
@property (strong, nonatomic) UIPanGestureRecognizer *panGestureRecognizer;
@property (strong, nonatomic) UIScreenEdgePanGestureRecognizer *edgePanGestureRecognizer;

@end

@implementation RootViewController

- (void)loadView {
    [super loadView];
    [self configtureViewControllers];
    [self configtureViews];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureGesture];
    self.panGestureRecognizer.delegate = self;
    self.edgePanGestureRecognizer.delegate = self;
    
    self.menuViewController.delegate = self.tabBarViewController.exploreViewController;
    self.tabBarViewController.exploreViewController.delegate = self;
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"]) {
        self.firstUseGuideView = [[FirstUseGuideView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:self.firstUseGuideView];
        [self.firstUseGuideView addGestureRecognizer:[[UIPanGestureRecognizer alloc] init]];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeFirstUseGuideView)];
        [self.firstUseGuideView addGestureRecognizer:tap];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedOnce"];
    }
    
    
}


#pragma mark - configtures

- (void)configtureViewControllers {
    self.menuViewController = [[MenuViewController alloc] init];
    [self addChildViewController:self.menuViewController];
    self.tabBarViewController = [[TabBarViewController alloc] init];
    [self addChildViewController:self.tabBarViewController];
    
}

- (void)configtureViews {
    self.backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"backgroundimage_1"]];
    self.backgroundImageView.frame = self.view.bounds;
    [self.view addSubview:self.backgroundImageView];
    
    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurEffectView.frame = self.view.bounds;
    [self.backgroundImageView addSubview:blurEffectView];
    
    
    self.menuViewController.view.frame = CGRectMake(0, 0, kScreenWidth/2, kScreenHeight);
    [self.view addSubview:self.menuViewController.view];
    
    [self.view addSubview:self.tabBarViewController.view];

    self.backgroundButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.backgroundButton.frame = [UIScreen mainScreen].bounds;
    self.backgroundButton.backgroundColor = [UIColor blackColor];
    self.backgroundButton.alpha = 0.0;
    self.backgroundButton.hidden = YES;
    [self.view addSubview:self.backgroundButton];
    [self.backgroundButton addTarget:self action:@selector(closeSideMenu) forControlEvents:UIControlEventTouchUpInside];
    
    self.isSlided = NO;
    self.viewOffset = self.tabBarViewController.view.frame.origin.x;
    
}

-(void)configureGesture {
    self.edgePanGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handleEdgePanGestureRecognizer:)];
    self.edgePanGestureRecognizer.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:self.edgePanGestureRecognizer];
    
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGestureRecognizer:)];
    [self.view addGestureRecognizer:self.panGestureRecognizer];
    
    
}

-(void)handleEdgePanGestureRecognizer:(UIScreenEdgePanGestureRecognizer *)edgePanGestureRecognizer {
    
}

- (void)handlePanGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
    CGPoint location = [panGestureRecognizer translationInView:self.tabBarViewController.view];
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            self.backgroundButton.hidden = NO;
            break;
        }
        case UIGestureRecognizerStateChanged: {
            CGFloat offset = self.tabBarViewController.view.frame.origin.x;
            CGRect tempFrame = CGRectMake(MAX(MIN(self.viewOffset + location.x, kScreenWidth/3.0*2.0),0), 0, kScreenWidth, kScreenHeight);
            self.tabBarViewController.view.frame = tempFrame;
            
            CGFloat progress = (offset/kScreenWidth)/2.0;
            self.backgroundButton.alpha = MIN(0.3, progress);
            self.backgroundButton.frame = tempFrame;
            break;
        }
        case UIGestureRecognizerStateEnded: {
            //            self.endLocationX = location.x;
            CGFloat velocity = [panGestureRecognizer velocityInView:self.view].x;
            //如果主视图已经是处于划开状态
            if (self.isSlided == YES) {
                //如果主视图位置小于屏幕的1/3，或者滑动速度小于-800，则关闭划开的状态
                if (self.tabBarViewController.view.frame.origin.x < kScreenWidth/3.0 || velocity < -800) {
                    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:1.0 initialSpringVelocity:3.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                        CGRect tempFrame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
                        self.tabBarViewController.view.frame = tempFrame;
                        self.backgroundButton.frame = tempFrame;
                        self.backgroundButton.alpha = 0;
                    } completion:^(BOOL finished) {
                        self.isSlided = NO;
                        self.backgroundButton.hidden = YES;
                        self.viewOffset = self.tabBarViewController.view.frame.origin.x;
                    }];
                } else {
                    //否则继续保持划开的状态
                    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                        CGRect tempFrame = CGRectMake(kScreenWidth/3*2, 0, kScreenWidth, kScreenHeight);
                        self.tabBarViewController.view.frame = tempFrame;
                        self.backgroundButton.frame = tempFrame;
                        self.backgroundButton.alpha = 0.3;
                    } completion:^(BOOL finished) {
                        self.isSlided = YES;
                        self.backgroundButton.hidden = NO;
                        [self.tabBarViewController.view bringSubviewToFront:self.backgroundButton];
                        self.viewOffset = self.tabBarViewController.view.frame.origin.x;
                    }];
                }
            }else {
                //如果主视图处于关闭的状态
                //如果主视图位置大于屏幕的1/3，或者滑动速度大于800，则把主视图划开
                if (self.tabBarViewController.view.frame.origin.x > kScreenWidth/3 || velocity > 800) {
                    [UIView animateWithDuration:0.2 delay:0 usingSpringWithDamping:1.0 initialSpringVelocity:3.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                        CGRect tempFrame = CGRectMake(kScreenWidth/3*2, 0, kScreenWidth, kScreenHeight);
                        self.tabBarViewController.view.frame = tempFrame;
                        self.backgroundButton.frame = tempFrame;
                        self.backgroundButton.alpha = 0.3;
                    } completion:^(BOOL finished) {
                        self.isSlided = YES;
                        self.backgroundButton.hidden = NO;
                        [self.tabBarViewController.view bringSubviewToFront:self.backgroundButton];
                        self.viewOffset = self.tabBarViewController.view.frame.origin.x;
                    }];
                } else {
                    //否则继续保持关闭状态
                    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                        CGRect tempFrame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
                        self.tabBarViewController.view.frame = tempFrame;
                        self.backgroundButton.frame = tempFrame;
                        self.backgroundButton.alpha = 0;
                    } completion:^(BOOL finished) {
                        self.isSlided = NO;
                        self.backgroundButton.hidden = YES;
                        self.viewOffset = self.tabBarViewController.view.frame.origin.x;
                    }];
                }
            }
            break;
        }
        case UIGestureRecognizerStateCancelled: {
            break;
        }
        case UIGestureRecognizerStatePossible: {
            break;
        }
        case UIGestureRecognizerStateFailed: {
            break;
        }
    }
}

#pragma mark - change playlist

- (void)closeSideMenu {
    //否则继续保持关闭状态
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        CGRect tempFrame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
        self.tabBarViewController.view.frame = tempFrame;
        self.backgroundButton.frame = tempFrame;
        self.backgroundButton.alpha = 0;
    } completion:^(BOOL finished) {
        self.isSlided = NO;
        self.backgroundButton.hidden = YES;
        self.viewOffset = self.tabBarViewController.view.frame.origin.x;
    }];
}

- (void)removeFirstUseGuideView {
    [self.firstUseGuideView removeFromSuperview];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
