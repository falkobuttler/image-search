//
//  ViewController.m
//  ImgSearch
//
//  Created by Vishal Parikh on 11/12/13.
//  Copyright (c) 2013 Health Equity Labs. All rights reserved.
//

#import "ImageCell.h"
#import "ViewController.h"
#import "UIImage+Decompression.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <NHBalancedFlowLayout/NHBalancedFlowLayout.h>

@interface ViewController () <UICollectionViewDelegateFlowLayout, NHBalancedFlowLayoutDelegate>

@property (weak, nonatomic) IBOutlet UITextField *searchTermTextField;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSDictionary *results;
@property (strong, nonatomic) NSMutableArray *images;

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
    _images = [NSMutableArray array];
    [_collectionView reloadData];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
//    [SVProgressHUD showWithStatus:@"Searching..." maskType:SVProgressHUDMaskTypeBlack];
    _errorLabel.text = @""; // clear any previous errors
    [_searchTermTextField resignFirstResponder]; // hide keyboard
    
    // https://developers.google.com/image-search/v1/jsondevguide#basic_query
    // Return 8 images per page (maximum per Google)
    NSString* encodedSearchText = [_searchTermTextField.text
                                   stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    NSString *queryString = [NSString stringWithFormat:@"https://ajax.googleapis.com/ajax/services/search/images?v=1.0&rsz=8&q=%@",
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
                _results = parsedObject[@"responseData"][@"results"];
                if ( ![_results isKindOfClass:[NSArray class]] || _results.count == 0 ) {
                    _errorLabel.text = @"No results";
                }
                else {
                    for( NSDictionary* imageDict in _results ) {
                        NSString *image = imageDict[@"url"];
                        [self getImage:image];
                    }
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
//                 [SVProgressHUD dismiss];
                 UIImage *img = [[UIImage alloc] initWithData:data];
                 @synchronized(self) { // Only one thread at a time
                     [_images addObject:img];
                     [_collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:_images.count-1 inSection:0]]];
                     if ( _results.count == _images.count ) {
                         [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                     }
                 }
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

#pragma mark - UICollectionViewFlowLayoutDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(NHBalancedFlowLayout *)collectionViewLayout
preferredSizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [_images[indexPath.item] size];
}

#pragma mark - UICollectionView data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section;
{
    return [_images count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ImageCell" forIndexPath:indexPath];
    cell.imageView.image = nil;
    
    /**
     * Decompress image on background thread before displaying it to prevent lag
     */
    NSInteger rowIndex = indexPath.row;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        UIImage *image = [UIImage decodedImageWithImage:_images[indexPath.item]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *currentIndexPathForCell = [collectionView indexPathForCell:cell];
            if (currentIndexPathForCell.row == rowIndex) {
                cell.imageView.image = image;
            }
        });
    });
    
    return cell;
}

@end
