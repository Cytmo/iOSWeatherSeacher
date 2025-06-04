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
        _province = [self safeStringFromValue:dictionary[@"province"] defaultValue:@"未知省份"];
        _city = [self safeStringFromValue:dictionary[@"city"] defaultValue:@"未知城市"];
        _weather = [self safeStringFromValue:dictionary[@"weather"] defaultValue:@"未知天气"];
        _temperature = [self safeStringFromValue:dictionary[@"temperature"] defaultValue:@"未知温度"];
        _windDirection = [self safeStringFromValue:dictionary[@"winddirection"] defaultValue:@"未知风向"];
        _windPower = [self safeStringFromValue:dictionary[@"windpower"] defaultValue:@"未知风力"];
        _humidity = [self safeStringFromValue:dictionary[@"humidity"] defaultValue:@"未知湿度"];
        _reportTime = [self safeStringFromValue:dictionary[@"reporttime"] defaultValue:@"未知时间"];
    }
    return self;
}

- (NSString *)safeStringFromValue:(id)value defaultValue:(NSString *)defaultValue {
    if ([value isKindOfClass:[NSString class]]) {
        NSString *stringValue = (NSString *)value;
        return stringValue.length > 0 ? [stringValue copy] : defaultValue;
    } else if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value stringValue];
    }
    return defaultValue;
}

@end
