//
//  LCScrollView.m
//  ifanr_menu_demo
//
//  Created by 罗楚健 on 16/7/15.
//  Copyright © 2016年 lcj. All rights reserved.
//

#import "LCScrollView.h"

#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height
#define RGBA(r, g, b, a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define RGB(r, g, b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]

#define PAGE_WIDTH    SCREEN_WIDTH
#define PAGE_HEIGHT   (SCREEN_HEIGHT-20)
#define SCALE         0.46 // scrollview 缩小倍数
#define PAGE_NUM      5    // 页面数
#define PAGE_DIVIDE   5    // 间隙长度
#define ANIM_DURATION 5  // 动画时间

@interface LCScrollView () <UIGestureRecognizerDelegate, UIScrollViewDelegate> {
    CGSize _openContentSize;
    CGSize _closeContentSize;
    NSNotification *_notification;
    BOOL _decelerating;
}
@property (nonatomic, assign) LC_SCROLLVIEW_STATE scrollViewState;
@property (nonatomic, assign) int currentPage;

@property (nonatomic, strong) UIButton *closeBtn;

@property (nonatomic, assign) id<UIScrollViewDelegate> myDelegate;
@end

@implementation LCScrollView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithChildViews:(NSArray *)childViews {
    self = [super initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    if (self) {
        self.childViews = [NSMutableArray arrayWithArray:childViews];
        [self setupUI];
    }
    return self;
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    
    // close btn
    [self.superview addSubview:self.closeBtn];
    _closeBtn.alpha = 0;
    
}

- (void)setupUI {
    _openContentSize = CGSizeMake(_childViews.count * (SCREEN_WIDTH + PAGE_DIVIDE), 0);
    _closeContentSize = CGSizeMake(_childViews.count * (SCREEN_WIDTH + PAGE_DIVIDE) - PAGE_DIVIDE, 0);
    
    self.contentSize = _closeContentSize;
    self.layer.masksToBounds = NO; // 让超出的试图都能显示
    
    for (int i = 0; i < _childViews.count; i ++) {
        UIView *childView = [_childViews objectAtIndex:i];
        childView.frame = CGRectMake(i * (PAGE_WIDTH + PAGE_DIVIDE), 0, PAGE_WIDTH, PAGE_HEIGHT);
        childView.layer.cornerRadius = 20;
        childView.layer.masksToBounds = YES;
        [self addSubview:childView];
    }
    
    // 缩小scrollView
    self.transform = CGAffineTransformMakeScale(SCALE, SCALE);
    self.frame = CGRectMake(0, SCREEN_HEIGHT-(SCREEN_HEIGHT*SCALE), SCREEN_WIDTH, SCREEN_HEIGHT*SCALE);
    
    // swipe touch event
    UISwipeGestureRecognizer *upGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeEvent:)];
    upGesture.delegate = self;
    upGesture.direction = UISwipeGestureRecognizerDirectionUp;
    [self addGestureRecognizer:upGesture];
    
    UISwipeGestureRecognizer *downGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeEvent:)];
    downGesture.delegate = self;
    downGesture.direction = UISwipeGestureRecognizerDirectionDown;
    [self addGestureRecognizer:downGesture];
    
    UISwipeGestureRecognizer *leftGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeEvent:)];
    leftGesture.delegate = self;
    leftGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    [self addGestureRecognizer:leftGesture];
    
    UISwipeGestureRecognizer *rightGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeEvent:)];
    rightGesture.delegate = self;
    rightGesture.direction = UISwipeGestureRecognizerDirectionRight;
    [self addGestureRecognizer:rightGesture];
    
    // pan
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panEvent:)];
    panGesture.delegate = self;
    [panGesture setMaximumNumberOfTouches:1]; // 最多只能由一根手指触发事件
    [self addGestureRecognizer:panGesture];
    
    // tap
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapEvent:)];
    tapGesture.delegate = self;
    [self addGestureRecognizer:tapGesture];
    
    //
    self.myDelegate = self;
}

- (UIButton *)closeBtn {
    if (!_closeBtn) {
        _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _closeBtn.frame = CGRectMake(self.frame.size.width - 45 - 18, 40, 45, 45);
        [_closeBtn addTarget:self action:@selector(onCloseBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        _closeBtn.layer.cornerRadius = _closeBtn.frame.size.width/2.0;
        _closeBtn.backgroundColor = [UIColor blackColor];
    }
    return _closeBtn;
}

- (void)onCloseBtnClicked:(UIButton *)sender {
    [self doAnimation:NO withPage:_currentPage];
}

- (void)tapEvent:(UITapGestureRecognizer *)recognizer {
    if (_scrollViewState == LC_SCROLLVIEW_STATE_OPEN ||
        _scrollViewState == LC_SCROLLVIEW_STATE_ANIMATING ||
        _decelerating) {
        return;
    }
    CGPoint point = [recognizer locationInView:[self superview]];
    [self doAnimation:YES withPage:[self pageOfTouch:point]];
}

- (void)panEvent:(UIPanGestureRecognizer *)recognizer {
    if (_scrollViewState == LC_SCROLLVIEW_STATE_OPEN) {
        return;
    }
    
    static CGPoint beginPoint;
    static CGPoint lastPoint;
    static BOOL isLastActionUp; // 最后一个动作是否向上移动
    CGPoint point = [recognizer locationInView:self.superview];
    
//    CGFloat offsetY = point.y - beginPoint.y;
    CGFloat offsetX = point.x - beginPoint.x;
    
    CGFloat k = (SCALE * (SCREEN_HEIGHT - point.y)) / (SCREEN_HEIGHT - beginPoint.y);
    /**
     *  当到达临界点，增大缩小速度变慢
     */
    if (k >= 1) {
        k = 1 + (k-1)*0.3;
    } else if (k <= SCALE) {
        k = SCALE - (SCALE - k) * 0.3;
    }
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(k, k);
    CGAffineTransform translationTransform = CGAffineTransformMakeTranslation(0, 0);
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            beginPoint = point;
            break;
        }
        case UIGestureRecognizerStateChanged: {
            if (!self.scrollEnabled) {
                _scrollViewState = LC_SCROLLVIEW_STATE_ANIMATING;
                if (k < 1.8) { // 放大到1.8倍的时候就停止放大
                    self.transform = CGAffineTransformConcat(scaleTransform, translationTransform);
                    [self moveScrollViewWithRate:k offsetX:offsetX];
                }
                
                if (lastPoint.y - point.y > 0) {
                    isLastActionUp = YES;
                } else {
                    isLastActionUp = NO;
                }
                
                lastPoint = point;
            }
            break;
        }
        case UIGestureRecognizerStateEnded: {
            if (!self.scrollEnabled) {
                if (isLastActionUp) {
                    self.contentSize = _openContentSize;
                } else {
                    self.contentSize = _closeContentSize;
                }
                
                int page;
                if (isLastActionUp) {
                    page = [self pageOfTouch:beginPoint];
                    _currentPage = page;
                } else {
                    page = _currentPage;
                }
                [self doAnimation:isLastActionUp withPage:page];
            }
            
            self.scrollEnabled = YES;
            beginPoint = CGPointZero;
            lastPoint = CGPointZero;
        }
        default:
            break;
    }
}

- (int)pageOfTouch:(CGPoint)beginPoint {
    int page = (beginPoint.x + self.contentOffset.x * SCALE) / ((SCREEN_WIDTH + PAGE_DIVIDE)*SCALE);
    return page;
}

/**
 *  打开关闭动画
 *
 *  @param shouldOpen
 */
- (void)doAnimation:(BOOL)shouldOpen withPage:(int)page {
    if (shouldOpen) {
        _scrollViewState = LC_SCROLLVIEW_STATE_OPEN;
        self.pagingEnabled = YES;
        self.contentSize = _openContentSize;
    } else {
        _scrollViewState = LC_SCROLLVIEW_STATE_CLOSE;
        self.pagingEnabled = NO;
        self.contentSize = _closeContentSize;
    }
    
    [UIView animateWithDuration:ANIM_DURATION delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        if (shouldOpen) {
            [self setContentOffset:CGPointMake((SCREEN_WIDTH + PAGE_DIVIDE)*page, self.contentOffset.y)];
            self.transform = CGAffineTransformIdentity;
            self.frame = CGRectMake(0, 0, SCREEN_WIDTH+5, SCREEN_HEIGHT);
            
            self.closeBtn.alpha = 1;
        } else {
            self.transform = CGAffineTransformMakeScale(SCALE, SCALE);
            self.frame = CGRectMake(0, SCREEN_HEIGHT-(SCREEN_HEIGHT*SCALE), SCREEN_WIDTH, SCREEN_HEIGHT*SCALE);
            
            self.closeBtn.alpha = 0;
        }
    } completion:^(BOOL finished) {

    }];
    
    for (UIView *childView in _childViews) {
        if (shouldOpen) {
            childView.layer.cornerRadius = 0;
            childView.layer.masksToBounds = NO;
        } else {
            childView.layer.cornerRadius = 20;
            childView.layer.masksToBounds = YES;
        }
    }
}

/**
 *  手指滑动时动画
 *
 *  @param rate    倍率
 *  @param offsetX x偏移量
 */
- (void)moveScrollViewWithRate:(CGFloat)rate offsetX:(CGFloat)offsetX {
    CGRect frame = self.frame;
    /**
     *  一开始放大根据底部向上放大，知道顶部到达屏幕顶部后根据顶部向下放大
     */
    if (rate > 1) {
        frame.origin.y = 0;
    } else {
        frame.origin.y = SCREEN_HEIGHT - frame.size.height;
    }
    frame.origin.x = offsetX - (SCREEN_WIDTH * (rate - SCALE)); // 实现scrollview跟随者手指移动
    self.frame = frame;
}

- (void)swipeEvent:(UISwipeGestureRecognizer *)recognizer {
    switch (recognizer.direction) {
        case UISwipeGestureRecognizerDirectionRight:
        case UISwipeGestureRecognizerDirectionLeft:
            self.scrollEnabled = YES;
            break;
        case UISwipeGestureRecognizerDirectionUp:
        case UISwipeGestureRecognizerDirectionDown:
            self.scrollEnabled = NO;
            break;
        default:
            break;
    }
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
//    if (_scrollViewState == LC_SCROLLVIEW_STATE_ANIMATING) {
//        return NO;
//    }
    return YES;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    _decelerating = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    _decelerating = NO;
}

@end


@implementation LCScrollViewDelegateContainer

- (void)forwardInvocation:(NSInvocation *)anInvocation{
    SEL aSelector = [anInvocation selector];
    if([self.firstDelegate respondsToSelector:aSelector]){
        [anInvocation invokeWithTarget:self.firstDelegate];
    }
    if([self.secondDelegate respondsToSelector:aSelector]){
        [anInvocation invokeWithTarget:self.secondDelegate];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector{
    NSMethodSignature *first = [(NSObject *)self.firstDelegate methodSignatureForSelector:aSelector];
    NSMethodSignature *second = [(NSObject *)self.secondDelegate methodSignatureForSelector:aSelector];
    if(first){
        return first;
    } else if(second) {
        return second;
    }
    return nil;
}

- (BOOL)respondsToSelector:(SEL)aSelector{
    if([self.firstDelegate respondsToSelector:aSelector] || [self.secondDelegate respondsToSelector:aSelector]){
        return YES;
    } else {
        return NO;
    }
}

@end
