//
//  AppsFlyerX+AppController.m
//  Created by Jonathan Wesfield on 26/12/2018.
//

#import <Foundation/Foundation.h>
#import "AppsFlyerX+AppController.h"
#import <objc/runtime.h>
#import "AppsFlyerAttribution.h"

@implementation AppDelegate (AppsFlyerX)
#ifndef AFSDK_DISABLE_APP_DELEGATE

#pragma mark - original method exist flags for swizzling
static BOOL isOriginalContinueUserActivityExist;
static BOOL isOriginalOpenURLExist;
static BOOL isOriginalOpenURLOptionsExist;

#if AFSDK_SHOULD_SWIZZLE
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        [self enableSwizzling];

    });
}

#else
#pragma mark - AppDelegate Deep Link implementetion
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options{
    [self afLogger:@"AF openURL:options"];
    [[AppsFlyerAttribution shared] handleOpenUrl:url options:options];
    return YES;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler{
    [self afLogger:@"AF continueUserActivity"];
    [[AppsFlyerAttribution shared] continueUserActivity:userActivity restorationHandler:restorationHandler];
    return YES;
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    [self afLogger:@"AF openURL:sourceApplication:annotation"];
    [[AppsFlyerAttribution shared] handleOpenUrl:url sourceApplication:sourceApplication annotation:annotation];
    return YES;
}
#endif

#pragma mark - Method Swizzling - Deep Link implementetion
- (BOOL)af_application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler {
    [self afLogger:@"Swizzled continueUserActivity"];
    [[AppsFlyerAttribution shared] continueUserActivity:userActivity restorationHandler:restorationHandler];
    if (isOriginalContinueUserActivityExist) {
        [self af_application:application continueUserActivity:userActivity restorationHandler:restorationHandler];
    }
    return YES;
}
-(BOOL)af_application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    [self afLogger:@"Swizzled openURL:sourceApplication:annotation"];
    [[AppsFlyerAttribution shared] handleOpenUrl:url sourceApplication:sourceApplication annotation:annotation];
    if (isOriginalOpenURLExist) {
        [self af_application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
    }
    return YES;
}

- (BOOL)af_application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options{
    [self afLogger:@"Swizzled openURL:options"];
    [[AppsFlyerAttribution shared] handleOpenUrl:url options:options];
    if (isOriginalOpenURLOptionsExist) {
        [self af_application:app openURL:url options:options];
    }
    return YES;
}

#pragma  mark - add swizzled methods
+(void)addSwizzledMethod:(SEL _Nonnull )originalSelector swizzledSelector:(SEL _Nonnull)swizzledSelector methodExistFlag:(BOOL*_Nonnull)methodExistFlag{
    Class class = [self class];
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    *methodExistFlag = [class instancesRespondToSelector:originalSelector];
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));

    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

+(void)enableSwizzling{
    SEL originalSelector = @selector(application: continueUserActivity: restorationHandler:);
    SEL swizzledSelector = @selector(af_application: continueUserActivity: restorationHandler:);
    [self addSwizzledMethod:originalSelector swizzledSelector:swizzledSelector methodExistFlag:&isOriginalContinueUserActivityExist];

    SEL originalSelector2 = @selector(application: openURL: sourceApplication: annotation:);
    SEL swizzledSelector2 = @selector(af_application: openURL: sourceApplication: annotation:);
    [self addSwizzledMethod:originalSelector2 swizzledSelector:swizzledSelector2 methodExistFlag:&isOriginalOpenURLExist];


    SEL originalSelector3 = @selector(application: openURL: options:);
    SEL swizzledSelector3 = @selector(af_application: openURL: options: );
    [self addSwizzledMethod:originalSelector3 swizzledSelector:swizzledSelector3 methodExistFlag:&isOriginalOpenURLOptionsExist];
}

#pragma mark - logger
-(void)afLogger:(NSString*)log {
    if([AppsFlyerLib shared].isDebug)
        NSLog(@"[DEBUG] AppsFlyer: %@" , log);
}


#endif
@end

