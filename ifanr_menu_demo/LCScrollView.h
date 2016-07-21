//
//  LCScrollView.h
//  ifanr_menu_demo
//
//  Created by 罗楚健 on 16/7/15.
//  Copyright © 2016年 lcj. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSInteger {
    LC_SCROLLVIEW_STATE_DEFAULT = 0,
    LC_SCROLLVIEW_STATE_CLOSE = LC_SCROLLVIEW_STATE_DEFAULT,
    LC_SCROLLVIEW_STATE_OPEN = 1,
    LC_SCROLLVIEW_STATE_ANIMATING = 2,
} LC_SCROLLVIEW_STATE;

@interface LCScrollView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic, strong, nullable) NSMutableArray *childViews;
- (nullable instancetype)initWithChildViews:(nullable NSArray *)childViews;

@end


/**
 *  delegate 转发器
 */
@interface LCScrollViewDelegateContainer : NSObject
@property (nonnull, assign) id<UIScrollViewDelegate> firstDelegate;
@property (nonnull, assign) id<UIScrollViewDelegate> secondDelegate;
@end
