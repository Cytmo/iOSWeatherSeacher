//
//  ViewController.m
//  weatherSearcher
//
//  Created by 孔维辰 on 2025/5/27.
//

#import "ViewController.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WeatherData.h"
// 不需要相对路径，因为iOS Bundle会将所有资源文件扁平化存储
NSString *const API_KEY_PATH = @"gaodeMapApiKey";

// 错误代码枚举
typedef NS_ENUM(NSInteger, WeatherErrorCode) {
    // API
    WeatherErrorCodeAPIKeyEmpty = 1001,    // API密钥为空
    WeatherErrorCodeAPIKeyNotFound = 1002, // 无法找到API密钥文件

    // adcode
    WeatherErrorCodeCityNameEmpty = 2001,    // 城市名称不能为空
    WeatherErrorCodeCityNotSupported = 2002, // 仅支持省级及以下行政区划的查询
    WeatherErrorCodeCityNotFound = 2003,     // 未找到该城市
    WeatherErrorCodeAdcodeNotFound = 2004,   // 未获取到adcode

    // 网络
    WeatherErrorCodeNetworkNoData = 3001,    // 未收到数据
    WeatherErrorCodeNetworkFailure = 3002,   // 网络请求失败
    WeatherErrorCodeDataParsingError = 3003, // 数据解析错误

    // 天气 api
    WeatherErrorCodeWeatherDataEmpty = 4001,  // 暂无天气数据
    WeatherErrorCodeWeatherAPIFailure = 4002, // 获取天气信息失败
};

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!self.apiKey || [self.apiKey length] == 0) {
        [self readApiKey];
    }
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
    [self.searchButton addTarget:self
                          action:@selector(searchButtonTapped:)
                forControlEvents:UIControlEventTouchUpInside];
    [self.searchButton setTitle:@"搜索" forState:UIControlStateNormal];
    self.searchButton.backgroundColor = [UIColor systemCyanColor];
    [self.searchButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.searchButton.layer.cornerRadius = 8;
    self.searchButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.searchButton];

    // 创建天气卡片view
    self.weatherView = [[UIView alloc] init];
    self.weatherView.backgroundColor = [UIColor systemCyanColor];
    self.weatherView.layer.cornerRadius = 12;
    self.weatherView.translatesAutoresizingMaskIntoConstraints = NO;
    self.weatherView.hidden = YES; // 有数据时才显示
    [self.view addSubview:self.weatherView];

    // 创建天气信息标签
    [self setupWeatherLabels];

    // 给天气卡片添加点击手势
    UITapGestureRecognizer *tapGesture =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(weatherCardTapped:)];
    [self.weatherView addGestureRecognizer:tapGesture];

    // 在网络请求过程中显示的加载指示器
    self.loadingIndicator = [[UIActivityIndicatorView alloc] init];
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingIndicator];
}

- (void)setupConstraints {
    [NSLayoutConstraint activateConstraints:@[
        // 搜索框约束
        [self.searchTextField.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.searchTextField.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor
                                                           constant:-50],
        [self.searchTextField.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor
                                                           constant:40],
        [self.searchTextField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor
                                                            constant:-40],
        [self.searchTextField.heightAnchor constraintEqualToConstant:44],

        // 搜索按钮约束
        [self.searchButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.searchButton.topAnchor constraintEqualToAnchor:self.searchTextField.bottomAnchor
                                                    constant:20],
        [self.searchButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor
                                                        constant:40],
        [self.searchButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor
                                                         constant:-40],
        [self.searchButton.heightAnchor constraintEqualToConstant:44],

        // 加载约束
        [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.loadingIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],

        /*
        centerXAnchor     // 水平
        topAnchor         // 相对顶部位置
        leadingAnchor     // 左边距
        trailingAnchor    // 右边距
        heightAnchor      // 高度
        */
        // 天气卡片约束
        [self.weatherView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.weatherView.topAnchor constraintEqualToAnchor:self.searchButton.bottomAnchor
                                                   constant:30],
        [self.weatherView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor
                                                       constant:40],
        [self.weatherView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor
                                                        constant:-40],
        [self.weatherView.heightAnchor constraintEqualToConstant:200],

        // 天气卡片内部标签约束 UILabel会根据内容自动计算宽高
        [self.locationLabel.topAnchor constraintEqualToAnchor:self.weatherView.topAnchor
                                                     constant:16],
        [self.locationLabel.leadingAnchor constraintEqualToAnchor:self.weatherView.leadingAnchor
                                                         constant:16],
        [self.locationLabel.trailingAnchor constraintEqualToAnchor:self.weatherView.trailingAnchor
                                                          constant:-16],

        [self.temperatureLabel.topAnchor constraintEqualToAnchor:self.locationLabel.bottomAnchor
                                                        constant:8],
        [self.temperatureLabel.centerXAnchor
            constraintEqualToAnchor:self.weatherView.centerXAnchor],

        [self.weatherLabel.topAnchor constraintEqualToAnchor:self.temperatureLabel.bottomAnchor
                                                    constant:4],
        [self.weatherLabel.centerXAnchor constraintEqualToAnchor:self.weatherView.centerXAnchor],

        [self.windLabel.topAnchor constraintEqualToAnchor:self.weatherLabel.bottomAnchor
                                                 constant:12],
        [self.windLabel.leadingAnchor constraintEqualToAnchor:self.weatherView.leadingAnchor
                                                     constant:16],
        [self.windLabel.widthAnchor constraintEqualToAnchor:self.weatherView.widthAnchor
                                                 multiplier:0.45],

        [self.humidityLabel.topAnchor constraintEqualToAnchor:self.weatherLabel.bottomAnchor
                                                     constant:12],
        [self.humidityLabel.trailingAnchor constraintEqualToAnchor:self.weatherView.trailingAnchor
                                                          constant:-16],
        [self.humidityLabel.widthAnchor constraintEqualToAnchor:self.weatherView.widthAnchor
                                                     multiplier:0.45],

        [self.updateTimeLabel.bottomAnchor constraintEqualToAnchor:self.weatherView.bottomAnchor
                                                          constant:-12],
        [self.updateTimeLabel.leadingAnchor constraintEqualToAnchor:self.weatherView.leadingAnchor
                                                           constant:16],
        [self.updateTimeLabel.trailingAnchor constraintEqualToAnchor:self.weatherView.trailingAnchor
                                                            constant:-16],
    ]];
}

- (void)showLoading {
    self.searchButton.enabled = NO;
    [self.loadingIndicator startAnimating];
}

- (void)hideLoading {
    self.searchButton.enabled = YES;
    [self.loadingIndicator stopAnimating];
}

- (void)readApiKey {
    NSString *keyPath = [[NSBundle mainBundle] pathForResource:API_KEY_PATH ofType:@"txt"];

    NSLog(@"API密钥文件路径: %@", keyPath);

    if (!keyPath) {
        NSLog(@"错误: 无法找到API密钥文件");
        return;
    }

    NSError *readError;
    NSString *key = [NSString stringWithContentsOfFile:keyPath
                                              encoding:NSUTF8StringEncoding
                                                 error:&readError];

    if (readError) {
        NSLog(@"读取文件错误: %@", readError.localizedDescription);
        return;
    }

    key = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (!key || key.length == 0) {
        NSLog(@"错误: API密钥为空");
        return;
    } else {
        self.apiKey = key;
        NSLog(@"成功读取API密钥: %@", self.apiKey);
    }
}

- (void)getAdcodeForCity:(NSString *)cityName
              completion:(void (^)(NSString *adcode, NSError *error))completion {
    if (!cityName || cityName.length == 0) {
        NSError *error =
            [NSError errorWithDomain:@"WeatherSearcher"
                                code:WeatherErrorCodeCityNameEmpty
                            userInfo:@{NSLocalizedDescriptionKey : @"城市名称不能为空"}];
        completion(nil, error);
        return;
    }

    // adcode
    // api直接输入adcode也可以查询，但直接输入100000/中国/中，其格式与其他输入不同，为了规避该问题，禁止用户输入中国或100000
    if ([cityName isEqualToString:@"中国"] || [cityName isEqualToString:@"100000"] ||
        [cityName isEqualToString:@"中"]) {
        NSError *error = [NSError
            errorWithDomain:@"WeatherSearcher"
                       code:WeatherErrorCodeCityNotSupported
                   userInfo:@{NSLocalizedDescriptionKey : @"仅支持省级及以下行政区划的查询"}];
        completion(nil, error);
        return;
    }
    // 构建行政区域查询API URL
    NSString *urlString =
        [NSString stringWithFormat:@"https://restapi.amap.com/v3/config/"
                                   @"district?keywords=%@&subdistrict=0&extensions=base&key=%@",
                                   cityName,
                                   self.apiKey];

    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSession *session = [NSURLSession sharedSession];

    NSURLSessionDataTask *task = [session
        dataTaskWithRequest:request
          completionHandler:^(
              NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
              if (error) {
                  completion(nil, error);
                  return;
              }

              if (!data) {
                  NSError *noDataError =
                      [NSError errorWithDomain:@"WeatherSearcher"
                                          code:WeatherErrorCodeNetworkNoData
                                      userInfo:@{NSLocalizedDescriptionKey : @"未收到数据"}];
                  completion(nil, noDataError);
                  return;
              }

              NSError *jsonError;
              NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                           options:0
                                                                             error:&jsonError];
              if (jsonError) {
                  completion(nil, jsonError);
                  return;
              }

              // 获取districts数组
              NSArray *districts = jsonResponse[@"districts"];
              if (!districts || districts.count == 0) {
                  NSError *notFoundError =
                      [NSError errorWithDomain:@"WeatherSearcher"
                                          code:WeatherErrorCodeCityNotFound
                                      userInfo:@{NSLocalizedDescriptionKey : @"未找到该城市"}];
                  completion(nil, notFoundError);
                  return;
              }

              // 获取第一个匹配结果的adcode
              NSDictionary *firstDistrict = districts[0];
              NSString *adcode = firstDistrict[@"adcode"];

              if (!adcode) {
                  NSError *noAdcodeError =
                      [NSError errorWithDomain:@"WeatherSearcher"
                                          code:WeatherErrorCodeAdcodeNotFound
                                      userInfo:@{NSLocalizedDescriptionKey : @"未获取到adcode"}];
                  completion(nil, noAdcodeError);
                  return;
              }

              completion(adcode, nil);
          }];

    [task resume];
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:title
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];

    // 添加确定按钮来关闭alert
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *_Nonnull action) {
                                                         // 点击确定后的操作（可以为空，仅用于关闭alert）
                                                         NSLog(@"用户点击了确定按钮");
                                                     }];

    [alert addAction:okAction];

    // 在主线程中显示alert
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)fetchWeatherWithAdcode:(NSString *)adcode {
    // 构建天气查询API URL
    NSString *urlString = [NSString
        stringWithFormat:@"https://restapi.amap.com/v3/weather/weatherInfo?city=%@&key=%@",
                         adcode,
                         self.apiKey];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSession *session = [NSURLSession sharedSession];

    NSURLSessionDataTask *task = [session
        dataTaskWithRequest:request
          completionHandler:^(
              NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
              if (error) {
                  [self showAlert:@"网络错误" message:@"网络请求失败"];
                  return;
              }

              if (data) {
                  NSError *jsonError;
                  NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                               options:0
                                                                                 error:&jsonError];
                  if (jsonError) {
                      [self showAlert:@"数据解析错误" message:@"数据解析错误"];
                      return;
                  }

                  dispatch_async(dispatch_get_main_queue(), ^{
                      NSLog(@"天气数据: %@", jsonResponse);
                      [self displayWeatherData:jsonResponse];
                  });
              }
          }];

    [task resume];
}

// 显示天气数据
- (void)displayWeatherData:(NSDictionary *)jsonResponse {
    // 检查API返回状态
    if (!jsonResponse || ![jsonResponse isKindOfClass:[NSDictionary class]]) {
        [self showAlert:@"错误" message:@"天气数据格式错误"];
        return;
    }

    NSInteger statusCode = [jsonResponse[@"status"] integerValue];
    if (statusCode != 1) {
        [self showAlert:@"错误" message:@"获取天气信息失败"];
        return;
    }

    // 解析天气数据
    NSArray *lives = jsonResponse[@"lives"];
    if (![lives isKindOfClass:[NSArray class]] || lives.count == 0) {
        [self showAlert:@"错误" message:@"暂无天气数据"];
        return;
    }

    NSDictionary *weatherInfo = lives[0];
    if (![weatherInfo isKindOfClass:[NSDictionary class]]) {
        [self showAlert:@"错误" message:@"天气详情数据格式错误"];
        return;
    }
    NSObject *weatherData = [[WeatherData alloc] initWithDictionary:(NSDictionary *)weatherInfo];
    if (!weatherData) {
        [self showAlert:@"错误" message:@"天气数据解析失败"];
        return;
    }
    [self updateWeatherCard:weatherData];
}
// 更新天气卡片
- (void)updateWeatherCard:(WeatherData *)weatherData {
    // 更新标签内容
    self.locationLabel.text =
        [NSString stringWithFormat:@"%@ · %@", weatherData.province, weatherData.city];
    self.temperatureLabel.text = [NSString stringWithFormat:@"%@°", weatherData.temperature];
    self.weatherLabel.text = weatherData.weather;
    self.windLabel.text = [NSString
        stringWithFormat:@"风向: %@ %@级", weatherData.windDirection, weatherData.windPower];
    self.humidityLabel.text = [NSString stringWithFormat:@"湿度: %@%%", weatherData.humidity];
    self.updateTimeLabel.text = [NSString stringWithFormat:@"更新时间: %@", weatherData.reportTime];

    /*
    // 显示动画（正确方式）
    self.weatherView.hidden = NO;           // 先设置为显示
    self.weatherView.alpha = 0.0;           // 但是透明
    [UIView animateWithDuration:0.3 animations:^{
        self.weatherView.alpha = 1.0;       // 动画到不透明
    }];

    // 隐藏动画（正确方式）
    [UIView animateWithDuration:0.3 animations:^{
        self.weatherView.alpha = 0.0;       // 动画到透明
    } completion:^(BOOL finished) {
        self.weatherView.hidden = YES;      // 动画结束后真正隐藏
    }];
    */
    // 显示天气卡片
    if (self.weatherView.hidden) {
        self.weatherView.hidden = NO;
        self.weatherView.alpha = 0.0;
        // 缩小到80，方便由小到大的动画效果
        self.weatherView.transform = CGAffineTransformMakeScale(0.8, 0.8);

        // 从小到大的动画
        [UIView animateWithDuration:0.8
                              delay:0.0
             usingSpringWithDamping:2
              initialSpringVelocity:0.1
                            // 淡入淡出
                            options:UIViewAnimationOptionCurveEaseInOut

                         animations:^{
                             self.weatherView.alpha = 1.0;
                             // 恢复到原始大小
                             self.weatherView.transform = CGAffineTransformIdentity;
                         }
                         completion:nil];
    } else {
        // 如果已经显示，添加轻微的动画
        [UIView animateWithDuration:0.2
            animations:^{
                // 由大变小，强调已经有了结果
                self.weatherView.transform = CGAffineTransformMakeScale(1.2, 1.2);
            }
            completion:^(BOOL finished) {
                [UIView animateWithDuration:0.6
                                 animations:^{
                                     self.weatherView.transform = CGAffineTransformIdentity;
                                 }];
            }];
    }
}

- (void)searchButtonTapped:(UIButton *)sender {
    // 不能使用gcd在主线程显示加载，似乎会导致用户可以多次触发搜索
    // 并非gcd导致
    // 原因未知
    self.searchButton.enabled = NO;
    [self showLoading];
    NSString *cityName = self.searchTextField.text;
    NSLog(@"搜索城市: %@", cityName);
    // 使用adcode api找到用户输入的城市对应的adcode
    [self getAdcodeForCity:cityName
                completion:^(NSString *adcode, NSError *error) {
                    if (error) {
                        NSLog(@"错误: %@", error.localizedDescription);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self showAlert:@"错误" message:error.localizedDescription];
                        });
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self hideLoading];
                        });

                        return;
                    }
                    NSLog(@"adcode: %@", adcode);
                    // 使用adcode获取天气信息
                    // 实际上高德天气API可以接受非adcode的city name 但并未在文档中找到相关说明
                    [self fetchWeatherWithAdcode:adcode];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self hideLoading];
                    });
                }];
}

- (void)setupWeatherLabels {
    // 地点
    self.locationLabel = [[UILabel alloc] init];
    self.locationLabel.font = [UIFont boldSystemFontOfSize:18];
    self.locationLabel.textColor = [UIColor whiteColor];
    self.locationLabel.textAlignment = NSTextAlignmentCenter;
    self.locationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.weatherView addSubview:self.locationLabel];

    // 气温
    self.temperatureLabel = [[UILabel alloc] init];
    self.temperatureLabel.font = [UIFont systemFontOfSize:36 weight:UIFontWeightLight];
    self.temperatureLabel.textColor = [UIColor whiteColor];
    self.temperatureLabel.textAlignment = NSTextAlignmentCenter;
    self.temperatureLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.weatherView addSubview:self.temperatureLabel];

    // 天气状况
    self.weatherLabel = [[UILabel alloc] init];
    self.weatherLabel.font = [UIFont systemFontOfSize:16];
    self.weatherLabel.textColor = [UIColor whiteColor];
    self.weatherLabel.textAlignment = NSTextAlignmentCenter;
    self.weatherLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.weatherView addSubview:self.weatherLabel];

    // 风向风力
    self.windLabel = [[UILabel alloc] init];
    self.windLabel.font = [UIFont systemFontOfSize:14];
    self.windLabel.textColor = [UIColor whiteColor];
    self.windLabel.textAlignment = NSTextAlignmentCenter;
    self.windLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.weatherView addSubview:self.windLabel];

    // 湿度
    self.humidityLabel = [[UILabel alloc] init];
    self.humidityLabel.font = [UIFont systemFontOfSize:14];
    self.humidityLabel.textColor = [UIColor whiteColor];
    self.humidityLabel.textAlignment = NSTextAlignmentCenter;
    self.humidityLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.weatherView addSubview:self.humidityLabel];

    // 更新时间
    self.updateTimeLabel = [[UILabel alloc] init];
    self.updateTimeLabel.font = [UIFont systemFontOfSize:12];
    self.updateTimeLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.8];
    self.updateTimeLabel.textAlignment = NSTextAlignmentCenter;
    self.updateTimeLabel.numberOfLines = 0;
    self.updateTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.weatherView addSubview:self.updateTimeLabel];
}

- (void)weatherCardTapped:(UITapGestureRecognizer *)gesture {
    // 点击卡片时显示详细信息的 Alert
    NSLog(@"weatherCardTapped");
    [UIView animateWithDuration:0.2
        animations:^{
            // 由大变小，强调已经有了结果
            self.weatherView.transform = CGAffineTransformMakeScale(1.05, 1.05);
        }
        /*^(BOOL finished) {
         [UIView animateWithDuration:0.6
                          animations:^{
                              self.weatherView.transform = CGAffineTransformIdentity;
                          }];
     }];*/
        completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1
                             animations:^{
                                 self.weatherView.transform = CGAffineTransformIdentity;
                             }];
        }];
}
@end
