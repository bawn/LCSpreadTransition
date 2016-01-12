//
//  LCPinterestTransitionAnimation.h
//  LCDragableModalTransition
//
//  Created by bawn on 12/27/15.
//  Copyright © 2015 bawn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

typedef NS_ENUM(NSUInteger, LCSpreadTransitionDirection) {
    LCSpreadTransitionDirectionBottom,// 从上往下dismiss
    LCSpreadTransitionDirectionTop,// 从下往上dismiss
    LCSpreadTransitionDirectionRight,// 从左往右dismiss
};

@interface LCDetectScrollViewEndGestureRecognizer : UIScreenEdgePanGestureRecognizer
@property (nonatomic, weak) UIScrollView *scrollview;
@property (nonatomic, assign) LCSpreadTransitionDirection direction;

@end

@interface LCSpreadTransitionAnimation : NSObject<UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, UIViewControllerInteractiveTransitioning>

@property (nonatomic, assign, getter=isDragable) BOOL dragable;
@property (nonatomic, readonly) LCDetectScrollViewEndGestureRecognizer *gesture;
@property (nonatomic, assign) UIGestureRecognizer *gestureRecognizerToFailPan;
@property (nonatomic, assign) BOOL bounces;
@property (nonatomic, assign) CGFloat behindViewScale;
@property (nonatomic, assign) CGFloat behindViewAlpha;
@property (nonatomic, assign) CGFloat transitionDuration;
@property (nonatomic, assign) CGFloat topMargin;



- (id)initWithModalViewController:(UIViewController *)modalViewController;
- (void)setContentScrollView:(UIScrollView *)scrollView;


@end
