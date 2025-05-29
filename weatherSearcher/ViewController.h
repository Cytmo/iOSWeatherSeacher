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
@property (nonatomic, strong) NSString *apiKey;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;

// 天气卡片相关的 UI 组件
@property (nonatomic, strong) UIView *weatherView;
@property (nonatomic, strong) UILabel *locationLabel;      // 地点
@property (nonatomic, strong) UILabel *temperatureLabel;   // 气温
@property (nonatomic, strong) UILabel *weatherLabel;       // 天气
@property (nonatomic, strong) UILabel *windLabel;          // 风向风力
@property (nonatomic, strong) UILabel *humidityLabel;      // 湿度
@property (nonatomic, strong) UILabel *updateTimeLabel;    
@end
