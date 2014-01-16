//
//  ViewController.h
//  ImgSearch
//
//  Created by Vishal Parikh on 11/12/13.
//  Copyright (c) 2013 Health Equity Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
- (IBAction)didSearch:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UILabel *mainLabel;

@end
