//
//  ViewController.m
//  ImgSearch
//
//  Created by Vishal Parikh on 11/12/13.
//  Copyright (c) 2013 Health Equity Labs. All rights reserved.
//

#import "ViewController.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *searchTermTextField;
@property (weak, nonatomic) IBOutlet UIImageView *resultImageView;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (strong, nonatomic) NSDictionary *results;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)didSearch:(UIButton *)sender {
    [SVProgressHUD showWithStatus:@"Searching..." maskType:SVProgressHUDMaskTypeBlack];
    _errorLabel.text = @""; // clear any previous errors
    _resultImageView.image = nil;
    [_searchTermTextField resignFirstResponder]; // hide keyboard
    
    //https://developers.google.com/image-search/v1/jsondevguide#basic_query
    NSString* encodedSearchText = [_searchTermTextField.text
                                   stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    NSString *queryString = [NSString stringWithFormat:@"https://ajax.googleapis.com/ajax/services/search/images?v=1.0&q=%@",
                             encodedSearchText];
    
    //Make an asynchronous request for the data
    [NSURLConnection sendAsynchronousRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:queryString]]
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
        if (error) {
            _errorLabel.text = [NSString stringWithFormat:@"Error: %@", error.localizedDescription];
        } else {
            NSError *localError = nil;
            NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&localError];
            
            if (localError != nil) {
                _errorLabel.text = [NSString stringWithFormat:@"Error: Cannot parse result - %@",
                                    error.localizedDescription];
            }else{
                self.results = parsedObject;
                
                NSArray* imageDicts = parsedObject[@"responseData"][@"results"];
                if ( ![imageDicts isKindOfClass:[NSArray class]] || imageDicts.count == 0 ) {
                    _errorLabel.text = @"No results";
                }
                else {
                    //get first image
                    NSString *image = imageDicts[0][@"url"];
                    [self getImage:image];
                }
            }
        }
    }];
}

-(void) getImage:(NSString *)url
{
    [NSURLConnection sendAsynchronousRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]]
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         if(error){
             _errorLabel.text = @"Error retrieving image";
         }else{
             dispatch_async(dispatch_get_main_queue(), ^{
                 [SVProgressHUD dismiss];
                 UIImage *img = [[UIImage alloc] initWithData:data ];
                 _resultImageView.image = img;
             });
         }
     }];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self didSearch:nil];
    return YES;
}

@end
