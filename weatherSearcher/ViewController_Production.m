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
#import <Masonry/Masonry.h>
#import <AFNetworking/AFNetworking.h>

NSString *const API_KEY_PATH = @"gaodeMapApiKey";

// 错误代码枚举
typedef NS_ENUM(NSInteger, WeatherErrorCode) {
    WeatherErrorCodeAPIKeyEmpty = 1001,
    WeatherErrorCodeAPIKeyNotFound = 1002,
    WeatherErrorCodeCityNameEmpty = 2001,
    WeatherErrorCodeCityNotSupported = 2002,
    WeatherErrorCodeCityNotFound = 2003,
    WeatherErrorCodeAdcodeNotFound = 2004,
    WeatherErrorCodeNetworkNoData = 3001,
    WeatherErrorCodeNetworkFailure = 3002,
    WeatherErrorCodeDataParsingError = 3003,
    WeatherErrorCodeWeatherDataEmpty = 4001,
    WeatherErrorCodeWeatherAPIFailure = 4002,
};

@interface ViewController ()

@end

@implementation ViewController

- (NSError *)createErrorWithCode:(WeatherErrorCode)code message:(NSString *)message {
    return [NSError errorWithDomain:@"WeatherSearcher"
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey : message}];
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert =
            [UIAlertController alertControllerWithTitle:title
                                                message:message
                                         preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             NSLog(@"用户点击了确定按钮");
                                                         }];

        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)handleNetworkError:(NSError *)error {
    NSString *message = @"网络请求失败";
    if (error.code == WeatherErrorCodeNetworkNoData) {
        message = @"未收到数据";
    }
    [self showAlert:@"网络错误" message:message];
}

- (void)handleDataError:(NSError *)error {
    [self showAlert:@"数据错误" message:error.localizedDescription];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!self.apiKey || [self.apiKey length] == 0) {
        [self readApiKey];
    }
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

    self.weatherView = [[UIView alloc] init];
    self.weatherView.backgroundColor = [UIColor systemCyanColor];
    self.weatherView.layer.cornerRadius = 12;
    self.weatherView.translatesAutoresizingMaskIntoConstraints = NO;
    self.weatherView.hidden = YES;
    [self.view addSubview:self.weatherView];

    [self setupWeatherLabels];

    UITapGestureRecognizer *tapGesture =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(weatherCardTapped:)];
    [self.weatherView addGestureRecognizer:tapGesture];

    self.loadingIndicator = [[UIActivityIndicatorView alloc] init];
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingIndicator];
}

- (void)setupConstraints {
    [self.searchTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view).offset(-50);
        make.left.equalTo(self.view).offset(40);
        make.right.equalTo(self.view).offset(-40);
        make.height.equalTo(@44);
    }];

    [self.searchButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.searchTextField.mas_bottom).offset(20);
        make.left.right.equalTo(self.searchTextField);
        make.height.equalTo(@44);
    }];

    [self.loadingIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];

    [self.weatherView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.searchButton.mas_bottom).offset(30);
        make.left.right.equalTo(self.searchTextField);
        make.height.equalTo(@200);
    }];

    [self.locationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.weatherView).offset(16);
        make.left.right.equalTo(self.weatherView).insets(UIEdgeInsetsMake(0, 16, 0, 16));
    }];

    [self.temperatureLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.locationLabel.mas_bottom).offset(8);
        make.centerX.equalTo(self.weatherView);
    }];

    [self.weatherLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.temperatureLabel.mas_bottom).offset(4);
        make.centerX.equalTo(self.weatherView);
    }];

    [self.windLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.weatherLabel.mas_bottom).offset(12);
        make.left.equalTo(self.weatherView).offset(16);
        make.width.equalTo(self.weatherView).multipliedBy(0.45);
    }];

    [self.humidityLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.weatherLabel.mas_bottom).offset(12);
        make.trailing.equalTo(self.weatherView.mas_trailing).offset(-16);
        make.width.equalTo(self.weatherView).multipliedBy(0.45);
    }];

    [self.updateTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.weatherView).offset(-12);
        make.left.right.equalTo(self.weatherView).insets(UIEdgeInsetsMake(0, 16, 0, 16));
    }];
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
        NSError *error = [self createErrorWithCode:WeatherErrorCodeAPIKeyNotFound
                                           message:@"无法找到API密钥文件"];
        [self handleDataError:error];
        return;
    }

    NSError *readError;
    NSString *key = [NSString stringWithContentsOfFile:keyPath
                                              encoding:NSUTF8StringEncoding
                                                 error:&readError];

    if (readError) {
        NSLog(@"读取文件错误: %@", readError.localizedDescription);
        NSError *error = [self createErrorWithCode:WeatherErrorCodeAPIKeyNotFound
                                           message:@"无法找到API密钥文件"];
        [self handleDataError:error];
        return;
    }

    key = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (!key || key.length == 0) {
        NSLog(@"错误: API密钥为空");
        NSError *error = [self createErrorWithCode:WeatherErrorCodeAPIKeyEmpty
                                           message:@"API密钥为空"];
        [self handleDataError:error];
        return;
    } else {
        self.apiKey = key;
        NSLog(@"成功读取API密钥: %@", self.apiKey);
    }
}

- (void)getAdcodeForCity:(NSString *)cityName
              completion:(void (^)(NSString *adcode, NSError *error))completion {
    if (!cityName || cityName.length == 0) {
        NSError *error = [self createErrorWithCode:WeatherErrorCodeCityNameEmpty
                                           message:@"城市名称不能为空"];
        completion(nil, error);
        return;
    }

    if ([cityName isEqualToString:@"中国"] || [cityName isEqualToString:@"100000"] ||
        [cityName isEqualToString:@"中"]) {
        NSError *error = [self createErrorWithCode:WeatherErrorCodeCityNotSupported
                                           message:@"仅支持省级及以下行政区划的查询"];
        completion(nil, error);
        return;
    }

    NSString *urlString =
        [NSString stringWithFormat:@"https://restapi.amap.com/v3/config/"
                                   @"district?keywords=%@&subdistrict=0&extensions=base&key=%@",
                                   cityName,
                                   self.apiKey];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:urlString
        parameters:nil
        headers:nil
        progress:nil
        success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
            NSArray *districts = responseObject[@"districts"];
            if (![districts isKindOfClass:[NSArray class]] || [districts count] == 0) {
                NSError *error = [self createErrorWithCode:WeatherErrorCodeDataParsingError
                                                   message:@"无法找到行政区划数据"];
                completion(nil, error);
                return;
            }

            NSDictionary *firstDistrict = districts[0];
            if (!firstDistrict) {
                NSError *error = [self createErrorWithCode:WeatherErrorCodeDataParsingError
                                                   message:@"无法找到行政区划数据"];
                completion(nil, error);
                return;
            }
            NSString *adcode = firstDistrict[@"adcode"];
            completion(adcode, nil);
        }
        failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
            completion(nil, error);
        }];
}

- (void)fetchWeatherWithAdcode:(NSString *)adcode {
    NSString *urlString = [NSString
        stringWithFormat:@"https://restapi.amap.com/v3/weather/weatherInfo?city=%@&key=%@",
                         adcode,
                         self.apiKey];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:urlString
        parameters:nil
        headers:nil
        progress:nil
        success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
            WeatherData *weatherData = [self parseWeatherDataFromAFNetworking:responseObject];
            if (!weatherData) {
                NSError *error = [self createErrorWithCode:WeatherErrorCodeDataParsingError
                                                   message:@"天气数据解析失败"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self handleDataError:error];
                });
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateWeatherCard:weatherData];
            });
            [self hideLoading];
        }
        failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self handleDataError:error];
                [self hideLoading];
            });
        }];
}

- (WeatherData *)parseWeatherDataFromAFNetworking:(NSDictionary *)jsonResponse {
    if (![jsonResponse isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSInteger statusCode = [jsonResponse[@"status"] integerValue];
    if (statusCode != 1) {
        return nil;
    }
    NSArray *lives = jsonResponse[@"lives"];
    if (!lives || lives.count == 0) {
        return nil;
    }
    NSDictionary *liveWeather = lives[0];
    if (!liveWeather || ![liveWeather isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return [[WeatherData alloc] initWithDictionary:liveWeather];
}

- (void)updateWeatherCard:(WeatherData *)weatherData {
    NSAssert([NSThread isMainThread], @"UI更新必须在主线程中执行");

    self.locationLabel.text =
        [NSString stringWithFormat:@"%@ · %@", weatherData.province, weatherData.city];
    self.temperatureLabel.text = [NSString stringWithFormat:@"%@°", weatherData.temperature];
    self.weatherLabel.text = weatherData.weather;
    self.windLabel.text = [NSString
        stringWithFormat:@"风向: %@ %@级", weatherData.windDirection, weatherData.windPower];
    self.humidityLabel.text = [NSString stringWithFormat:@"湿度: %@%%", weatherData.humidity];
    self.updateTimeLabel.text = [NSString stringWithFormat:@"更新时间: %@", weatherData.reportTime];

    [self showWeatherCardWithAnimation];
}

- (void)showWeatherCardWithAnimation {
    if (self.weatherView.hidden) {
        self.weatherView.hidden = NO;
        self.weatherView.alpha = 0.0;
        self.weatherView.transform = CGAffineTransformMakeScale(0.8, 0.8);

        [UIView animateWithDuration:0.8
                              delay:0.0
             usingSpringWithDamping:2
              initialSpringVelocity:0.1
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.weatherView.alpha = 1.0;
                             self.weatherView.transform = CGAffineTransformIdentity;
                         }
                         completion:nil];
    } else {
        [UIView animateWithDuration:0.2
            animations:^{
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
    self.searchButton.enabled = NO;
    [self showLoading];
    NSString *cityName = self.searchTextField.text;
    NSLog(@"搜索城市: %@", cityName);

    [self getAdcodeForCity:cityName
                completion:^(NSString *adcode, NSError *error) {
                    if (error) {
                        NSLog(@"错误: %@", error.localizedDescription);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self handleDataError:error];
                            [self hideLoading];
                        });
                        return;
                    }
                    NSLog(@"adcode: %@", adcode);
                    [self fetchWeatherWithAdcode:adcode];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self hideLoading];
                    });
                }];
}

- (void)setupWeatherLabels {
    self.locationLabel = [[UILabel alloc] init];
    self.locationLabel.font = [UIFont boldSystemFontOfSize:18];
    self.locationLabel.textColor = [UIColor whiteColor];
    self.locationLabel.textAlignment = NSTextAlignmentCenter;
    self.locationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.weatherView addSubview:self.locationLabel];

    self.temperatureLabel = [[UILabel alloc] init];
    self.temperatureLabel.font = [UIFont systemFontOfSize:36 weight:UIFontWeightLight];
    self.temperatureLabel.textColor = [UIColor whiteColor];
    self.temperatureLabel.textAlignment = NSTextAlignmentCenter;
    self.temperatureLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.weatherView addSubview:self.temperatureLabel];

    self.weatherLabel = [[UILabel alloc] init];
    self.weatherLabel.font = [UIFont systemFontOfSize:16];
    self.weatherLabel.textColor = [UIColor whiteColor];
    self.weatherLabel.textAlignment = NSTextAlignmentCenter;
    self.weatherLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.weatherView addSubview:self.weatherLabel];

    self.windLabel = [[UILabel alloc] init];
    self.windLabel.font = [UIFont systemFontOfSize:14];
    self.windLabel.textColor = [UIColor whiteColor];
    self.windLabel.textAlignment = NSTextAlignmentCenter;
    self.windLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.weatherView addSubview:self.windLabel];

    self.humidityLabel = [[UILabel alloc] init];
    self.humidityLabel.font = [UIFont systemFontOfSize:14];
    self.humidityLabel.textColor = [UIColor whiteColor];
    self.humidityLabel.textAlignment = NSTextAlignmentCenter;
    self.humidityLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.weatherView addSubview:self.humidityLabel];

    self.updateTimeLabel = [[UILabel alloc] init];
    self.updateTimeLabel.font = [UIFont systemFontOfSize:12];
    self.updateTimeLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.8];
    self.updateTimeLabel.textAlignment = NSTextAlignmentCenter;
    self.updateTimeLabel.numberOfLines = 0;
    self.updateTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.weatherView addSubview:self.updateTimeLabel];
}

- (void)weatherCardTapped:(UITapGestureRecognizer *)gesture {
    NSLog(@"weatherCardTapped");
    [UIView animateWithDuration:0.2
        animations:^{
            self.weatherView.transform = CGAffineTransformMakeScale(1.05, 1.05);
        }
        completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1
                             animations:^{
                                 self.weatherView.transform = CGAffineTransformIdentity;
                             }];
        }];
}

@end