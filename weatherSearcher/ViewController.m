//
//  ViewController.m
//  weatherSearcher
//
//  Created by 孔维辰 on 2025/5/27.
//

#import "ViewController.h"
#import <Foundation/Foundation.h>

// 天气应用错误域
NSString *const WeatherSearcherErrorDomain = @"com.ks.weatherSearcher.error";
// 不需要相对路径，因为iOS Bundle会将所有资源文件扁平化存储
NSString *const API_KEY_PATH = @"gaodeMapApiKey";
// 天气应用错误代码枚举
typedef NS_ENUM(NSInteger, WeatherErrorCode) {
    // API相关错误
    WeatherErrorCodeAPIKeyEmpty = 1001,          // API密钥为空
    WeatherErrorCodeAPIKeyNotFound = 1002,       // 无法找到API密钥文件
    
    // 城市搜索相关错误
    WeatherErrorCodeCityNameEmpty = 2001,        // 城市名称不能为空
    WeatherErrorCodeCityNotSupported = 2002,     // 仅支持省级及以下行政区划的查询
    WeatherErrorCodeCityNotFound = 2003,         // 未找到该城市
    WeatherErrorCodeAdcodeNotFound = 2004,       // 未获取到adcode
    
    // 网络相关错误
    WeatherErrorCodeNetworkNoData = 3001,        // 未收到数据
    WeatherErrorCodeNetworkFailure = 3002,       // 网络请求失败
    WeatherErrorCodeDataParsingError = 3003,     // 数据解析错误
    
    // 天气数据相关错误
    WeatherErrorCodeWeatherDataEmpty = 4001,     // 暂无天气数据
    WeatherErrorCodeWeatherAPIFailure = 4002,    // 获取天气信息失败
};

// 错误代码描述映射函数
NSString *WeatherErrorDescription(WeatherErrorCode errorCode) {
    switch (errorCode) {
        // API相关错误
        case WeatherErrorCodeAPIKeyEmpty:
            return @"API密钥为空";
        case WeatherErrorCodeAPIKeyNotFound:
            return @"无法找到API密钥文件，请确保gaodeMapApiKey.txt已添加到项目Bundle Resources中";
            
        // 城市搜索相关错误
        case WeatherErrorCodeCityNameEmpty:
            return @"城市名称不能为空";
        case WeatherErrorCodeCityNotSupported:
            return @"仅支持省级及以下行政区划的查询";
        case WeatherErrorCodeCityNotFound:
            return @"未找到该城市";
        case WeatherErrorCodeAdcodeNotFound:
            return @"未获取到adcode";
            
        // 网络相关错误
        case WeatherErrorCodeNetworkNoData:
            return @"未收到数据";
        case WeatherErrorCodeNetworkFailure:
            return @"网络请求失败";
        case WeatherErrorCodeDataParsingError:
            return @"数据解析错误";
            
        // 天气数据相关错误
        case WeatherErrorCodeWeatherDataEmpty:
            return @"暂无天气数据";
        case WeatherErrorCodeWeatherAPIFailure:
            return @"获取天气信息失败";
            
        default:
            return @"未知错误";
    }
}

// 创建错误对象
NSError *WeatherError(WeatherErrorCode errorCode) {
    return [NSError errorWithDomain:WeatherSearcherErrorDomain 
                               code:errorCode 
                           userInfo:@{NSLocalizedDescriptionKey: WeatherErrorDescription(errorCode)}];
}


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if(!self.apiKey || [self.apiKey length] ==0){
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
    [self.searchButton addTarget:self action:@selector(searchButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.searchButton setTitle:@"搜索" forState:UIControlStateNormal];
    self.searchButton.backgroundColor = [UIColor systemBlueColor];
    [self.searchButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.searchButton.layer.cornerRadius = 8;
    self.searchButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.searchButton];

    // 测试auto layout， 添加一个weatherview
    self.weatherView = [[UIView alloc] init];
    self.weatherView.backgroundColor = [UIColor systemBlueColor];
    self.weatherView.layer.cornerRadius = 8;
    self.weatherView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.weatherView];
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
        [self.searchButton.heightAnchor constraintEqualToConstant:44],

        // weatherview约束
        [self.weatherView.centerXAnchor constraintEqualToAnchor: self.view.centerXAnchor ],
        [self.weatherView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:100],
        [self.weatherView.heightAnchor constraintEqualToConstant:88],
        [self.weatherView.widthAnchor constraintEqualToConstant:200],
    ]];
}

- (void) readApiKey {
    NSString *keyPath = [[NSBundle mainBundle] pathForResource:API_KEY_PATH ofType:@"txt"];
    
    NSLog(@"API密钥文件路径: %@", keyPath);
    
    if (!keyPath) {
        NSLog(@"错误: %@", WeatherError(WeatherErrorCodeAPIKeyNotFound));
        return;
    }
    
    NSError *readError;
    NSString *key = [NSString stringWithContentsOfFile:keyPath encoding:NSUTF8StringEncoding error:&readError];
    
    if (readError) {
        NSLog(@"读取文件错误: %@", readError.localizedDescription);
        return;
    }
    
    key = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    
    if (!key || key.length == 0) {
        NSError *error = WeatherError(WeatherErrorCodeAPIKeyEmpty);
        NSLog(@"错误: %@", error.localizedDescription);
        return;
    } else {
        self.apiKey = key;
        NSLog(@"成功读取API密钥: %@", self.apiKey);
    }
}

- (void)getAdcodeForCity:(NSString *)cityName completion:(void (^)(NSString *adcode, NSError *error))completion {
    if (!cityName || cityName.length == 0) {
        NSError *error = WeatherError(WeatherErrorCodeCityNameEmpty);
        completion(nil, error);
        return;
    }
    
    // adcode api直接输入adcode也可以查询，但直接输入100000/中国/中，其格式与其他输入不同，为了规避该问题，禁止用户输入中国或100000
    if([cityName isEqualToString:@"中国"] || [cityName isEqualToString:@"100000"] || [cityName isEqualToString:@"中"]){
        NSError *error = WeatherError(WeatherErrorCodeCityNotSupported);
        completion(nil, error);
        return;
    }
    // 构建行政区域查询API URL
    NSString *urlString = [NSString stringWithFormat:@"https://restapi.amap.com/v3/config/district?keywords=%@&subdistrict=0&extensions=base&key=%@", 
                          cityName, self.apiKey];
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
            return;
        }
        
        if (!data) {
            NSError *noDataError = WeatherError(WeatherErrorCodeNetworkNoData);
            completion(nil, noDataError);
            return;
        }
        
        NSError *jsonError;
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
            completion(nil, jsonError);
            return;
        }

        // 获取districts数组
        NSArray *districts = jsonResponse[@"districts"];
        if (!districts || districts.count == 0) {
            NSError *notFoundError = WeatherError(WeatherErrorCodeCityNotFound);
            completion(nil, notFoundError);
            return;
        }
        
        // 获取第一个匹配结果的adcode
        NSDictionary *firstDistrict = districts[0];
        NSString *adcode = firstDistrict[@"adcode"];
        
        if (!adcode) {
            NSError *noAdcodeError = WeatherError(WeatherErrorCodeAdcodeNotFound);
            completion(nil, noAdcodeError);
            return;
        }
        
        completion(adcode, nil);
    }];
    
    [task resume];
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    // 添加确定按钮来关闭alert
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
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
    NSString *urlString = [NSString stringWithFormat:@"https://restapi.amap.com/v3/weather/weatherInfo?city=%@&key=%@", adcode, self.apiKey];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSError *networkError = WeatherError(WeatherErrorCodeNetworkFailure);
            [self showAlert:@"网络错误" message:networkError.localizedDescription];
            return;
        }
        
        if (data) {
            NSError *jsonError;
            NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (jsonError) {
                NSError *parseError = WeatherError(WeatherErrorCodeDataParsingError);
                [self showAlert:@"数据解析错误" message:parseError.localizedDescription];
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
    NSInteger statusCode = [jsonResponse[@"status"] integerValue];
    if(statusCode != 1){
        NSError *apiError = WeatherError(WeatherErrorCodeWeatherAPIFailure);
        [self showAlert:@"错误" message:apiError.localizedDescription];
        return;
    }
    
    // 解析天气数据
    NSArray *lives = jsonResponse[@"lives"];
    if (!lives || lives.count == 0) {
        NSError *dataError = WeatherError(WeatherErrorCodeWeatherDataEmpty);
        [self showAlert:@"错误" message:dataError.localizedDescription];
        return;
    }
    
    NSDictionary *weatherInfo = lives[0];
    
    // 提取天气信息
    NSString *province = weatherInfo[@"province"] ?: @"未知省份";
    NSString *city = weatherInfo[@"city"] ?: @"未知城市";
    NSString *weather = weatherInfo[@"weather"] ?: @"未知";
    NSString *temperature = weatherInfo[@"temperature"] ?: @"--";
    NSString *windDirection = weatherInfo[@"winddirection"] ?: @"--";
    NSString *windPower = weatherInfo[@"windpower"] ?: @"--";
    NSString *humidity = weatherInfo[@"humidity"] ?: @"--";
    NSString *reportTime = weatherInfo[@"reporttime"] ?: @"--";
    
    NSString *title = [NSString stringWithFormat:@"%@·%@·%@", province, city, weather];
    NSString *message = [NSString stringWithFormat:@"位置：%@·%@\n"
                                                   @"温度：%@°C\n"
                                                   @"天气：%@\n"
                                                   @"风向：%@ %@级\n"
                                                   @"湿度：%@%%\n"
                                                   @"更新时间：%@",
                        province, city, temperature, weather,
                        windDirection, windPower, humidity, reportTime];
    
    [self showWeatherAlert:title message:message];
}

- (void)showWeatherAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title 
                                                                   message:message 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    // 添加"确定"按钮
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" 
                                                       style:UIAlertActionStyleDefault 
                                                     handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"用户查看了天气信息");
    }];
    
    // 添加"刷新"按钮
    UIAlertAction *refreshAction = [UIAlertAction actionWithTitle:@"刷新" 
                                                            style:UIAlertActionStyleDefault 
                                                          handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"用户点击了刷新");
        // 重新搜索当前城市的天气
        NSString *currentCity = self.searchTextField.text;
        if (currentCity && currentCity.length > 0) {
            [self searchButtonTapped:self.searchButton];
        }
    }];
    
    [alert addAction:okAction];
    [alert addAction:refreshAction];
    
    // 在主线程中显示alert
    [self presentViewController:alert animated:YES completion:^{
        NSLog(@"天气信息alert已显示");
    }];
}

- (void)searchButtonTapped:(UIButton *)sender {
    NSString *cityName = self.searchTextField.text;
    NSLog(@"搜索城市: %@", cityName);
    // 使用adcode api找到用户输入的城市对应的adcode
    [self getAdcodeForCity:cityName completion:^(NSString *adcode, NSError *error) {
        if(error){
            NSLog(@"错误: %@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showAlert:@"错误" message:error.localizedDescription];
            });
            return;
        }
        NSLog(@"adcode: %@", adcode);
        // 使用adcode获取天气信息
        // 实际上高德天气API可以接受非adcode的city name 但并未在文档中找到相关说明
        [self fetchWeatherWithAdcode:adcode];
    }];

}
@end
