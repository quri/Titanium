//
//  ESImageViewController.m
//  Titanium
//
//  Created by Camille Kander on 5/29/14.
//  Copyright (c) 2014 Quri. All rights reserved.
//

#import "ESImageViewController-Internals.h"
#import "ESModalImageViewAnimationController.h"

@interface ESImageViewController () <UIGestureRecognizerDelegate, UIViewControllerTransitioningDelegate>

@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGestureRecognizer;

@end

CGFloat const kMaxImageScale = 3.0;

@implementation ESImageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)awakeFromNib {
    
    [self setModalPresentationStyle:UIModalPresentationCustom];
    [self setTransitioningDelegate:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    self.pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    self.doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    [self.doubleTapGestureRecognizer setNumberOfTapsRequired:2];
    
    for (UIGestureRecognizer *recognizer in @[self.tapGestureRecognizer, self.pinchGestureRecognizer, self.panGestureRecognizer]) {
        [recognizer setDelegate:self];
    }
    
    [self.view addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)setImageView:(UIImageView *)imageView {
    
    [imageView removeFromSuperview];
    _imageView = imageView;
    [_imageView setUserInteractionEnabled:YES];
    
    [_imageView setContentMode:UIViewContentModeScaleAspectFit];
    
    [_imageView addGestureRecognizer:self.pinchGestureRecognizer];
    [_imageView addGestureRecognizer:self.panGestureRecognizer];
    [_imageView addGestureRecognizer:self.doubleTapGestureRecognizer];
    
    [self.view addSubview:_imageView];
}

- (void)dismissSelf {
    
    [self performSegueWithIdentifier:@"HideImage" sender:nil];
}

#pragma mark - Gestures

- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIView *piece = gestureRecognizer.view;
        CGPoint locationInView = [gestureRecognizer locationInView:piece];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview];
        
        piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
        piece.center = locationInSuperview;
    }
}

- (void)resetAnchorPointWithContent:(UIView *)content container:(UIView *)container andDuration:(CGFloat)duration {
    
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"anchorPoint"];
    [anim setFromValue:[NSValue valueWithCGPoint:content.layer.anchorPoint]];
    [anim setToValue:[NSValue valueWithCGPoint:CGPointMake(0.5, 0.5)]];
    [anim setDuration:duration];
    [anim setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [content.layer addAnimation:anim forKey:@"anchorPoint"];
    [content.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
}

- (void)tap:(UITapGestureRecognizer *)regognizer {
    
    UIView *content = self.imageView;
    UIView *container = content.superview;
    CGRect originalFrame = [self imageViewFrameForImage:self.image];
    
//    NSLog(@"%@, %@", NSStringFromCGRect(content.frame), NSStringFromCGRect(originalFrame));
    
    if (CGAffineTransformEqualToTransform(content.transform, CGAffineTransformIdentity) && CGRectEqualToRect([self roundedRectWithRect:content.frame], [self roundedRectWithRect:originalFrame])) { // rounding error de cul à marde!
        [self dismissSelf];
    } else {
        CGFloat duration = 0.3;
        [self resetAnchorPointWithContent:content container:container andDuration:duration];
        [UIView animateWithDuration:duration animations:^{
            [content setCenter:container.center];
            [content setTransform:CGAffineTransformIdentity];
        }];
    }
}

- (void)pinch:(UIPinchGestureRecognizer *)recognizer {
    
    [self adjustAnchorPointForGestureRecognizer:recognizer];
    
    UIView *content = self.imageView;
    
    // TODO: make this right
    CGFloat imageScale = self.imageView.frame.size.width / 320.0;
    
    CGFloat zoomScale = (imageScale < 1 ? sqrt(recognizer.scale) : recognizer.scale);
    
    if (recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged) {
        [content setTransform:CGAffineTransformScale(content.transform, zoomScale, zoomScale)];
        [recognizer setScale:1.0];
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:0.3 animations:^{
            if (imageScale < 1.0) {
                [content setTransform:CGAffineTransformIdentity];
            } else if (imageScale > kMaxImageScale) {
                [content setTransform:CGAffineTransformScale(CGAffineTransformIdentity, kMaxImageScale, kMaxImageScale)];
            }
        } completion:^(BOOL finished) {
//            UIView *acceptableRect = [[UIView alloc] initWithFrame:[self acceptableCenterPointRectForImageSize:content.frame.size]];
//            [acceptableRect setBackgroundColor:[[UIColor yellowColor] colorWithAlphaComponent:0.5]];
//            [self.view addSubview:acceptableRect];
        }];
    }
}

- (void)pan:(UIPanGestureRecognizer *)recognizer {
    
    [self adjustAnchorPointForGestureRecognizer:recognizer];
    
    UIView *content = self.imageView;
    UIView *container = content.superview;
    
    if (recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [recognizer translationInView:container];
        [content setCenter:CGPointMake(content.center.x + translation.x, content.center.y + translation.y)];
        [recognizer setTranslation:CGPointZero inView:container];
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint velocity = [recognizer velocityInView:container];
        CGFloat factor = 0.1;
        CGPoint inertia = CGPointMake(content.center.x + velocity.x * factor, content.center.y + velocity.y * factor);

        [self resetAnchorPointWithContent:content container:container andDuration:0.3];

        [UIView animateWithDuration:0.4 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:1.0 options:0 animations:^{
            
//            [content setCenter:inertia];
            [content setCenter:[self pointClosestToPoint:content.center inRect:[self acceptableCenterPointRectForImageSize:content.frame.size]]];

            [recognizer setTranslation:CGPointZero inView:container];
        } completion:^(BOOL finished){
            if (finished) {
                [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.0 options:0 animations:^{
//                    [content setCenter:[self pointClosestToPoint:content.center inRect:[self acceptableCenterPointRectForImageSize:content.frame.size]]];
                } completion:nil];
            }
        }];
    }
}

- (void)doubleTap:(UITapGestureRecognizer *)recognizer {
    
    UIView *content = self.imageView;
    
    [UIView animateWithDuration:0.3 animations:^{
        if (CGAffineTransformEqualToTransform(content.transform, CGAffineTransformIdentity)) {
            [content setTransform:CGAffineTransformScale(content.transform, kMaxImageScale, kMaxImageScale)];
        }
    }];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    if (gestureRecognizer == self.tapGestureRecognizer && otherGestureRecognizer == self.doubleTapGestureRecognizer) {
        return YES;
    }
    
    return NO;
}

#pragma mark - Math

- (CGFloat)maximumZoomScaleForImageSize:(CGSize)imageSize {

    CGFloat horizontalRatio = imageSize.width / self.view.frame.size.width;
    CGFloat verticalRatio = imageSize.height / self.view.frame.size.height;
    
    return MAX(horizontalRatio, verticalRatio) / 2.0;
}

- (CGRect)imageViewFrameForImage:(UIImage *)image {
    
    CGSize const screenSize = self.view.frame.size;
    CGFloat const screenRatio = screenSize.width / screenSize.height;
    CGFloat const imageRatio = image.size.width / image.size.height;
    
    CGFloat x = 0.0;
    CGFloat y = 0.0;
    CGFloat width = 0.0;
    CGFloat height = 0.0;
    
    if (imageRatio > screenRatio) { // Top-bottom letterboxing
        width = screenSize.width;
        height = width / imageRatio;
        y = (screenSize.height - height) / 2.0;
    } else {                        // Left-right letterboxing
        height = screenSize.height;
        width = height * imageRatio;
        x = (screenSize.width - width) / 2.0;
    }
    
//    NSLog(@"{ %f, %f, %f, %f }", x, y, width, height);
    
    return CGRectMake(x, y, width, height);
    return CGRectMake(0.0, 0.0, width, height);
}

- (CGRect)roundedRectWithRect:(CGRect)sourceRect {
    
    return CGRectMake(round(sourceRect.origin.x),
                      round(sourceRect.origin.y),
                      round(sourceRect.size.width),
                      round(sourceRect.size.height));
}

- (CGRect)acceptableCenterPointRectForImageSize:(CGSize)imageSize {
    
    CGSize const screenSize = self.view.frame.size;
    CGPoint const origin = CGPointMake(screenSize.width - imageSize.width / 2.0, screenSize.height - imageSize.height / 2.0);
    CGSize const size = CGSizeMake(screenSize.width - origin.x * 2.0, screenSize.height - origin.y * 2.0);
    
    CGFloat const kMinimumDefault = 1.0;
    CGPoint const screenCenter = self.view.center;
    return CGRectMake((size.width > 0.0 ? origin.x : screenCenter.x),
                      (size.height > 0.0 ? origin.y : screenCenter.y),
                      MAX(size.width, kMinimumDefault),
                      MAX(size.height, kMinimumDefault));
}

- (CGPoint)pointClosestToPoint:(CGPoint)point inRect:(CGRect)rect {
    
    if (CGRectContainsPoint(rect, point)) return point;
    
    CGFloat x = 0.0;
    
    if (point.x < CGRectGetMinX(rect)) {
        x = CGRectGetMinX(rect);
    } else if (point.x > CGRectGetMaxX(rect)) {
        x = CGRectGetMaxX(rect);
    } else {
        x = point.x;
    }
    
    CGFloat y = 0.0;
    
    if (point.y < CGRectGetMinY(rect)) {
        y = CGRectGetMinY(rect);
    } else if (point.y > CGRectGetMaxY(rect)) {
        y = CGRectGetMaxY(rect);
    } else {
        y = point.y;
    }
    
    return CGPointMake(x, y);
}

#pragma mark - View controller transitioning delegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    
    return [[ESModalImageViewAnimationController alloc] initWithThumbnailView:self.tappedThumbnail];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    
    return [[ESModalImageViewAnimationController alloc] initWithThumbnailView:self.tappedThumbnail];
}

@end
