//
//  LCPinterestTransitionAnimation.m
//  LCDragableModalTransition
//
//  Created by bawn on 12/27/15.
//  Copyright © 2015 bawn. All rights reserved.
//

#import "LCSpreadTransitionAnimation.h"
#import "LCSpreadTransitionProtocol.h"
#import "UICollectionView+IndexPath.h"


@interface LCSpreadTransitionAnimation ()<UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIViewController *modalController;
@property (nonatomic, strong) LCDetectScrollViewEndGestureRecognizer *gesture;
@property (nonatomic, strong) id<UIViewControllerContextTransitioning> transitionContext;
@property (nonatomic, assign) CGFloat panLocationStart;
@property (nonatomic, assign) BOOL presenting;
@property (nonatomic, assign) BOOL isInteractive;
@property (nonatomic, assign) CATransform3D tempTransform;
@property (nonatomic, strong) UIView *screenSnapShotView;
@property (nonatomic, strong) UIView *cellSnapShotView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, assign) CGRect screenBounds;


@end

@implementation LCSpreadTransitionAnimation

- (id)initWithModalViewController:(UIViewController *)modalViewController{
    self = [super init];
    if (self) {
        _modalController = modalViewController;
        [self initialization];
    }
    return self;
}

- (void)initialization{
    
    self.dragable = NO;
    self.bounces = YES;
    self.behindViewScale = 0.9f;
    self.behindViewAlpha = 1.0f;
    self.transitionDuration = 0.8f;
    
    self.screenBounds = [UIScreen mainScreen].bounds;
    
    self.contentView = [[UIView alloc] init];
    self.contentView.backgroundColor = [UIColor whiteColor];
}

- (void)setBehindViewAlpha:(CGFloat)behindViewAlpha{
    _behindViewAlpha = 1.0f - behindViewAlpha;
}

- (void)setDragable:(BOOL)dragable
{
    _dragable = dragable;
    if (_dragable) {
        [self removeGestureRecognizerFromModalController];
        self.gesture = [[LCDetectScrollViewEndGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        self.gesture.delegate = self;
        self.gesture.edges = UIRectEdgeLeft;
        
        [self.modalController.view addGestureRecognizer:self.gesture];
    } else {
        [self removeGestureRecognizerFromModalController];
    }
}


- (void)removeGestureRecognizerFromModalController
{
    if (self.gesture && [self.modalController.view.gestureRecognizers containsObject:self.gesture]) {
        [self.modalController.view removeGestureRecognizer:self.gesture];
        self.gesture = nil;
    }
}

//- (void)setBehindViewAlpha:(CGFloat)behindViewAlpha{
//    _behindViewAlpha = behindViewAlpha;
//    self.backgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:_behindViewAlpha];
//}


- (void)setContentScrollView:(UIScrollView *)scrollView{
    
    if (!self.dragable) {
        self.dragable = YES;
    }
    self.gesture.scrollview = scrollView;
    [self.gesture.scrollview addObserver:self forKeyPath:@"panGestureRecognizer.state" options:NSKeyValueObservingOptionNew context:nil];
//    [self.gesture.scrollview addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];

}

# pragma mark - Gesture


- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    // Location reference
    CGPoint location = [recognizer locationInView:self.modalController.view.window];
    location = CGPointApplyAffineTransform(location, CGAffineTransformInvert(recognizer.view.transform));
    // Velocity reference
    CGPoint velocity = [recognizer velocityInView:[self.modalController.view window]];
    velocity = CGPointApplyAffineTransform(velocity, CGAffineTransformInvert(recognizer.view.transform));
    
    BOOL isHorizontalGesture = fabs(velocity.y) <= fabs(velocity.x);
    if (recognizer.state == UIGestureRecognizerStateBegan && isHorizontalGesture) {
    
        [self.contentView removeFromSuperview];
        self.contentView = nil;
        
        self.isInteractive = YES;
        if (self.gesture.direction == LCSpreadTransitionDirectionRight) {
            self.panLocationStart = location.x;
        }
        else{
            self.panLocationStart = location.y;
        }
        [self.modalController dismissViewControllerAnimated:YES completion:nil];
        
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGFloat animationRatio = 0.0f;
        
        if (self.gesture.direction == LCSpreadTransitionDirectionRight) {
            animationRatio = (location.x - self.panLocationStart) / (CGRectGetWidth([self.modalController view].bounds));
        }
        else {
            animationRatio = (location.y - self.panLocationStart) / (CGRectGetHeight([self.modalController view].bounds));
        }
        
        [self updateInteractiveTransition:animationRatio];
        
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        CGFloat velocityForSelectedDirection = 0.0f;
        CGFloat offset = 0.0f;
        if (self.gesture.direction == LCSpreadTransitionDirectionRight) {
            velocityForSelectedDirection = velocity.x;
            offset = self.modalController.view.frame.origin.x;
        } else {
            velocityForSelectedDirection = velocity.y;
            offset = self.modalController.view.frame.origin.y;
        }
        
        if (ABS(offset) > self.topMargin) {
            
            [self finishInteractiveTransition];
        }
        else {
            [self cancelInteractiveTransition];
        }

        self.isInteractive = NO;
    }
}

#pragma mark -

-(void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    self.transitionContext = transitionContext;
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    toViewController.view.hidden = YES;
    
    if (![self isPriorToIOS8]) {
        self.screenSnapShotView.layer.transform = CATransform3DScale(self.screenSnapShotView.layer.transform, self.behindViewScale, self.behindViewScale, 1);
    }
    
    self.tempTransform = self.screenSnapShotView.layer.transform;
    self.screenSnapShotView.alpha = self.behindViewAlpha;
    
    if (fromViewController.modalPresentationStyle == UIModalPresentationFullScreen) {
        [[transitionContext containerView] addSubview:toViewController.view];
    }
    [[transitionContext containerView] bringSubviewToFront:fromViewController.view];
}


- (void)updateInteractiveTransition:(CGFloat)percentComplete
{
//    if (!self.bounces && percentComplete < 0) {
//        percentComplete = 0;
//    }
//    NSLog(@"%f", percentComplete);
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
//    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    CATransform3D transform = CATransform3DMakeScale(
                                                     1 + (((1 / self.behindViewScale) - 1) * ABS(percentComplete)),
                                                     1 + (((1 / self.behindViewScale) - 1) * ABS(percentComplete)), 1);
    self.screenSnapShotView.layer.transform = CATransform3DConcat(self.tempTransform, transform);
    self.screenSnapShotView.alpha =  (self.behindViewAlpha) + ((1.0f - self.behindViewAlpha) * ABS(percentComplete));
    

    
    CGRect updateRect;
    
    if (self.gesture.direction == LCSpreadTransitionDirectionRight) {
        updateRect = CGRectMake(CGRectGetWidth(fromViewController.view.bounds) * percentComplete,
                                0,
                                CGRectGetWidth(fromViewController.view.frame),
                                CGRectGetHeight(fromViewController.view.frame));
    }
    else{
        updateRect = CGRectMake(0,
                                (CGRectGetHeight(fromViewController.view.bounds) * percentComplete),
                                CGRectGetWidth(fromViewController.view.frame),
                                CGRectGetHeight(fromViewController.view.frame));
    }
    
    // reset to zero if x and y has unexpected value to prevent crash
    if (isnan(updateRect.origin.x) || isinf(updateRect.origin.x)) {
        updateRect.origin.x = 0;
    }
    if (isnan(updateRect.origin.y) || isinf(updateRect.origin.y)) {
        updateRect.origin.y = 0;
    }
    
    CGPoint transformedPoint = CGPointApplyAffineTransform(updateRect.origin, fromViewController.view.transform);
    updateRect = CGRectMake(transformedPoint.x, transformedPoint.y, updateRect.size.width, updateRect.size.height);
    
    fromViewController.view.frame = updateRect;
}


- (void)finishInteractiveTransition
{
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    CGRect endRect;
    
    if (self.gesture.direction == LCSpreadTransitionDirectionBottom) {
        endRect = CGRectMake(0,
                             CGRectGetHeight(fromViewController.view.bounds),
                             CGRectGetWidth(fromViewController.view.frame),
                             CGRectGetHeight(fromViewController.view.frame));
    }
    else if (self.gesture.direction == LCSpreadTransitionDirectionTop) {
        endRect = CGRectMake(0,
                             -CGRectGetHeight(fromViewController.view.bounds),
                             CGRectGetWidth(fromViewController.view.frame),
                             CGRectGetHeight(fromViewController.view.frame));
    }
    else if (self.gesture.direction == LCSpreadTransitionDirectionRight) {
        endRect = CGRectMake(CGRectGetWidth(fromViewController.view.bounds),
                             0,
                             CGRectGetWidth(fromViewController.view.frame),
                             CGRectGetHeight(fromViewController.view.frame));
    }

    
    CGPoint transformedPoint = CGPointApplyAffineTransform(endRect.origin, fromViewController.view.transform);
    endRect = CGRectMake(transformedPoint.x, transformedPoint.y, endRect.size.width, endRect.size.height);
    
    if (fromViewController.modalPresentationStyle == UIModalPresentationCustom) {
        [toViewController beginAppearanceTransition:YES animated:YES];
    }
    
    [UIView animateWithDuration:0.3 delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.screenSnapShotView.alpha = 1.0f;
        self.screenSnapShotView.layer.transform = CATransform3DIdentity;
        fromViewController.view.frame = endRect;
        
    }completion:^(BOOL finished) {
        toViewController.view.hidden = NO;
        self.screenSnapShotView.hidden = YES;
        if (fromViewController.modalPresentationStyle == UIModalPresentationCustom) {
            [toViewController endAppearanceTransition];
        }
        [self.gesture.scrollview removeObserver:self forKeyPath:@"panGestureRecognizer.state"];
        [transitionContext completeTransition:YES];
    }];
}

- (void)cancelInteractiveTransition
{
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    [UIView animateWithDuration:0.4 delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
        
        self.screenSnapShotView.layer.transform = self.tempTransform;
        self.screenSnapShotView.alpha =  self.behindViewAlpha;

        
        fromViewController.view.frame = CGRectMake(0,0,
                                                   CGRectGetWidth(fromViewController.view.frame),
                                                   CGRectGetHeight(fromViewController.view.frame));
        
    } completion:^(BOOL finished) {
        self.gesture.direction = LCSpreadTransitionDirectionBottom;
        [transitionContext completeTransition:NO];
        if (fromViewController.modalPresentationStyle == UIModalPresentationFullScreen) {
            [toViewController.view removeFromSuperview];
        }
    }];
}


- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext{
    if (self.presenting) {
        return 1.3f;
    }
    else{
        return 0.35;
    }
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext{
    
    if (self.isInteractive) {
        return;
    }
    
    UIView *containerView = [transitionContext containerView];
    if (self.presenting) {
        
        UINavigationController *fromViewControllerNAV = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
        UIViewController *fromViewController = fromViewControllerNAV.topViewController;
        
        UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        
        UIView *fromView = fromViewControllerNAV.view;
        UIView *toView = toViewController.view;
        toView.alpha = 0.0f;
        
        CGRect endRect = CGRectMake(0,
                                    CGRectGetHeight(fromViewController.view.bounds),
                                    CGRectGetWidth(fromViewController.view.frame),
                                    CGRectGetHeight(fromViewController.view.frame));

        toView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        CGPoint transformedPoint = CGPointApplyAffineTransform(endRect.origin, fromViewController.view.transform);
        endRect = CGRectMake(transformedPoint.x, transformedPoint.y, endRect.size.width, endRect.size.height);

        
        UICollectionView *waterFallView = nil;
        if ([fromViewController respondsToSelector:@selector(collectionViewForTransition)]) {
            waterFallView = [(id<LCSpreadControllerProtocol>)fromViewController collectionViewForTransition];
        }
        UICollectionViewCell *cell = [waterFallView cellForItemAtIndexPath:waterFallView.selectedIndexPath];
        CGPoint point = [cell convertPoint:CGPointZero toView:fromView];
        
        self.screenSnapShotView = [fromView snapshotViewAfterScreenUpdates:YES];
        
        fromView.hidden = YES;
        [containerView insertSubview:self.screenSnapShotView aboveSubview:fromView];

        [containerView addSubview:self.contentView];
        self.contentView.frame = CGRectMake(0, point.y, self.screenBounds.size.width, cell.frame.size.height);
        
        self.cellSnapShotView = [self.screenSnapShotView snapshotViewAfterScreenUpdates:YES];
        CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
        shapeLayer.frame = self.contentView.bounds;
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.contentView.frame];
        shapeLayer.path = path.CGPath;
        self.cellSnapShotView.layer.mask = shapeLayer;
        self.cellSnapShotView.frame = CGRectMake(0, -point.y, self.cellSnapShotView.frame.size.width, self.cellSnapShotView.frame.size.height);
        [self.contentView addSubview:self.cellSnapShotView];
        self.contentView.clipsToBounds = YES;
        
        [containerView addSubview:toView];
        
        if (toViewController.modalPresentationStyle == UIModalPresentationCustom) {
            [fromViewControllerNAV beginAppearanceTransition:NO animated:YES];
        }
        
        [UIView animateWithDuration:0.4 delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
//            fromView.transform = CGAffineTransformMakeScale(self.behindViewScale, self.behindViewScale);
//            fromView.alpha =  self.behindViewAlpha;
            self.screenSnapShotView.transform = CGAffineTransformMakeScale(self.behindViewScale, self.behindViewScale);
            self.screenSnapShotView.alpha =  self.behindViewAlpha;
            self.cellSnapShotView.alpha = 0.0f;
            
        } completion:^(BOOL finished) {
            
            [UIView animateWithDuration:0.65 delay:0.0f usingSpringWithDamping:0.75 initialSpringVelocity:0.35 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.contentView.frame = CGRectMake(0, self.topMargin, self.screenBounds.size.width, self.screenBounds.size.height - (self.topMargin));
            } completion:^(BOOL finished) {
                
                [UIView animateWithDuration:0.25f animations:^{
                    toView.alpha = 1.0f;
                } completion:^(BOOL finished) {
                    fromView.hidden = NO;
                    self.contentView.hidden = YES;
                    if (toViewController.modalPresentationStyle == UIModalPresentationCustom) {
                        [fromViewControllerNAV endAppearanceTransition];
                    }
                    [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
                }];
            }];
        }];
    }
    else{
        [self.contentView removeFromSuperview];
        self.contentView = nil;
        
        UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
        UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        
        UIView *toView = toViewController.view;
        toView.hidden = YES;
        
        if (fromViewController.modalPresentationStyle == UIModalPresentationFullScreen) {
            [containerView addSubview:toViewController.view];
        }
        
        [containerView bringSubviewToFront:fromViewController.view];

        if (![self isPriorToIOS8]) {
            self.screenSnapShotView.layer.transform = CATransform3DScale(self.screenSnapShotView.layer.transform, self.behindViewScale, self.behindViewScale, 1);
        }
        
        
        CGRect endRect;
        
        if (self.gesture.direction == LCSpreadTransitionDirectionBottom) {
            endRect = CGRectMake(0,
                                 CGRectGetHeight(fromViewController.view.bounds),
                                 CGRectGetWidth(fromViewController.view.frame),
                                 CGRectGetHeight(fromViewController.view.frame));
        } else if (self.gesture.direction == LCSpreadTransitionDirectionTop) {
            endRect = CGRectMake(0,
                                 -CGRectGetHeight(fromViewController.view.bounds),
                                 CGRectGetWidth(fromViewController.view.frame),
                                 CGRectGetHeight(fromViewController.view.frame));
        } else if (self.gesture.direction == LCSpreadTransitionDirectionRight) {
            endRect = CGRectMake(CGRectGetWidth(fromViewController.view.bounds),
                                 0,
                                 CGRectGetWidth(fromViewController.view.frame),
                                 CGRectGetHeight(fromViewController.view.frame));
        }
       
        
        CGPoint transformedPoint = CGPointApplyAffineTransform(endRect.origin, fromViewController.view.transform);
        endRect = CGRectMake(transformedPoint.x, transformedPoint.y, endRect.size.width, endRect.size.height);
        
        
        [UIView animateWithDuration:0.35 delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.screenSnapShotView.layer.transform = CATransform3DScale(toViewController.view.layer.transform, 1.0f, 1.0f, 1);
            self.screenSnapShotView.alpha = 1.0f;
            fromViewController.view.frame = endRect;
        } completion:^(BOOL finished) {
            toView.hidden = NO;
            toViewController.view.layer.transform = CATransform3DIdentity;
            if (fromViewController.modalPresentationStyle == UIModalPresentationCustom) {
                [toViewController endAppearanceTransition];
            }
            [self.gesture.scrollview removeObserver:self forKeyPath:@"panGestureRecognizer.state"];
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }
}


#pragma mark - UIViewControllerTransitioningDelegate Methods

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    self.presenting = YES;
    return self;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    self.presenting = NO;
    return self;
}


- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id <UIViewControllerAnimatedTransitioning>)animator
{
    return nil;
}

- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id <UIViewControllerAnimatedTransitioning>)animator
{
    // Return nil if we are not interactive
    if (self.isInteractive && self.dragable) {
        self.presenting = NO;
        return self;
    }
    
    return nil;
}

#pragma mark - Gesture Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (self.gestureRecognizerToFailPan == otherGestureRecognizer) {
        return YES;
    }
    
    return NO;
}


#pragma mark - KVO

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // 监听pan手势结束
    if (self.gesture.scrollview.panGestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        if (self.gesture.scrollview.contentOffset.y < -self.topMargin) {
            self.gesture.direction = LCSpreadTransitionDirectionBottom;
            [self.modalController dismissViewControllerAnimated:YES completion:NULL];
        }
        else if (self.gesture.scrollview.contentOffset.y + self.gesture.scrollview.bounds.size.height >= self.gesture.scrollview.contentSize.height + self.topMargin){
            self.gesture.direction = LCSpreadTransitionDirectionTop;
            [self.modalController dismissViewControllerAnimated:YES completion:NULL];
        }
    }
}

//- (void)dealloc{
//    [self.gesture.scrollview removeObserver:self forKeyPath:@"panGestureRecognizer.state"];
//}


//- (UIImageView *)snapShotWithView:(UIView *)view{
//    UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, [UIScreen mainScreen].scale);
//    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
//    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
//    imageView.frame = view.frame;
//    return imageView;
//}


#pragma mark - Utils

- (BOOL)isPriorToIOS8
{
    NSComparisonResult order = [[UIDevice currentDevice].systemVersion compare: @"8.0" options: NSNumericSearch];
    if (order == NSOrderedSame || order == NSOrderedDescending) {
        // OS version >= 8.0
        return YES;
    }
    return NO;
}

@end


@interface LCDetectScrollViewEndGestureRecognizer ()

@property (nonatomic, strong) NSNumber *isFail;

@end

@implementation LCDetectScrollViewEndGestureRecognizer


- (void)reset
{
    [super reset];
    self.isFail = nil;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    
    if (!self.scrollview) {
        return;
    }

    if (self.state == UIGestureRecognizerStateFailed) return;
    CGPoint velocity = [self velocityInView:self.view];
    CGPoint nowPoint = [touches.anyObject locationInView:self.view];
    CGPoint prevPoint = [touches.anyObject previousLocationInView:self.view];
    
    if (self.isFail) {
        if (self.isFail.boolValue) {
            self.state = UIGestureRecognizerStateFailed;
        }
        return;
    }
    
    CGFloat topVerticalOffset = -self.scrollview.contentInset.top;
    
    BOOL isVerticalGesture = fabs(velocity.y) > fabs(velocity.x);

    if (isVerticalGesture && (nowPoint.y > prevPoint.y) && (self.scrollview.contentOffset.y <= topVerticalOffset)) {
        self.direction = LCSpreadTransitionDirectionBottom;
        self.isFail = @YES;
    }
    else if (isVerticalGesture && (nowPoint.y <= prevPoint.y) && (self.scrollview.contentOffset.y + self.scrollview.bounds.size.height >= self.scrollview.contentSize.height)) {
        self.direction = LCSpreadTransitionDirectionTop;
        self.isFail = @YES;
    }
    else if (!isVerticalGesture && (nowPoint.x > prevPoint.x) && (self.scrollview.contentOffset.x <= topVerticalOffset)) {
        self.direction = LCSpreadTransitionDirectionRight;
        self.isFail = @NO;
    }
    else if (self.scrollview.contentOffset.y >= topVerticalOffset) {
        self.state = UIGestureRecognizerStateFailed;
        self.isFail = @YES;
    }
//    else {
//        self.isFail = @NO;
//    }
}



@end

