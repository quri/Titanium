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

BOOL frameIsPortrait(CGRect frame) {
    return frame.size.height > frame.size.width;
}

static CGFloat const kTransitioningDuration = 0.6;
static CGFloat const kMaskingDuration = 0.2;

@implementation ESModalImageViewAnimationController

#pragma mark - View controller animated transitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return kTransitioningDuration;
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
    
    [presentedView setAlpha:0.0];
    [originView insertSubview:presentedView aboveSubview:originView];
    
    UIImage *image = presentedViewController.image;
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:[presentedViewController imageViewFrameForImage:presentedViewController.image]];
    [imageView setImage:image];
    
    CALayer *mask = [self maskWithImageViewFrame:imageView.frame direction:ESModalTransitionDirectionPresenting animated:YES];
    [imageView.layer setMask:mask];
    [imageView setTransform:[self affineTransformWithImageViewFrame:imageView.frame andThumbnailFrame:self.thumbnailView.frame]];

    [self.thumbnailView setHidden:YES];
    [originView insertSubview:imageView aboveSubview:presentedView];
    
    CGFloat duration = [self transitionDuration:transitionContext];
    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.0 options:0 animations:^{
        [imageView setTransform:CGAffineTransformIdentity];
        [presentedView setAlpha:1.0];
    } completion:^(BOOL finished) {
        [presentedViewController setImageView:imageView];
        [transitionContext completeTransition:YES];
    }];
}

- (void)performDismiss:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    ESImageViewController *imageViewController = (ESImageViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    UIView *fromView = imageViewController.view;
    
    UIImageView *imageView = imageViewController.imageView;
    [imageView removeFromSuperview];
    [containerView addSubview:imageView];
    
    CGFloat duration = [self transitionDuration:transitionContext];
    
    CGRect freezeFrame = imageView.frame; // This is necessary if you want to delay the masking using dispatch_after
    CALayer *mask = [self maskWithImageViewFrame:freezeFrame direction:ESModalTransitionDirectionDismissing animated:YES];
    [imageView.layer setMask:mask];
    
    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.0 options:0 animations:^{
        [imageView setTransform:[self affineTransformWithImageViewFrame:imageView.frame andThumbnailFrame:self.thumbnailView.frame]];
        [fromView setAlpha:0.0];
    } completion:^(BOOL finished) {
        [self.thumbnailView setHidden:NO];
        [transitionContext completeTransition:YES];
    }];
}

#pragma mark - Internals

- (CGAffineTransform)affineTransformWithImageViewFrame:(CGRect)imageViewFrame andThumbnailFrame:(CGRect)thumbnailFrame {
    
    CGFloat scaleFactor = 0.0;
    if (frameIsPortrait(imageViewFrame)) {
        scaleFactor = thumbnailFrame.size.width / imageViewFrame.size.width;
    } else {
        scaleFactor = thumbnailFrame.size.height / imageViewFrame.size.height;
    }
    
    CGAffineTransform scale = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
    
    CGFloat deltaX = CGRectGetMidX(thumbnailFrame) - CGRectGetMidX(imageViewFrame);
    CGFloat deltaY = CGRectGetMidY(thumbnailFrame) - CGRectGetMidY(imageViewFrame);
    CGAffineTransform translation = CGAffineTransformMakeTranslation(deltaX, deltaY);
    
    return CGAffineTransformConcat(scale, translation);
}

- (CALayer *)maskWithImageViewFrame:(CGRect)imageViewFrame direction:(ESModalTransitionDirection)direction animated:(BOOL)animated {
    
    CALayer *mask = [CALayer layer];
    mask.position = CGPointMake(CGRectGetMidX(imageViewFrame), CGRectGetMidY(imageViewFrame));
    mask.backgroundColor = [UIColor blackColor].CGColor;
    
    UIView *rotatedView = [[UIView alloc] initWithFrame:imageViewFrame];
    [rotatedView setTransform:CGAffineTransformMakeRotation(M_PI_2)];
    CGRect maskBounds = CGRectIntersection(imageViewFrame, rotatedView.frame);

    if (animated) {
        mask.bounds = (direction == ESModalTransitionDirectionPresenting ? maskBounds : imageViewFrame);
        [self addAnimationToMask:mask forImageViewFrame:imageViewFrame transitionDirection:direction];
    }
    
    mask.bounds = (direction == ESModalTransitionDirectionPresenting ? imageViewFrame : maskBounds);
    
    return mask;
}

- (void)addAnimationToMask:(CALayer *)mask forImageViewFrame:(CGRect)frame transitionDirection:(ESModalTransitionDirection)direction {
    
    BOOL portrait = frameIsPortrait(frame);
    NSString *keyPath = (portrait ? @"bounds.size.height" : @"bounds.size.width");
    CGFloat longDim = (portrait ? frame.size.height : frame.size.width);
    CGFloat shortDim = (portrait ? frame.size.width : frame.size.height);
    
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:keyPath];
    anim.fromValue = @((direction == ESModalTransitionDirectionPresenting ? shortDim : longDim));
    anim.toValue = @((direction == ESModalTransitionDirectionPresenting ? longDim : shortDim));
    anim.duration = kMaskingDuration;
    
    [mask addAnimation:anim forKey:@"bounds"];
}

@end
