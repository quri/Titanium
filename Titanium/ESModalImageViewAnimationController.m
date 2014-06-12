//
//  ESModalImageViewAnimationController.m
//  Titanium
//
//  Created by Camille Kander on 5/29/14.
//  Copyright (c) 2014 Quri. All rights reserved.
//

#import "ESModalImageViewAnimationController.h"
#import "ESImageViewController.h"

typedef NS_ENUM(BOOL, ESModalTransitionDirection) {
    ESModalTransitionDirectionPresenting = YES,
    ESModalTransitionDirectionDismissing = NO
};

@implementation ESModalImageViewAnimationController

#pragma mark - View controller animated transitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.6;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {

    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if ([toViewController isKindOfClass:[ESImageViewController class]]) {
        [self performPresent:transitionContext];
    } else {
        [self performDismiss:transitionContext];
    }
}

#pragma mark - Performs

- (void)performPresent:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    ESImageViewController *presentedViewController = (ESImageViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *presentedView = presentedViewController.view;
    UIView *originView = [transitionContext containerView];
    
    [originView insertSubview:presentedView aboveSubview:originView];
    
    [self.thumbnailView setHidden:YES];
    
    CALayer *mask = [self maskWithModalViewFrame:presentedView.frame direction:ESModalTransitionDirectionPresenting animated:YES];
    [presentedView.layer setMask:mask];

    CGAffineTransform transform = [self affineTransformWithImageViewFrame:presentedView.frame andThumbnailFrame:self.thumbnailView.frame];
    [presentedView setTransform:transform];
    
    CGFloat duration = [self transitionDuration:transitionContext];
    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.0 options:0 animations:^{
        [presentedView setTransform:CGAffineTransformIdentity];
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:YES];
    }];
}

- (void)performDismiss:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    ESImageViewController *imageViewController = (ESImageViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIView *fromView = imageViewController.view;
    CALayer *mask = [self maskWithModalViewFrame:fromView.frame direction:ESModalTransitionDirectionDismissing animated:YES];
    [fromView.layer setMask:mask];
    
    CGFloat duration = [self transitionDuration:transitionContext];
    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.0 options:0 animations:^{
        [imageViewController.view setTransform:[self affineTransformWithImageViewFrame:imageViewController.view.frame andThumbnailFrame:self.thumbnailView.frame]];
    } completion:^(BOOL finished) {
        [self.thumbnailView setHidden:NO];
        [transitionContext completeTransition:YES];
    }];
}

#pragma mark - Internals

- (CGAffineTransform)affineTransformWithImageViewFrame:(CGRect)imageViewFrame andThumbnailFrame:(CGRect)thumbnailFrame {
    
    CGFloat scaleFactor = thumbnailFrame.size.width / imageViewFrame.size.width;
    CGAffineTransform scale = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
    
    CGFloat deltaX = CGRectGetMidX(thumbnailFrame) - CGRectGetMidX(imageViewFrame);
    CGFloat deltaY = CGRectGetMidY(thumbnailFrame) - CGRectGetMidY(imageViewFrame);
    CGAffineTransform translation = CGAffineTransformMakeTranslation(deltaX, deltaY);
    
    return CGAffineTransformConcat(scale, translation);
}

- (CALayer *)maskWithModalViewFrame:(CGRect)modalViewFrame direction:(ESModalTransitionDirection)direction animated:(BOOL)animated {
    
    CGRect maskBounds = CGRectMake(0.0, 0.0, 320.0, 320.0);
    
    CALayer *mask = [CALayer layer];
    mask.position = CGPointMake(CGRectGetMidX(modalViewFrame), CGRectGetMidY(modalViewFrame));
    mask.backgroundColor = [UIColor blackColor].CGColor;
    
    if (animated) {
        mask.bounds = (direction == ESModalTransitionDirectionPresenting ? maskBounds : modalViewFrame);
        [self addAnimationToMask:mask forModalViewFrame:modalViewFrame transitionDirection:direction];
    }
    
    mask.bounds = (direction == ESModalTransitionDirectionPresenting ? modalViewFrame : maskBounds);
    
    return mask;
}

- (void)addAnimationToMask:(CALayer *)mask forModalViewFrame:(CGRect)frame transitionDirection:(ESModalTransitionDirection)direction {
    
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"bounds.size.height"];
    anim.fromValue = @((direction == ESModalTransitionDirectionPresenting ? 320.0 : frame.size.height));
    anim.toValue = @((direction == ESModalTransitionDirectionPresenting ? frame.size.height : 320.0));
    anim.duration = 0.2;
    [mask addAnimation:anim forKey:@"bounds"];
}

@end
