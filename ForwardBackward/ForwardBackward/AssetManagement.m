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
#import "UIImage+Stitch.h"

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


- (void)createStitchedImage
{
    [self setStitchedImage:[forwardImage stitchImagewithImage:[self backwardImage]]];
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
