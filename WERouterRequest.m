//
//  WERouterRequest.m
//  WekidsEducation
//
//  Created by CodingIran on 2019/2/26.
//  Copyright © 2019 wekids. All rights reserved.
//

#import "WERouterRequest.h"

@interface WERouterRequest ()

@property(nonatomic, copy, readwrite) NSString *requestPath;

@property(nullable, nonatomic, strong, readwrite) WERouterParameters parameters;

@end

@implementation WERouterRequest

- (instancetype)initWithPath:(NSString *)requestPath parameters:(nullable WERouterParameters)parameters
{
    if (self = [super init]) {
        self.parameters = parameters;
        self.verifySameController = NO;
        
//        while ([requestPath hasPrefix:@"/"]) requestPath = [requestPath substringFromIndex:1];
        self.requestPath = requestPath.copy ? : @"";
    }
    
    return self;
}

@end

@implementation WERouterRequest (WebView)

static char kAssociatedObjectKey_webUrl;
static char kAssociatedObjectKey_openInWebView;

- (void)setWebUrl:(NSString * _Nonnull)webUrl
{
    objc_setAssociatedObject(self, &kAssociatedObjectKey_webUrl, webUrl, OBJC_ASSOCIATION_COPY_NONATOMIC);
    if (webUrl && webUrl.length) {
        self.openInWebView = YES;
    }
}

- (NSString *)webUrl
{
    return objc_getAssociatedObject(self, &kAssociatedObjectKey_webUrl);
}

- (void)setOpenInWebView:(BOOL)openInWebView
{
    objc_setAssociatedObject(self, &kAssociatedObjectKey_openInWebView, @(openInWebView), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)openInWebView
{
    return [objc_getAssociatedObject(self, &kAssociatedObjectKey_openInWebView) boolValue];
}
- (NSString *)webUrlScheme
{
    return @"";
}

- (instancetype)initWithWebURL:(NSString *)webUrl isRelativePath:(BOOL)isRelativePath
{
    NSString *requestPath = webUrl.copy;
    if ([webUrl containsString:@"http:"]) {
        NSArray<NSString *> *stringList = [webUrl componentsSeparatedByString:@"http:"];
        if (stringList && stringList.count > 1) {
            requestPath = stringList[1];
        }
    }
    if (self = [self initWithPath:requestPath parameters:nil]) {
        self.verifySameController = NO;
        if (isRelativePath) {
            // 相对路径
//            self.webUrl = [WEWebUrlServerIP stringByAppendingPathComponent:requestPath];
            self.webUrl = [self.webUrlScheme stringByAppendingPathComponent:requestPath];
        } else {
            // 绝对路径
            self.webUrl = requestPath;
        }
    }
    
    return self;
}

- (instancetype)initWithWebURL:(NSString *)webUrl
{
    return [self initWithWebURL:webUrl isRelativePath:YES];
}

@end
