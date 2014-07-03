//
//  ESModalImageViewAnimationController.m
//  Titanium
//
//  Created by Camille Kander on 5/29/14.
//  Copyright (c) 2014 Quri. All rights reserved.
//

#import "ESModalImageViewAnimationController.h"
#import "ESImageViewController-Internals.h"

typedef NS_ENUM(BOOL, ESModalTransitionDirection) {
    ESModalTransitionDirectionPresenting = YES,
    ESModalTransitionDirectionDismissing = NO
};

BOOL frameIsPortrait(CGRect bounds) {
    return bounds.size.height > bounds.size.width;
}

static CGFloat const kTransitioningDuration = 0.5;
static CGFloat const kMaskingDuration = 0.15;

@implementation ESModalImageViewAnimationController

- (instancetype)initWithThumbnailView:(UIView *)thumbnailView {
    
    self = [super init];
    if (self) {
        _thumbnailView = thumbnailView;
    }
    
    return self;
}

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
    UIView *containerView = [transitionContext containerView];
    
    [presentedView setAlpha:0.0];
    [containerView insertSubview:presentedView aboveSubview:containerView];
    
    UIImage *image = presentedViewController.image;
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:[presentedViewController imageViewFrameForImage:presentedViewController.image]];
    [imageView setImage:image];
    
    CALayer *mask = [self maskWithImageViewFrame:imageView.frame thumbnailFrame:self.thumbnailView.frame direction:ESModalTransitionDirectionPresenting animated:YES];
    [imageView.layer setMask:mask];
    CGRect frameRelativeToContainer = [containerView convertRect:self.thumbnailView.frame fromView:self.thumbnailView.superview];
    [imageView setTransform:[self affineTransformWithImageViewFrame:imageView.frame andThumbnailFrame:frameRelativeToContainer]];

    [self.thumbnailView setHidden:YES];
    [containerView insertSubview:imageView aboveSubview:presentedView];
    
    CGFloat duration = [self transitionDuration:transitionContext];
    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.0 options:0 animations:^{
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
    CALayer *mask = [self maskWithImageViewFrame:freezeFrame thumbnailFrame:self.thumbnailView.frame direction:ESModalTransitionDirectionDismissing animated:YES];
    [imageView.layer setMask:mask];
    
    [UIView animateWithDuration:duration*0.6 delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:0 animations:^{
        CGRect frameRelativeToContainer = [containerView convertRect:self.thumbnailView.frame fromView:self.thumbnailView.superview];
        [imageView setTransform:[self affineTransformWithImageViewFrame:imageView.frame andThumbnailFrame:frameRelativeToContainer]];
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

- (CGRect)maskBoundsWithImageViewFrame:(CGRect)imageViewFrame andThumbnailFrame:(CGRect)thumbnailFrame {
    
    CGSize const imageViewSize = imageViewFrame.size;
    CGFloat const imageViewRatio = imageViewSize.width / imageViewSize.height;
    CGFloat const thumbnailRatio = thumbnailFrame.size.width / thumbnailFrame.size.height;
    
    CGFloat x = 0.0;
    CGFloat y = 0.0;
    CGFloat width = 0.0;
    CGFloat height = 0.0;
    
    if (thumbnailRatio > imageViewRatio) { // Top-bottom cropping
        width = imageViewSize.width;
        height = width / thumbnailRatio;
        y = (imageViewSize.height - height) / 2.0;
    } else {                        // Left-right cropping
        height = imageViewSize.height;
        width = height * thumbnailRatio;
        x = (imageViewSize.width - width) / 2.0;
    }
    
    return CGRectMake(x, y, width, height);
}

- (CALayer *)maskWithImageViewFrame:(CGRect)imageViewFrame thumbnailFrame:(CGRect)thumbnailFrame direction:(ESModalTransitionDirection)direction animated:(BOOL)animated {
    
    CGRect imageViewBounds = CGRectOffset(imageViewFrame, -imageViewFrame.origin.x, -imageViewFrame.origin.y);
    
    CALayer *mask = [CALayer layer];
    mask.position = CGPointMake(CGRectGetMidX(imageViewBounds), CGRectGetMidY(imageViewBounds));
    mask.backgroundColor = [UIColor blackColor].CGColor;
    
    CGRect maskBounds = [self maskBoundsWithImageViewFrame:imageViewFrame andThumbnailFrame:thumbnailFrame];

    if (animated) {
        mask.bounds = (direction == ESModalTransitionDirectionPresenting ? maskBounds : imageViewBounds);
        [self addAnimationToMask:mask withMaskBounds:maskBounds imageViewBounds:imageViewBounds transitionDirection:direction];
    }
    
    mask.bounds = (direction == ESModalTransitionDirectionPresenting ? imageViewBounds : maskBounds);
    
    return mask;
}

- (void)addAnimationToMask:(CALayer *)mask withMaskBounds:(CGRect)maskBounds imageViewBounds:(CGRect)imageViewBounds transitionDirection:(ESModalTransitionDirection)direction {
    
    BOOL portrait = frameIsPortrait(imageViewBounds);
    NSString *keyPath = (portrait ? @"bounds.size.height" : @"bounds.size.width");
    
    CGFloat maskBoundsDimension = (portrait ? maskBounds.size.height : maskBounds.size.width);
    CGFloat imageBoundsDimension = (portrait ? imageViewBounds.size.height : imageViewBounds.size.width);
    
    CGFloat fromValue = (direction == ESModalTransitionDirectionPresenting ? maskBoundsDimension : imageBoundsDimension);
    CGFloat toValue = (direction == ESModalTransitionDirectionPresenting ? imageBoundsDimension : maskBoundsDimension);
    
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:keyPath];
    anim.fromValue = @(fromValue);
    anim.toValue = @(toValue);
    anim.duration = kMaskingDuration;
    
    [mask addAnimation:anim forKey:@"bounds"];
}

@end
