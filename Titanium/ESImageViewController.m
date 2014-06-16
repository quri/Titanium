//
//  ESImageViewController.m
//  Titanium
//
//  Created by Camille Kander on 5/29/14.
//  Copyright (c) 2014 Quri. All rights reserved.
//

#import "ESImageViewController.h"

@interface ESImageViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation ESImageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.scrollView.backgroundColor = [UIColor blackColor];
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
}

- (void)setImageView:(UIImageView *)imageView {
    
    [imageView removeFromSuperview];
    _imageView = imageView;
    
    [_imageView setContentMode:UIViewContentModeScaleAspectFit];
    
    [self.scrollView setMaximumZoomScale:[self maximumZoomScaleForImageSize:imageView.image.size]];
    [self.scrollView setContentMode:UIViewContentModeCenter];
    [self.scrollView addSubview:_imageView];
//    [imageView setCenter:self.scrollView.center];
}

#pragma mark - Scroll view delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
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
    
    NSLog(@"{ %f, %f, %f, %f }", x, y, width, height);
    
    return CGRectMake(x, y, width, height);
}

@end
