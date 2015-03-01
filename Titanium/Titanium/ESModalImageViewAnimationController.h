//
//  ESModalImageViewAnimationController.h
//  Titanium
//
//  Created by Camille Kander on 5/29/14.
//  Copyright (c) 2014 Quri. All rights reserved.
//

@import UIKit;

@interface ESModalImageViewAnimationController : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, strong) UIView *thumbnailView;

- (instancetype)initWithThumbnailView:(UIView *)thumbnailView;

@end
