#import <Foundation/Foundation.h>




/*    [self updateWeatherCard:province
                       city:city
                    weather:weather
                temperature:temperature
              windDirection:windDirection
                  windPower:windPower
                   humidity:humidity
                 reportTime:reportTime];
                 */
NS_ASSUME_NONNULL_BEGIN
@interface WeatherData : NSObject

@property (nonatomic, strong) NSString *province;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *weather;
@property (nonatomic, strong) NSString *temperature;
@property (nonatomic, strong) NSString *windDirection;
@property (nonatomic, strong) NSString *windPower;
@property (nonatomic, strong) NSString *humidity;
@property (nonatomic, strong) NSString *reportTime;


// 指定初始化方法
- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary NS_DESIGNATED_INITIALIZER;

// 禁用init和new方法，防止外部直接调用
- (instancetype) init NS_UNAVAILABLE;
+ (instancetype) new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END