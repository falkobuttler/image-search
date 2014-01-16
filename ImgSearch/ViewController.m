//
//  ViewController.m
//  ImgSearch
//
//  Created by Vishal Parikh on 11/12/13.
//  Copyright (c) 2013 Health Equity Labs. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didSearch:(UIButton *)sender {
    NSLog(@"Did search");
    //TODO: get the query and create a query string
    
    //Test query string
    //https://developers.google.com/image-search/v1/jsondevguide#basic_query
    NSString *queryString = @"https://ajax.googleapis.com/ajax/services/search/images?v=1.0&q=fuzzy%20monkey";
    
    //Make an asynchronous request for the data
    [NSURLConnection sendAsynchronousRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:queryString]] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (error) {
            NSLog(@"Error with query string");
        } else {
            NSError *localError = nil;
            NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&localError];
            
            if (localError != nil) {
                NSLog(@"Json error");
            }else{
                self.results = parsedObject;
                //get first image
                NSString *image = [[[[parsedObject objectForKey:@"responseData"] objectForKey:@"results"]objectAtIndex:0] objectForKey:@"url"];
                [self getImage:image];
                
                //the dispatch_async is important, we can only update the UI on the main thread
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.mainLabel setText:image];
                    NSLog(@"%@",image);
                });
            }
        }
    }];
}

-(void) getImage:(NSString *)url
{
    [NSURLConnection sendAsynchronousRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if(error){
            NSLog(@"Error retrieving image");
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Setting Image");
                UIImage *img = [[UIImage alloc] initWithData:data ];
                //TODO actually set the image here
            });
        }
    }];
}
@end
