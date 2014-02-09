//
//  UIImage+Stitch.m
//  ForwardBackward
//
//  Created by Akram Hussein on 09/02/2014.
//  Copyright (c) 2014 Akram Hussein. All rights reserved.
//

#import "UIImage+Stitch.h"

@implementation UIImage (Stitch)

- (UIImage *)stitchImagewithImage:(UIImage *)secondImage
{
    CGSize size = CGSizeMake(self.size.width, self.size.height + secondImage.size.height);
    
    UIGraphicsBeginImageContext(size);
    
    [self drawInRect:CGRectMake(0, 0, size.width, self.size.height)];
    [secondImage drawInRect:CGRectMake(0, self.size.height, size.width, secondImage.size.height)];
    
    UIImage *stitchedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return stitchedImage;
}

@end

