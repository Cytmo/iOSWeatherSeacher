//
//  ViewController.m
//  weatherSearcher
//
//  Created by 孔维辰 on 2025/5/27.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupUI];
    [self setupConstraints];
}

- (void)setupUI {
    self.searchTextField = [[UITextField alloc] init];
    self.searchTextField.placeholder = @"请输入城市名称";
    self.searchTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.searchTextField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.searchTextField];

    self.searchButton = [[UIButton alloc] init];
    [self.searchButton addTarget:self action:@selector(searchButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.searchButton setTitle:@"搜索" forState:UIControlStateNormal];
    self.searchButton.backgroundColor = [UIColor systemBlueColor];
    [self.searchButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.searchButton.layer.cornerRadius = 8;
    self.searchButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.searchButton];
}
- (void)setupConstraints {
    [NSLayoutConstraint activateConstraints:@[
        // 搜索框约束
        [self.searchTextField.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.searchTextField.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-50],
        [self.searchTextField.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:40],
        [self.searchTextField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-40],
        [self.searchTextField.heightAnchor constraintEqualToConstant:44],
        
        // 搜索按钮约束
        [self.searchButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.searchButton.topAnchor constraintEqualToAnchor:self.searchTextField.bottomAnchor constant:20],
        [self.searchButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:40],
        [self.searchButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-40],
        [self.searchButton.heightAnchor constraintEqualToConstant:44]
    ]];
}

- (void)searchButtonTapped:(UIButton *)sender {
    NSString *cityName = self.searchTextField.text;
    NSLog(@"搜索城市: %@", cityName);
    //https://restapi.amap.com/v3/weather/weatherInfo?city=110101&key=8cf27aab0f75fb3d9577af38b72ee015	
}

    //8cf27aab0f75fb3d9577af38b72ee015	
}
@end
