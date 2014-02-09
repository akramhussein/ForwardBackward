//
//  AssetManagement.m
//  ForwardBackward
//
//  Created by Akram Hussein on 02/02/2014.
//  Copyright (c) 2014 Akram Hussein. All rights reserved.
//

#import "AssetManagement.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import "ALAssetsLibrary+CustomPhotoAlbum.h"

@interface AssetManagement ()

@property (strong, atomic) ALAssetsLibrary* library;
@property (strong, nonatomic) NSString *appName;
@property (strong, nonatomic) UIImage *stitchedImage;
@end


@implementation AssetManagement

@synthesize forwardImage;
@synthesize backwardImage;

- (id)init
{
    if (self = [super init])
    {
        self.appName = [[NSString alloc] initWithString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]];
        self.library = [[ALAssetsLibrary alloc] init];
    }
    return self;
}

- (void)reset
{
    [self setForwardImage:nil];
    [self setBackwardImage:nil];
    [self setStitchedImage:nil];
}

- (UIImage *)getStitchedImage
{
    return [self stitchedImage];
}

// Stitch with UIKit - not be thread safe must be run in main thread
- (UIImage *)stitchImage:(UIImage *)firstImage withImage:(UIImage *) secondImage
{
    CGSize size = CGSizeMake(firstImage.size.width, firstImage.size.height + secondImage.size.height);
    
    UIGraphicsBeginImageContext(size);
    
    [firstImage drawInRect:CGRectMake(0, 0, size.width, firstImage.size.height)];
    [secondImage drawInRect:CGRectMake(0, firstImage.size.height, size.width, secondImage.size.height)];
    
    UIImage *stitchedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    

    return stitchedImage;
}

- (void)createStitchedImage
{
    [self setStitchedImage:[self stitchImage:[self forwardImage] withImage:[self backwardImage]]];
}

- (void)saveStitchedImage
{
    if ([self stitchedImage] == nil)
    {
        [self createStitchedImage];
    }
    [[self library] saveImage:[self stitchedImage]
                      toAlbum:[self appName]
                   completion:^(NSURL *assetURL, NSError *error) {}
                      failure:^(NSError *error){
                          if (error != nil)
                          {
                              NSLog(@"%@", [error description]);
                          }
                      }];
}

@end
