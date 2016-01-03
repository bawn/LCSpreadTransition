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


@interface LCDetectScrollViewEndGestureRecognizer : UIPanGestureRecognizer
@property (nonatomic, weak) UIScrollView *scrollview;
@end

@interface LCSpreadTransitionAnimation : NSObject<UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, UIViewControllerInteractiveTransitioning, UINavigationControllerDelegate>

@property (nonatomic, assign, getter=isDragable) BOOL dragable;
@property (nonatomic, readonly) LCDetectScrollViewEndGestureRecognizer *gesture;
@property (nonatomic, assign) UIGestureRecognizer *gestureRecognizerToFailPan;
@property (nonatomic, assign) BOOL bounces;
@property (nonatomic, assign) CGFloat behindViewScale;
@property (nonatomic, assign) CGFloat behindViewAlpha;
@property (nonatomic, assign) CGFloat transitionDuration;


- (id)initWithModalViewController:(UIViewController *)modalViewController;
- (void)setContentScrollView:(UIScrollView *)scrollView;


@end
