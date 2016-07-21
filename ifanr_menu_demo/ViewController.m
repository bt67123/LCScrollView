//
//  ViewController.m
//  ifanr_menu_demo
//
//  Created by 罗楚健 on 16/7/15.
//  Copyright © 2016年 lcj. All rights reserved.
//

#import "LC.h"
#import "ViewController.h"

@interface ViewController () <UIScrollViewDelegate>
@property (nonatomic, strong) LCScrollView *scrollView;
@property (nonatomic, strong) LCScrollViewDelegateContainer *scrollViewDelegateContainer;
@property (nonatomic, assign) LC_SCROLLVIEW_STATE scrollViewState;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    [self setupUI];
}

- (void)setupUI {
    NSArray *imgs = @[@"IMG_1", @"IMG_4322", @"IMG_4323", @"IMG_4324", @"IMG_4325"];
    NSMutableArray *views = [NSMutableArray array];
    for (int i = 0; i < imgs.count; i ++) {
        UIImageView *testView = [[UIImageView alloc] init];
        [testView setImage:[UIImage imageNamed:imgs[i]]];
        [views addObject:testView];
    }
    
    self.scrollView = [[LCScrollView alloc] initWithChildViews:views];
    
    self.scrollViewDelegateContainer = [[LCScrollViewDelegateContainer alloc] init];
    _scrollViewDelegateContainer.firstDelegate = _scrollView;
    _scrollViewDelegateContainer.secondDelegate = self;
    _scrollView.delegate = (id)_scrollViewDelegateContainer;
    
    [self.view addSubview:_scrollView];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    NSLog(@"view controller");
}

@end
