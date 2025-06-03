#import "WeatherData.h"

@implementation WeatherData

- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary{
    /*            adcode = 411300;
            city = "\U5357\U9633\U5e02";
            humidity = 45;
            "humidity_float" = "45.0";
            province = "\U6cb3\U5357";
            reporttime = "2025-06-03 10:30:09";
            temperature = 27;
            "temperature_float" = "27.0";
            weather = "\U9634";
            winddirection = "\U4e1c";
            windpower = "\U22643";
        */
    self = [super init];

    if(!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]){
        return nil;
    }
    if(self){
        _province = [dictionary[@"province"] isKindOfClass:[NSString class]] ? [dictionary[@"province"] copy]: @"未知省份";
        _city = [dictionary[@"city"] isKindOfClass:[NSString class]] ? [dictionary[@"city"] copy]: @"未知城市";
        _weather = [dictionary[@"weather"] isKindOfClass:[NSString class]] ? [dictionary[@"weather"] copy]: @"未知天气";
        _temperature = [dictionary[@"temperature"] isKindOfClass:[NSString class]] ? [dictionary[@"temperature"] copy]: @"未知温度";
        _windDirection = [dictionary[@"winddirection"] isKindOfClass:[NSString class]] ? [dictionary[@"winddirection"] copy]: @"未知风向";
        _windPower = [dictionary[@"windpower"] isKindOfClass:[NSString class]] ? [dictionary[@"windpower"] copy]: @"未知风力";
        _humidity = [dictionary[@"humidity"] isKindOfClass:[NSString class]] ? [dictionary[@"humidity"] copy]: @"未知湿度";
        _reportTime = [dictionary[@"reporttime"] isKindOfClass:[NSString class]] ? [dictionary[@"reporttime"] copy]: @"未知时间";
    }
    return self;
}

@end
