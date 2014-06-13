//
//  ESImageViewController.h
//  Titanium
//
//  Created by Camille Kander on 5/29/14.
//  Copyright (c) 2014 Quri. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ESImageViewController : UIViewController

@property (nonatomic, strong) UIImage *image;
@property (strong, nonatomic) UIImageView *imageView;

- (CGRect)imageViewFrameForImage:(UIImage *)image;

@end
