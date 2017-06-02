//
//  CommonFunction.m
//  plan
//
//  Created by Fengzy on 15/9/2.
//  Copyright (c) 2015年 Fengzy. All rights reserved.
//

#import "UIDevice+Util.h"
#import "CommonFunction.h"
#import <CommonCrypto/CommonDigest.h>
#import "LocalNotificationManager.h"

static NSString * const kKeyYears = @"years";
static NSString * const kKeyMonths = @"months";
static NSString * const kKeyDays = @"days";
static NSString * const kKeyHours = @"hours";
static NSString * const kKeyMinutes = @"minutes";

@implementation CommonFunction

//获取设备型号 iPhone4、iPhone6 Plus
+ (NSString *)getDeviceType {
    return [[UIDevice currentDevice] platformString];
}

//获取iOS系统版本号
+ (NSString *)getiOSVersion {
    return [[UIDevice currentDevice] systemVersion];
}

+ (NSString *)getAppVersion {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

//获取当前时间字符串：yyyy-MM-dd HH:mm:ss
+ (NSString *)getTimeNowString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:STRDateFormatterType1];
    NSString *timeNow = [dateFormatter stringFromDate:[NSDate date]];
    return timeNow;
}

+ (NSDateComponents *)getDateTime:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday |
    NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    
    if (date == nil) {
        date = [NSDate date];
    }
    NSDateComponents *comps = [calendar components:unitFlags fromDate:date];
    return comps;
}

//判断是否为空白字符串
+ (BOOL)isEmptyString:(NSString *)original {
    return original == nil || [original isEqualToString:@""];
}

//压缩图片
+ (NSData *)compressImage:(UIImage *)image {
    CGFloat compression = 0.9f;
    CGFloat maxCompression = 0.1f;
    int maxFileSize = 512*1024; //压缩到小于512KB
    NSData *imageData = UIImageJPEGRepresentation(image, compression);
    while ([imageData length]>maxFileSize && compression>maxCompression) {
        compression -= 0.1;
        imageData = UIImageJPEGRepresentation(image, compression);
    }
    return imageData;
}

//数组排序 yes升序排列，no,降序排列
+ (NSArray *)arraySort:(NSArray *)array ascending:(BOOL)ascending {
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:nil ascending:ascending];
    return [array sortedArrayUsingDescriptors:[NSArray arrayWithObjects:sd, nil]];

}

//NSString转换NSDate
+ (NSDate *)NSStringDateToNSDate:(NSString *)datetime formatter:(NSString *)format {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [formatter setDateFormat:format];
    NSDate *date = [formatter dateFromString:datetime];
    return date;
}

//NSDate转换NSString
+ (NSString *)NSDateToNSString:(NSDate *)datetime formatter:(NSString *)format {
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:format];
    NSString *dateStr = [formatter stringFromDate:datetime];
    return dateStr;
}

+ (BOOL)validateNumber:(NSString *)textString {
    NSString *number = @"^[0-9]+$";
    NSPredicate *numberPre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", number];
    return [numberPre evaluateWithObject:textString];
}

+ (BOOL)validateEmail:(NSString *)textString {
    NSString *email = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailPre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", email];
    return [emailPre evaluateWithObject:textString];
}

+ (BOOL)isSameDay:(NSDate*)date1 date2:(NSDate*)date2 {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
    NSDateComponents *comp1 = [calendar components:unitFlags fromDate:date1];
    NSDateComponents *comp2 = [calendar components:unitFlags fromDate:date2];
    return [comp1 day] == [comp2 day] &&
    [comp1 month] == [comp2 month] &&
    [comp1 year] == [comp2 year];
}

// MD5 32位加密
+ (NSString *)md5HexDigest:(NSString*)password {
    const char *original_str = [password UTF8String];
    unsigned char result[CC_MD5_BLOCK_BYTES];
    CC_MD5(original_str, (CC_LONG)strlen(original_str), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < CC_MD5_BLOCK_BYTES; i++) {
        // %02X是格式控制符：‘x’表示以16进制输出，‘02’表示不足两位，前面补0；
        [hash appendFormat:@"%02X", result[i]];
    }
    NSString *mdfiveString = [hash lowercaseString];
    return mdfiveString;
}

//超过仟的数字用K缩写
+ (NSString *)checkNumberForThousand:(NSInteger)number {
    if (number > 100000) {
        return [NSString stringWithFormat:@"%.1fW", (CGFloat)number / 10000];
    } else if (number > 1000) {
        return [NSString stringWithFormat:@"%.1fK", (CGFloat)number / 1000];
    } else {
        return [NSString stringWithFormat:@"%ld", (long)number];
    }
}

//时间间隔显示：刚刚，N分钟前，N天前...
+ (NSString *)intervalSinceNow:(NSDate *)date {
    NSDictionary *dic = [CommonFunction timeIntervalArrayFromString:date];
    NSInteger minutes = [[dic objectForKey:kKeyMinutes] integerValue];
    
    if (minutes < 1) {
        return STRCommonTime1;
    } else if (minutes < 60) {
        return [NSString stringWithFormat:STRCommonTime5, (long)minutes];
    } else if (minutes < 24 * 60) {
        return [NSString stringWithFormat:STRCommonTime6, (long)minutes / 60];
    } else if (minutes < 48 * 60) {
        return STRCommonTime3;
    } else if (minutes < 30 * 24 * 60) {
        return [NSString stringWithFormat:STRCommonTime7, (long)minutes / (60 * 24)];
    } else if (minutes < 60 * 24 * 60) {
        return STRCommonTime4;
    } else if (minutes < 12 * 30 * 24 * 60) {
        return [NSString stringWithFormat:STRCommonTime8, (long)minutes / (60 * 24 * 30)];
    } else {
        return [CommonFunction NSDateToNSString:date formatter:STRDateFormatterType1];
    }
}

+ (NSDictionary *)timeIntervalArrayFromString:(NSDate *)date {
    NSUInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *compsPast = [calendar components:unitFlags fromDate:date];
    NSDateComponents *compsNow = [calendar components:unitFlags fromDate:[NSDate date]];
    
    NSInteger years = [compsNow year] - [compsPast year];
    NSInteger months = [compsNow month] - [compsPast month] + years * 12;
    NSInteger days = [compsNow day] - [compsPast day] + months * 30;
    NSInteger hours = [compsNow hour] - [compsPast hour] + days * 24;
    NSInteger minutes = [compsNow minute] - [compsPast minute] + hours * 60;
    
    return @{
             kKeyYears:  @(years),
             kKeyMonths: @(months),
             kKeyDays:   @(days),
             kKeyHours:  @(hours),
             kKeyMinutes:@(minutes)
             };
}

//获取PNG图片的大小
+ (CGSize)getPNGImageSizeWithRequest:(NSMutableURLRequest*)request {
    [request setValue:@"bytes=16-23" forHTTPHeaderField:@"Range"];
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    if(data.length == 8)
    {
        int w1 = 0, w2 = 0, w3 = 0, w4 = 0;
        [data getBytes:&w1 range:NSMakeRange(0, 1)];
        [data getBytes:&w2 range:NSMakeRange(1, 1)];
        [data getBytes:&w3 range:NSMakeRange(2, 1)];
        [data getBytes:&w4 range:NSMakeRange(3, 1)];
        int w = (w1 << 24) + (w2 << 16) + (w3 << 8) + w4;
        int h1 = 0, h2 = 0, h3 = 0, h4 = 0;
        [data getBytes:&h1 range:NSMakeRange(4, 1)];
        [data getBytes:&h2 range:NSMakeRange(5, 1)];
        [data getBytes:&h3 range:NSMakeRange(6, 1)];
        [data getBytes:&h4 range:NSMakeRange(7, 1)];
        int h = (h1 << 24) + (h2 << 16) + (h3 << 8) + h4;
        return CGSizeMake(w, h);
    }
    return CGSizeZero;
}

//获取gif图片的大小
+ (CGSize)getGIFImageSizeWithRequest:(NSMutableURLRequest*)request {
    [request setValue:@"bytes=6-9" forHTTPHeaderField:@"Range"];
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    if(data.length == 4)
    {
        short w1 = 0, w2 = 0;
        [data getBytes:&w1 range:NSMakeRange(0, 1)];
        [data getBytes:&w2 range:NSMakeRange(1, 1)];
        short w = w1 + (w2 << 8);
        short h1 = 0, h2 = 0;
        [data getBytes:&h1 range:NSMakeRange(2, 1)];
        [data getBytes:&h2 range:NSMakeRange(3, 1)];
        short h = h1 + (h2 << 8);
        return CGSizeMake(w, h);
    }
    return CGSizeZero;
}

//获取jpg图片的大小
+ (CGSize)getJPGImageSizeWithRequest:(NSMutableURLRequest*)request {
    [request setValue:@"bytes=0-209" forHTTPHeaderField:@"Range"];
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    if ([data length] <= 0x58) {
        return CGSizeZero;
    }
    
    if ([data length] < 210) {// 肯定只有一个DQT字段
        short w1 = 0, w2 = 0;
        [data getBytes:&w1 range:NSMakeRange(0x60, 0x1)];
        [data getBytes:&w2 range:NSMakeRange(0x61, 0x1)];
        short w = (w1 << 8) + w2;
        short h1 = 0, h2 = 0;
        [data getBytes:&h1 range:NSMakeRange(0x5e, 0x1)];
        [data getBytes:&h2 range:NSMakeRange(0x5f, 0x1)];
        short h = (h1 << 8) + h2;
        return CGSizeMake(w, h);
    } else {
        short word = 0x0;
        [data getBytes:&word range:NSMakeRange(0x15, 0x1)];
        if (word == 0xdb) {
            [data getBytes:&word range:NSMakeRange(0x5a, 0x1)];
            if (word == 0xdb) {// 两个DQT字段
                short w1 = 0, w2 = 0;
                [data getBytes:&w1 range:NSMakeRange(0xa5, 0x1)];
                [data getBytes:&w2 range:NSMakeRange(0xa6, 0x1)];
                short w = (w1 << 8) + w2;
                short h1 = 0, h2 = 0;
                [data getBytes:&h1 range:NSMakeRange(0xa3, 0x1)];
                [data getBytes:&h2 range:NSMakeRange(0xa4, 0x1)];
                short h = (h1 << 8) + h2;
                return CGSizeMake(w, h);
            } else {// 一个DQT字段
                short w1 = 0, w2 = 0;
                [data getBytes:&w1 range:NSMakeRange(0x60, 0x1)];
                [data getBytes:&w2 range:NSMakeRange(0x61, 0x1)];
                short w = (w1 << 8) + w2;
                short h1 = 0, h2 = 0;
                [data getBytes:&h1 range:NSMakeRange(0x5e, 0x1)];
                [data getBytes:&h2 range:NSMakeRange(0x5f, 0x1)];
                short h = (h1 << 8) + h2;
                return CGSizeMake(w, h);
            }
        } else {
            return CGSizeZero;
        }
    }
}

//根据性别获取颜色
+ (UIColor *)getGenderColor {
    //昵称：男蓝女粉
    NSString *gender = [Config shareInstance].settings.gender;
    if (gender && [gender isEqualToString:@"0"]) {
        return color_Pink;
    } else {
        return color_Blue;
    }
}

//用户等级icon图标
+ (UIImage *)getUserLevelIcon:(NSString *)level {
    NSInteger levelCode = [level integerValue];
    switch (levelCode) {
        case 9:
            return [UIImage imageNamed:png_Icon_Icon_UserLevel_9];
            break;
        case 8:
            return [UIImage imageNamed:png_Icon_Icon_UserLevel_8];
            break;
        case 7:
            return [UIImage imageNamed:png_Icon_Icon_UserLevel_7];
            break;
        case 6:
            return [UIImage imageNamed:png_Icon_Icon_UserLevel_6];
            break;
        case 5:
            return [UIImage imageNamed:png_Icon_Icon_UserLevel_5];
            break;
        case 4:
            return [UIImage imageNamed:png_Icon_Icon_UserLevel_4];
            break;
        default:
            return nil;
            break;
    }
}

//计划开始时间显示格式：今天，明天，或日期
+ (NSString *)getBeginDateStringForShow:(NSString *)date {
    NSDate *today = [NSDate date];
    NSDate *tomorrow = [today dateByAddingTimeInterval:24 * 3600];
    NSString *todayString = [CommonFunction NSDateToNSString:today formatter:STRDateFormatterType4];
    NSString *tomorrowString = [CommonFunction NSDateToNSString:tomorrow formatter:STRDateFormatterType4];
    if ([date isEqualToString:todayString]) {
        return STRCommonTime2;
    } else if ([date isEqualToString:tomorrowString]) {
        return STRCommonTime9;
    } else {
        return date;
    }
}

//计划提醒时间显示格式：今天，明天，或日期
+ (NSString *)getNotifyTimeStringForShow:(NSString *)time {
    NSArray *timeSplitArray = [time componentsSeparatedByString:@" "];
    NSString *notifyDate = @"";
    NSString *notifyTime = @"";
    if (timeSplitArray.count == 2) {
        notifyDate = timeSplitArray[0];
        notifyTime = timeSplitArray[1];
    }
    NSDate *today = [NSDate date];
    NSDate *tomorrow = [today dateByAddingTimeInterval:24 * 3600];
    NSString *todayString = [CommonFunction NSDateToNSString:today formatter:STRDateFormatterType4];
    NSString *tomorrowString = [CommonFunction NSDateToNSString:tomorrow formatter:STRDateFormatterType4];
    if ([notifyDate isEqualToString:todayString]) {
        return [NSString stringWithFormat:@"%@ %@", STRCommonTime2, notifyTime];
    } else if ([notifyDate isEqualToString:tomorrowString]) {
        return [NSString stringWithFormat:@"%@ %@", STRCommonTime9, notifyTime];
    } else {
        return time;
    }
}

/** toDay格式：2016-03-18 */
+ (NSInteger)howManyDaysLeft:(NSString*)toDay {
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    [gregorian setFirstWeekday:2];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *fromDate;
    NSDate *toDate;
    [gregorian rangeOfUnit:NSCalendarUnitDay startDate:&fromDate interval:NULL forDate:[NSDate date]];
    [gregorian rangeOfUnit:NSCalendarUnitDay startDate:&toDate interval:NULL forDate:[dateFormatter dateFromString:toDay]];
    NSDateComponents *dayComponents = [gregorian components:NSCalendarUnitDay fromDate:fromDate toDate:toDate options:0];
    return dayComponents.day;
}

//将整型数字转换成带千分号的格式
+ (NSString *)integerToDecimalStyle:(NSInteger)integer {
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    return [formatter stringFromNumber:[NSNumber numberWithInteger:integer]];
}

/** 更新提醒时间，防止提醒时间早于当前时间导致的设置提醒无效 */
+ (NSString *)updateNotifyTime:(NSString *)notifyTime
{
    NSDate *oldNotifyTime = [CommonFunction NSStringDateToNSDate:notifyTime formatter:STRDateFormatterType3];
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    unsigned units  = NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitYear|NSCalendarUnitHour|NSCalendarUnitMinute;
    NSDateComponents *compOldNotifyTime = [calendar components:units fromDate:oldNotifyTime];
    NSDateComponents *compToday = [calendar components:units fromDate:[NSDate date]];
    compToday.hour = compOldNotifyTime.hour;
    compToday.minute = compOldNotifyTime.minute;
    
    NSDate *newNotifyTime = [calendar dateFromComponents:compToday];
    
    if ([newNotifyTime compare:[NSDate date]] == NSOrderedAscending) {
        //把提醒的时、分赋值到今天的日期下面，还是比当前时间小的话，就直接把提醒日期设为明天即可
        compToday.day += 1;
        newNotifyTime = [calendar dateFromComponents:compToday];
    }
    
    return [CommonFunction NSDateToNSString:newNotifyTime formatter:STRDateFormatterType3];
}

/** 获取随机数 */
+ (int)getRandomNumber:(int)from to:(int)to
{
    return (int)(from + (arc4random() % (to - from + 1)));
}

/** 更新本地通知 */
+ (void)updatePlanNotification:(Plan *)plan
{
    //首先取消该计划的本地所有通知
    [self cancelPlanNotification:plan.planid];
    //重新添加新的通知
    [self addPlanNotification:plan];
}

/** 取消本地通知 */
+ (void)cancelPlanNotification:(NSString*)planid
{
    //取消该计划的本地所有通知
    NSArray *array = [LocalNotificationManager getNotificationWithTag:planid type:NotificationTypePlan];
    for (UILocalNotification *item in array)
    {
        [LocalNotificationManager cancelNotification:item];
    }
}

/** 新增本地通知 */
+ (void)addPlanNotification:(Plan *)plan
{
    //时间格式：yyyy-MM-dd HH:mm
    NSDate *date = [CommonFunction NSStringDateToNSDate:plan.notifytime formatter:STRDateFormatterType3];
    
    if (!date) return;
    
    BmobUser *user = [BmobUser currentUser];
    NSMutableDictionary *destDic = [NSMutableDictionary dictionary];
    [destDic setObject:user.objectId forKey:@"account"];
    [destDic setObject:plan.planid forKey:@"tag"];
    [destDic setObject:@([date timeIntervalSince1970]) forKey:@"time"];
    [destDic setObject:@(NotificationTypePlan) forKey:@"type"];
    [destDic setObject:plan.beginDate forKey:@"beginDate"];
    [destDic setObject:plan.iscompleted forKey:@"iscompleted"];
    [destDic setObject:plan.completetime ?: @"" forKey:@"completetime"];
    [destDic setObject:plan.content forKey:@"content"];
    [destDic setObject:plan.notifytime forKey:@"notifytime"];
    [destDic setObject:plan.remark ?:@"" forKey:@"remark"];
    [destDic setObject:plan.isRepeat ?:@"0" forKey:@"isRepeat"];
    [LocalNotificationManager createLocalNotification:date userInfo:destDic alertBody:plan.content];
}


+ (NSInteger)calculateDayFromDate:(NSDate *)date1 toDate:(NSDate *)date2
{
    NSCalendar *userCalendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [userCalendar components:NSCalendarUnitDay fromDate:date1 toDate:date2 options:0];
    NSInteger days = [components day];
    return days;
}

@end
