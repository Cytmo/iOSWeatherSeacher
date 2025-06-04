//
//  ViewController.m
//  weatherSearcher
//
//  Created by 孔维辰 on 2025/5/27.
//

/*
 * 【核心类介绍】
 * 
 * 1. AFHTTPSessionManager - 核心网络管理类
 *    - 封装NSURLSession的复杂操作
 *    - 提供GET、POST、PUT、DELETE等HTTP方法
 *    - 管理请求头、超时、认证等配置
 * 
 * 2. 请求序列化器 (Request Serializers)
 *    - AFHTTPRequestSerializer: 标准HTTP请求(默认)
 *    - AFJSONRequestSerializer: JSON格式请求体
 *    - AFPropertyListRequestSerializer: Plist格式请求体
 * 
 * 3. 响应序列化器 (Response Serializers)
 *    - AFJSONResponseSerializer: JSON响应解析(默认)
 *    - AFXMLParserResponseSerializer: XML响应解析
 *    - AFHTTPResponseSerializer: 原始NSData响应
 * 
 * 【基本使用模式】
 * 
 * // 1. 创建管理器
 * AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
 * 
 * // 2. 配置序列化器(可选)
 * manager.requestSerializer = [AFJSONRequestSerializer serializer];
 * manager.responseSerializer = [AFJSONResponseSerializer serializer];
 * 
 * // 3. 发送请求
 * [manager GET:@"https://api.example.com/data"
 *   parameters:@{@"key": @"value"}
 *      headers:@{@"Authorization": @"Bearer token"}
 *     progress:^(NSProgress *progress) {
 *         // 进度回调(可选)
 *     }
 *      success:^(NSURLSessionDataTask *task, id responseObject) {
 *         // 成功回调 - responseObject已解析为NSDictionary/NSArray
 *      }
 *      failure:^(NSURLSessionDataTask *task, NSError *error) {
 *         // 失败回调 - 网络错误或HTTP状态码错误
 *      }];
 * 
 * 【参数说明】
 * 
 * parameters: 请求参数
 * - GET请求: 自动拼接到URL查询字符串
 * - POST请求: 根据requestSerializer编码为请求体
 * 
 * headers: 自定义HTTP请求头
 * - 常用于认证、内容类型等
 * 
 * progress: 进度监控Block
 * - 主要用于文件上传下载
 * - 小数据请求可传nil
 * 
 * success: 成功回调Block
 * - task: NSURLSessionDataTask实例
 * - responseObject: 已解析的响应对象(NSDictionary/NSArray/NSData)
 * 
 * failure: 失败回调Block  
 * - task: NSURLSessionDataTask实例(可能为nil)
 * - error: 错误信息(网络错误、HTTP状态码错误等)
 * 
 * 【线程模型】
 * AFNetworking的success/failure回调默认在主线程执行
 * 这意味着可以直接在回调中更新UI，无需手动dispatch_async
 * 但为了代码清晰和确保一致性，建议显式使用dispatch_async
 * 
 * 【错误处理】
 * AFNetworking会自动处理以下错误：
 * - 网络连接错误 (无网络、超时等)
 * - HTTP状态码错误 (4xx、5xx)
 * - JSON解析错误 (响应不是有效JSON)
 * 
 * 业务逻辑错误仍需在success回调中检查：
 * - API返回的status字段
 * - 数据完整性验证
 * 
 * 【最佳实践】
 * 1. 使用单例模式管理AFHTTPSessionManager
 * 2. 统一配置baseURL、超时时间、请求头
 * 3. 在success回调中验证业务逻辑
 * 4. 使用dispatch_async确保UI更新在主线程
 * 5. 合理处理网络状态变化
 * 
 * ================================================================
 */

#import "ViewController.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WeatherData.h"
#import <Masonry/Masonry.h>
#import <AFNetworking/AFNetworking.h>  // 导入AFNetworking - 现代iOS网络库
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

// 创建自定义错误
- (NSError *)createErrorWithCode:(WeatherErrorCode)code message:(NSString *)message {
    return [NSError errorWithDomain:@"WeatherSearcher" 
                               code:code 
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

// 错误显示
- (void)showAlert:(NSString *)title message:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
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

// 处理网络请求错误
- (void)handleNetworkError:(NSError *)error {
    NSString *message = @"网络请求失败";
    if (error.code == WeatherErrorCodeNetworkNoData) {
        message = @"未收到数据";
    }
    [self showAlert:@"网络错误" message:message];
}

// 处理数据解析错误
- (void)handleDataError:(NSError *)error {
    [self showAlert:@"数据错误" message:error.localizedDescription];
}


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
    /*
     * Auto Layout: [view.centerXAnchor constraintEqualToAnchor:superview.centerXAnchor]
     * Masonry: make.centerX.equalTo(superview)
     * 
     * autolayout与masonry的属性
     * centerXAnchor -> centerX
     * centerYAnchor -> centerY  
     * leadingAnchor -> left (或leading)
     * trailingAnchor -> right (或trailing)
     * topAnchor -> top
     * bottomAnchor -> bottom
     * widthAnchor -> width
     * heightAnchor -> height
     引用其他视图的约束属性时需要mas_前缀
     规则1：make.后面的不需要mas_
     规则2：equalTo()里面引用其他view的需要mas_

     */
    
    /*
     * Auto Layout
     * [self.searchTextField.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
     * [self.searchTextField.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-50],
     * [self.searchTextField.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:40],
     * [self.searchTextField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-40],
     * [self.searchTextField.heightAnchor constraintEqualToConstant:44],
     * 
     * Masonry
     * - mas_makeConstraints: 创建新约束
     * - equalTo(): 等于某个值或视图(constraintEqualToAnchor)
     * - offset(): 添加偏移量，相当于constant
     * - 链式语法：可以连续调用多个方法
     */
    [self.searchTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);                    // 水平居中
        make.centerY.equalTo(self.view).offset(-50);        // 垂直居中，向上偏移50点
        make.left.equalTo(self.view).offset(40);            // 左边距40点
        make.right.equalTo(self.view).offset(-40);          // 右边距40点
        make.height.equalTo(@44);                           // 高度44点
    }];
    
    /*
     * Auto Layout
     * [self.searchButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
     * [self.searchButton.topAnchor constraintEqualToAnchor:self.searchTextField.bottomAnchor constant:20],
     * [self.searchButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:40],
     * [self.searchButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-40],
     * [self.searchButton.heightAnchor constraintEqualToConstant:44],
     * 
     *  Masonry
     * - mas_bottom: 获取视图的底部约束点
     * - left.right.equalTo(): 同时设置左右约束的简化写法
     * - 相对约束：相对于其他视图定位
     */
    [self.searchButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);                    // 水平居中
        make.top.equalTo(self.searchTextField.mas_bottom).offset(20);  // 距离搜索框底部20点
        make.left.right.equalTo(self.searchTextField);     // 左右边距与搜索框一致
        make.height.equalTo(@44);                           // 高度44点
    }];
    
    /*
     * Auto Layout
     * [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
     * [self.loadingIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
     * 
     * Masonry
     * - center: 同时设置centerX和centerY的简化属性
     */
    [self.loadingIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);                   
    }];
    
    /*
     * Auto Layou
     * [self.weatherView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
     * [self.weatherView.topAnchor constraintEqualToAnchor:self.searchButton.bottomAnchor constant:30],
     * [self.weatherView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:40],
     * [self.weatherView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-40],
     * [self.weatherView.heightAnchor constraintEqualToConstant:200],
     * 
     * Masonry复用
     * - 复用已有视图的约束：left.right.equalTo(searchTextField)
     * - 避免重复定义相同的边距值
     */
    [self.weatherView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);                    // 水平居中
        make.top.equalTo(self.searchButton.mas_bottom).offset(30);  // 距离按钮底部30点
        make.left.right.equalTo(self.searchTextField);     // 与搜索框左右对齐
        make.height.equalTo(@200);                          // 高度200点
    }];
        
    /*
     * Auto Layout
     * [self.locationLabel.topAnchor constraintEqualToAnchor:self.weatherView.topAnchor constant:16],
     * [self.locationLabel.leadingAnchor constraintEqualToAnchor:self.weatherView.leadingAnchor constant:16],
     * [self.locationLabel.trailingAnchor constraintEqualToAnchor:self.weatherView.trailingAnchor constant:-16],
     * 
     * Masonry边距
     * - insets(): 统一设置四个方向的边距
     * - UIEdgeInsetsMake(top, left, bottom, right)
     */
    [self.locationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.weatherView).offset(16);      // 距离顶部16点
        make.left.right.equalTo(self.weatherView).insets(UIEdgeInsetsMake(0, 16, 0, 16));  // 左右边距16点
    }];
    
    /*
     Auto Layout
     * [self.temperatureLabel.topAnchor constraintEqualToAnchor:self.locationLabel.bottomAnchor constant:8],
     * [self.temperatureLabel.centerXAnchor constraintEqualToAnchor:self.weatherView.centerXAnchor],
     */

    [self.temperatureLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.locationLabel.mas_bottom).offset(8);  // 距离位置标签底部8点
        make.centerX.equalTo(self.weatherView);             // 在天气卡片中水平居中
    }];
    
    // 天气状况标签
    /*
     * Auto Layout
     * [self.weatherLabel.topAnchor constraintEqualToAnchor:self.temperatureLabel.bottomAnchor constant:4],
     * [self.weatherLabel.centerXAnchor constraintEqualToAnchor:self.weatherView.centerXAnchor],
     */
    [self.weatherLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.temperatureLabel.mas_bottom).offset(4);  // 距离温度标签底部4点
        make.centerX.equalTo(self.weatherView);             // 在天气卡片中水平居中 在此处center和centerX的效果一致
    }];
    
    // 风向风力标签（左侧）
    /*
     * Auto Layout
     * [self.windLabel.topAnchor constraintEqualToAnchor:self.weatherLabel.bottomAnchor constant:12],
     * [self.windLabel.leadingAnchor constraintEqualToAnchor:self.weatherView.leadingAnchor constant:16],
     * [self.windLabel.widthAnchor constraintEqualToAnchor:self.weatherView.widthAnchor multiplier:0.45],
     * 
     * Masonry比例约束
     * - multipliedBy(): 设置比例约束，相当于multiplier
     */
    [self.windLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.weatherLabel.mas_bottom).offset(12);  // 距离天气标签底部12点
        make.left.equalTo(self.weatherView).offset(16);     // 左边距16点
        make.width.equalTo(self.weatherView).multipliedBy(0.45);  // 宽度为父视图的45%
    }];
    
    // 湿度标签（右侧）
    /*
     * Auto Layout
     * [self.humidityLabel.topAnchor constraintEqualToAnchor:self.weatherLabel.bottomAnchor constant:12],
     * [self.humidityLabel.trailingAnchor constraintEqualToAnchor:self.weatherView.trailingAnchor constant:-16],
     * [self.humidityLabel.widthAnchor constraintEqualToAnchor:self.weatherView.widthAnchor multiplier:0.45],
     */

    [self.humidityLabel mas_makeConstraints:^(MASConstraintMaker *make){
        make.top.equalTo(self.weatherLabel.mas_bottom).offset(12);
        make.trailing.equalTo(self.weatherView.mas_trailing).offset(-16);
        make.width.equalTo(self.weatherView).multipliedBy(0.45);// 宽度为父视图的45%
    }];

    
    // 更新时间标签
    /*
     * Auto Layout
     * [self.updateTimeLabel.bottomAnchor constraintEqualToAnchor:self.weatherView.bottomAnchor constant:-12],
     * [self.updateTimeLabel.leadingAnchor constraintEqualToAnchor:self.weatherView.leadingAnchor constant:16],
     * [self.updateTimeLabel.trailingAnchor constraintEqualToAnchor:self.weatherView.trailingAnchor constant:-16],
     * 
     * Masonry底部对齐
     * - bottom.equalTo(): 底部对齐约束
     * - 负值offset表示向上偏移
   UIEdgeInsetsMake(top, left, bottom, right)
                |    |     |      |
                |    |     |      右边距
                |    |     底边距  
                |    左边距
                顶边距   
     top 和 left 是正值时向内缩进
     bottom 和 right 是正值时向内缩进
    */

    // 设置所有边距为10点
    // [view mas_makeConstraints:^(MASConstraintMaker *make) {
    //     make.edges.equalTo(superview).insets(UIEdgeInsetsMake(10, 10, 10, 10));
    // }];

    // 等价于原生Auto Layout的：
    // view.top = superview.top + 10
    // view.left = superview.left + 10  
    // view.bottom = superview.bottom - 10
    // view.right = superview.right - 10
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
    
    // 参数验证逻辑保持不变
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
    
    // URL构建逻辑保持不变
    NSString *urlString =
        [NSString stringWithFormat:@"https://restapi.amap.com/v3/config/"
                                   @"district?keywords=%@&subdistrict=0&extensions=base&key=%@",
                                   cityName,
                                   self.apiKey];

    /*
     * NSURL *url = [NSURL URLWithString:urlString];
     * NSURLRequest *request = [NSURLRequest requestWithURL:url];
     * NSURLSession *session = [NSURLSession sharedSession];
     * 
     * NSURLSessionDataTask *task = [session
     *     dataTaskWithRequest:request
     *       completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
     *           if (error) {
     *               completion(nil, error);
     *               return;
     *           }
     *           if (!data) {
     *               NSError *noDataError = [self createErrorWithCode:WeatherErrorCodeNetworkNoData 
     *                                                        message:@"未收到数据"];
     *               completion(nil, noDataError);
     *               return;
     *           }
     *           // 手动JSON解析
     *           NSError *jsonError;
     *           NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data
     *                                                                        options:0
     *                                                                          error:&jsonError];
     *           if (jsonError) {
     *               completion(nil, jsonError);
     *               return;
     *           }
     *           // 数据提取逻辑...
     *       }];
     * [task resume];
     */
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:urlString parameters:nil headers:nil progress:nil 
    success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSArray *districts = responseObject[@"districts"];
        if(![districts isKindOfClass:[NSArray class]] || [districts){
            NSError *error = [self createErrorWithCode:WeatherErrorCodeDataParsingError
                                               message:@"无法找到行政区划数据"];
            completion(nil,error);
                  return;
              }
        
        NSDictionary *firstDistrict = districts[0];
        if (!firstDistrict) {
            NSError *error = [self createErrorWithCode:WeatherErrorCodeDataParsingError
                                               message:@"无法找到行政区划数据"];
            completion(nil,error);
                  return;
              }
              NSString *adcode = firstDistrict[@"adcode"];
        completion(adcode,nil);
    }
    failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error){
        completion(nil,error);
    }
    ];
    
}

- (void)fetchWeatherWithAdcode:(NSString *)adcode {
    // URL构建逻辑保持不变
    NSString *urlString = [NSString
        stringWithFormat:@"https://restapi.amap.com/v3/weather/weatherInfo?city=%@&key=%@",
                         adcode,
                         self.apiKey];

    /*
     * 
     * NSURL *url = [NSURL URLWithString:urlString];
     * NSURLRequest *request = [NSURLRequest requestWithURL:url];
     * NSURLSession *session = [NSURLSession sharedSession];
     * 
     * NSURLSessionDataTask *task = [session
     *     dataTaskWithRequest:request
     *       completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
     *           // 复杂的数据处理和线程切换
     *           WeatherData *weatherData = [self processWeatherResponse:data error:error];
     *           dispatch_async(dispatch_get_main_queue(), ^{
     *               if (weatherData) {
     *                   [self updateWeatherCard:weatherData];
     *               }
     *           });
     *       }];
     * [task resume];
     */

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:urlString parameters:nil headers:nil progress:nil
    success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        WeatherData *weatherData = [self parseWeatherDataFromAFNetworking:responseObject];
        if(!weatherData) {
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
    failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleDataError:error];
            [self hideLoading];
        });
    }
    
    ];
    
}

/*
 * 新增方法：专门处理AFNetworking返回的已解析数据
 * 
 * 【设计说明】
 * 原来的processWeatherResponse方法处理NSData和手动JSON解析
 * 新方法直接处理AFNetworking已解析的NSDictionary
 * 保持数据解析逻辑的纯净性，不包含UI操作
 */
- (WeatherData *)parseWeatherDataFromAFNetworking:(NSDictionary *)jsonResponse {
    /*
     * 【实现指导】
     * 1. 检查jsonResponse类型: if (![jsonResponse isKindOfClass:[NSDictionary class]])
     * 2. 检查API状态码: NSInteger statusCode = [jsonResponse[@"status"] integerValue];
     * 3. 验证lives数组: NSArray *lives = jsonResponse[@"lives"];
     * 4. 提取第一个天气数据: NSDictionary *liveWeather = lives[0];
     * 5. 创建WeatherData对象: return [[WeatherData alloc] initWithDictionary:liveWeather];
     * 
     * 【错误处理】
     * 返回nil表示解析失败，让调用者处理UI错误提示
     * 避免在数据解析方法中直接操作UI
     */
    
    if(![jsonResponse isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSInteger statusCode = [jsonResponse[@"status"] integerValue];
    if(statusCode != 1) {
        return nil;
    }
    NSArray *lives = jsonResponse[@"lives"];
    if(!lives || lives.count == 0) {
        return nil;
    }
    NSDictionary *liveWeather = lives[0];
    if(!liveWeather || ![liveWeather isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return [[WeatherData alloc] initWithDictionary:liveWeather];
}

- (void)updateWeatherCard:(WeatherData *)weatherData {
    // 断言确保在主线程
    NSAssert([NSThread isMainThread], @"UI更新必须在主线程中执行");
    
    // 更新标签内容
    self.locationLabel.text = [NSString stringWithFormat:@"%@ · %@", weatherData.province, weatherData.city];
    self.temperatureLabel.text = [NSString stringWithFormat:@"%@°", weatherData.temperature];
    self.weatherLabel.text = weatherData.weather;
    self.windLabel.text = [NSString stringWithFormat:@"风向: %@ %@级", weatherData.windDirection, weatherData.windPower];
    self.humidityLabel.text = [NSString stringWithFormat:@"湿度: %@%%", weatherData.humidity];
    self.updateTimeLabel.text = [NSString stringWithFormat:@"更新时间: %@", weatherData.reportTime];

    // 显示天气卡片动画
    [self showWeatherCardWithAnimation];
}

// 分离动画逻辑
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
                            [self handleDataError:error];
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

/*
 * ==================== AFNetworking 实际使用示例 ====================
 * 
 * 以下是完整的AFNetworking GET请求实现模板
 * 你可以参考这个模板来完成上面的TODO部分
 */

/*
// 示例1: 获取城市adcode的AFNetworking实现
- (void)exampleGetAdcodeWithAFNetworking:(NSString *)cityName {
    // 1. 创建AFHTTPSessionManager
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    // 2. 构建URL
    NSString *urlString = [NSString stringWithFormat:@"https://restapi.amap.com/v3/config/district?keywords=%@&key=%@", cityName, self.apiKey];
    
    // 3. 发送GET请求
    [manager GET:urlString
      parameters:nil                    // GET参数已在URL中，这里为nil
         headers:nil                    // 无需自定义请求头
        progress:nil                    // 小数据请求，无需进度监控
         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
             // 4. 成功回调 - responseObject已经是解析好的NSDictionary
             NSLog(@"API响应: %@", responseObject);
             
             // 5. 类型检查
             if (![responseObject isKindOfClass:[NSDictionary class]]) {
                 NSLog(@"响应格式错误");
                 return;
             }
             
             // 6. 提取数据
             NSDictionary *response = (NSDictionary *)responseObject;
             NSArray *districts = response[@"districts"];
             
             if (!districts || districts.count == 0) {
                 NSLog(@"未找到城市");
                 return;
             }
             
             // 7. 获取adcode
             NSDictionary *firstDistrict = districts[0];
             NSString *adcode = firstDistrict[@"adcode"];
             
             NSLog(@"获取到adcode: %@", adcode);
             
             // 8. 继续后续操作...
         }
         failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
             // 9. 失败回调
             NSLog(@"请求失败: %@", error.localizedDescription);
             
             // 10. 错误处理
             dispatch_async(dispatch_get_main_queue(), ^{
                 // 更新UI显示错误信息
             });
         }];
}

// 示例2: 获取天气数据的AFNetworking实现  
- (void)exampleGetWeatherWithAFNetworking:(NSString *)adcode {
    // 1. 创建管理器
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    // 2. 构建URL
    NSString *urlString = [NSString stringWithFormat:@"https://restapi.amap.com/v3/weather/weatherInfo?city=%@&key=%@", adcode, self.apiKey];
    
    // 3. 发送请求
    [manager GET:urlString
      parameters:nil
         headers:nil  
        progress:nil
         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
             // 4. 解析天气数据
             WeatherData *weatherData = [self parseWeatherDataFromAFNetworking:responseObject];
             
             // 5. 更新UI (确保在主线程)
             dispatch_async(dispatch_get_main_queue(), ^{
                 if (weatherData) {
                     [self updateWeatherCard:weatherData];
                 } else {
                     // 处理解析失败
                     NSLog(@"天气数据解析失败");
                 }
                 [self hideLoading];  // 隐藏加载指示器
             });
         }
         failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
             // 6. 处理网络错误
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self handleNetworkError:error];
                 [self hideLoading];  // 确保隐藏加载指示器
             });
         }];
}

// 示例3: 带参数的POST请求
- (void)examplePostRequestWithAFNetworking {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    // 配置请求序列化器为JSON格式
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    // 请求参数
    NSDictionary *parameters = @{
        @"username": @"user123",
        @"password": @"pass123"
    };
    
    // 自定义请求头
    NSDictionary *headers = @{
        @"Authorization": @"Bearer your_token_here",
        @"Custom-Header": @"custom_value"
    };
    
    [manager POST:@"https://api.example.com/login"
       parameters:parameters
          headers:headers
         progress:nil
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
              NSLog(@"登录成功: %@", responseObject);
          }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
              NSLog(@"登录失败: %@", error.localizedDescription);
          }];
}
*/

/*
 * ==================== 实现任务清单 ====================
 * 
 * 请按照以上示例，完成以下方法的AFNetworking实现：
 * 
 * 1. getAdcodeForCity:completion: 方法
 *    - 使用AFHTTPSessionManager发送GET请求
 *    - 在success回调中提取districts和adcode
 *    - 在failure回调中调用completion(nil, error)
 * 
 * 2. fetchWeatherWithAdcode: 方法  
 *    - 使用AFHTTPSessionManager发送GET请求
 *    - 在success回调中调用parseWeatherDataFromAFNetworking
 *    - 确保UI更新在主线程，调用hideLoading
 * 
 * 3. parseWeatherDataFromAFNetworking: 方法
 *    - 检查responseObject类型和API状态码
 *    - 提取lives数组和天气数据
 *    - 返回WeatherData对象或nil
 * 
 * 【提示】
 * - 参考上面的示例代码结构
 * - 保持原有的错误处理逻辑
 * - 注意线程安全，UI操作使用dispatch_async
 * - 测试时注意观察网络请求日志
 * 
 * ================================================================
 */

@end
