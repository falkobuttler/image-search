//
//  SearchConfiguration.m
//  ImgSearch
//
//  Created by Falko Buttler on 1/16/14.
//  Copyright (c) 2014 Health Equity Labs. All rights reserved.
//

#import "SearchConfiguration.h"

@implementation SearchConfiguration

+ (instancetype)sharedInstance
{
    static SearchConfiguration *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SearchConfiguration alloc] init];
        [instance reset];
    });
    return instance;
}

- (void)reset
{
    self.fileTypes = SCFileTypesAll;
    self.colors = SCColorsAll;
    self.rights = SCRightsAll;
    self.sizes = SCSizesAll;
    self.imageTypes = SCImageTypesAll;
}

@end
