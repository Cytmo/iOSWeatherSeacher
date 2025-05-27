//
//  ViewController.h
//  weatherSearcher
//
//  Created by 孔维辰 on 2025/5/27.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (nonatomic, strong) UITextField *searchTextField;
@property (nonatomic, strong) UIButton *searchButton;
@property (nonatomic, strong) UIView *weatherView;
@property (nonatomic, strong) NSString *apiKey;

@end

