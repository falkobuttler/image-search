//
//  FilterViewController.m
//  ImgSearch
//
//  Created by Falko Buttler on 1/16/14.
//  Copyright (c) 2014 Health Equity Labs. All rights reserved.
//

#import "FilterViewController.h"
#import "DropDownListView.h"
#import "SearchConfiguration.h"
@import QuartzCore;

typedef NS_ENUM(NSInteger, FilterMode) {
    FilterModeNone,
    FilterModeFileType,
    FilterModeColors,
    FilterModeRights,
    FilterModeSizes,
    FilterModeImageTypes
};

@interface FilterViewController () <kDropDownListViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *fileTypesButton;
@property (weak, nonatomic) IBOutlet UIButton *colorsButton;
@property (weak, nonatomic) IBOutlet UIButton *rightsButton;
@property (weak, nonatomic) IBOutlet UIButton *sizesButton;
@property (weak, nonatomic) IBOutlet UIButton *imageTypesButton;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;

@property (strong, nonatomic) DropDownListView* dropdown;
@property (assign, nonatomic) FilterMode filterMode;

@end

@implementation FilterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _filterMode = FilterModeNone;
    [self addOutlineToButton:_fileTypesButton];
    [self addOutlineToButton:_colorsButton];
    [self addOutlineToButton:_rightsButton];
    [self addOutlineToButton:_sizesButton];
    [self addOutlineToButton:_imageTypesButton];
    [self addOutlineToButton:_resetButton];
}

- (void)addOutlineToButton:(UIButton*)button
{
    button.layer.borderColor = [UIColor whiteColor].CGColor;
    button.layer.borderWidth = 1.0;
    button.layer.cornerRadius = 10;
}

- (IBAction)changeFileTypes:(id)sender
{
    _filterMode = FilterModeFileType;
    NSArray* options = @[@"All File Types", @"JPG", @"PNG", @"GIF", @"BMP"];
    [self showPopUpWithTitle:@"File Types" withOption:options xy:CGPointZero size:self.view.frame.size isMultiple:NO];
}

- (IBAction)changeColors:(id)sender
{
    _filterMode = FilterModeColors;
    NSArray* options = @[@"All Colors", @"Black", @"Blue", @"Brown", @"Gray", @"Green", @"Orange", @"Pink",
                         @"Purple", @"Red", @"Teal", @"White", @"Yellow"];
    [self showPopUpWithTitle:@"Colors" withOption:options xy:CGPointZero size:self.view.frame.size isMultiple:NO];
}

- (IBAction)changeRights:(id)sender
{
    _filterMode = FilterModeRights;
    NSArray* options = @[@"All Rights", @"Public Domain", @"Attribute", @"Share Alike", @"Non Commercial", @"Non Derived"];
    [self showPopUpWithTitle:@"Rights" withOption:options xy:CGPointZero size:self.view.frame.size isMultiple:NO];
}

- (IBAction)changeSizes:(id)sender
{
    _filterMode = FilterModeSizes;
    NSArray* options = @[@"All Sizes", @"Icon", @"Small", @"Medium", @"Large", @"XL", @"XXL", @"Huge"];
    [self showPopUpWithTitle:@"Sizes" withOption:options xy:CGPointZero size:self.view.frame.size isMultiple:NO];
}

- (IBAction)changeImageTypes:(id)sender
{
    _filterMode = FilterModeImageTypes;
    [self showPopUpWithTitle:@"Image Types" withOption:@[@"All Image Types", @"Face", @"Photo", @"Clipart", @"Lineart"]
                          xy:CGPointZero size:self.view.frame.size isMultiple:NO];
}

- (IBAction)resetFilter:(id)sender
{
    [[SearchConfiguration sharedInstance] reset];
 
    // TODO: Could be refactored
    [_fileTypesButton setTitle:@"All File Types" forState:UIControlStateNormal];
    [_colorsButton setTitle:@"All Colors" forState:UIControlStateNormal];
    [_rightsButton setTitle:@"All Rights" forState:UIControlStateNormal];
    [_sizesButton setTitle:@"All Sizes" forState:UIControlStateNormal];
    [_imageTypesButton setTitle:@"All Image Types" forState:UIControlStateNormal];
}

-(void)showPopUpWithTitle:(NSString*)popupTitle withOption:(NSArray*)arrOptions xy:(CGPoint)point size:(CGSize)size isMultiple:(BOOL)isMultiple
{
    [_dropdown fadeOut];
    _dropdown = [[DropDownListView alloc] initWithTitle:popupTitle options:arrOptions xy:point size:size isMultiple:isMultiple];
    _dropdown.delegate = self;
    [_dropdown showInView:self.view animated:YES];
    [_dropdown SetBackGroundDropDwon_R:0.0 G:108.0 B:194.0 alpha:0.70];
}

#pragma mark -
#pragma mark DropDownListViewDelegate

- (void)DropDownListView:(DropDownListView *)dropdownListView didSelectedIndex:(NSInteger)anIndex
{
    // Note: Index matches enum values
    switch ( _filterMode ) {
        case FilterModeFileType:
            [_fileTypesButton setTitle:dropdownListView.kDropDownOption[anIndex] forState:UIControlStateNormal];
            [SearchConfiguration sharedInstance].fileTypes = anIndex;
            break;
        case FilterModeColors:
            [_colorsButton setTitle:dropdownListView.kDropDownOption[anIndex] forState:UIControlStateNormal];
            [SearchConfiguration sharedInstance].colors = anIndex;
            break;
        case FilterModeRights:
            [_rightsButton setTitle:dropdownListView.kDropDownOption[anIndex] forState:UIControlStateNormal];
            [SearchConfiguration sharedInstance].rights = anIndex;
            break;
        case FilterModeSizes:
            [_sizesButton setTitle:dropdownListView.kDropDownOption[anIndex] forState:UIControlStateNormal];
            [SearchConfiguration sharedInstance].sizes = anIndex;
            break;
        case FilterModeImageTypes:
            [_imageTypesButton setTitle:dropdownListView.kDropDownOption[anIndex] forState:UIControlStateNormal];
            [SearchConfiguration sharedInstance].imageTypes = anIndex;
            break;
        default:
            break;
    }
}

- (void)DropDownListView:(DropDownListView *)dropdownListView Datalist:(NSMutableArray*)ArryData{
    // intentially left blank
}

- (void)DropDownListViewDidCancel {
    // intentially left blank
}

@end
