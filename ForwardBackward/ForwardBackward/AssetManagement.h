//
//  AssetManagement.h
//  ForwardBackward
//
//  Created by Akram Hussein on 02/02/2014.
//  Copyright (c) 2014 Akram Hussein. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AssetManagement : NSObject

@property (strong, nonatomic) UIImage *forwardImage;
@property (strong, nonatomic) UIImage *backwardImage;

- (void)saveStitchedImage;
- (void)reset;

- (void)createStitchedImage;
- (UIImage *)getStitchedImage;

@end
