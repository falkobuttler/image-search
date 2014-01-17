//
//  SearchConfiguration.h
//  ImgSearch
//
//  Created by Falko Buttler on 1/16/14.
//  Copyright (c) 2014 Health Equity Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SearchConfiguration : NSObject

typedef NS_ENUM(NSInteger, SCFileTypes) {
    SCFileTypesAll,
    SCFileTypesJPG,
    SCFileTypesPNG,
    SCFileTypesGIF,
    SCFileTypesBMP
};

typedef NS_ENUM(NSInteger, SCColors) {
    SCColorsAll,
    SCColorsBlack,
    SCColorsBlue,
    SCColorsBrown,
    SCColorsGray,
    SCColorsGreen,
    SCColorsOrange,
    SCColorsPink,
    SCColorsPurple,
    SCColorsRed,
    SCColorsTeal,
    SCColorsWhite,
    SCColorsYellow
};

typedef NS_ENUM(NSInteger, SCRights) {
    SCRightsAll,
    SCRightsPublicDomain,
    SCRightsAttribute,
    SCRightsSharealike,
    SCRightsNonCommercial,
    SCRightsNonDerived
};

typedef NS_ENUM(NSInteger, SCSizes) {
    SCSizesAll,
    SCSizesIcon,
    SCSizesSmall,
    SCSizesMedium,
    SCSizesLarge,
    SCSizesXLarge,
    SCSizesXXLarge,
    SCSizesHuge
};

typedef NS_ENUM(NSInteger, SCImageTypes) {
    SCImageTypesAll,
    SCImageTypesFace,
    SCImageTypesPhoto,
    SCImageTypesClipart,
    SCImageTypesLineart
};

@property (assign, nonatomic) SCFileTypes fileTypes;
@property (assign, nonatomic) SCColors colors;
@property (assign, nonatomic) SCRights rights;
@property (assign, nonatomic) SCSizes sizes;
@property (assign, nonatomic) SCImageTypes imageTypes;

+ (instancetype)sharedInstance;

- (void)reset;

@end
