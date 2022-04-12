//
//  WERouterRequest.h
//  WekidsEducation
//
//  Created by CodingIran on 2019/2/26.
//  Copyright © 2019 wekids. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 路由参数定义
typedef id WERouterParameters;

@interface WERouterRequest : NSObject

/// 是否校验从一个页面 push 到相同的页面，默认为 NO
@property(nonatomic, assign) BOOL verifySameController;

/// 请求地址
@property(nonatomic, copy, readonly) NSString *requestPath;

/// 请求参数
@property(nullable, nonatomic, strong, readonly) WERouterParameters parameters;

/// 初始化方法
- (instancetype)initWithPath:(NSString *)requestPath parameters:(nullable WERouterParameters)parameters NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new  NS_UNAVAILABLE;

@end

/**
 * 如果使用webview打开则使用此分类进行初始化
 */
@interface WERouterRequest (WebView)

@property(nonatomic, copy, readonly) NSString *webUrl;

/// 是否以webview打开，会校验webUrl的合法性
@property(nonatomic, assign, readonly) BOOL openInWebView;

/// initWithWebURL:isRelativePath: 拼接在前面的 url scheme
@property(nonatomic, copy, readonly) NSString *webUrlScheme;

/**
 使用webview 打开地址

 @param webUrl 需要打开的地址，默认为相对路径
 @return 实例对象
 */
- (instancetype)initWithWebURL:(NSString *)webUrl;

/**
 使用webview 打开地址

 @param webUrl 需要打开的地址，默认为相对路径
 @param isRelativePath 是否相对路径
 @return 实例对象
 */
- (instancetype)initWithWebURL:(NSString *)webUrl isRelativePath:(BOOL)isRelativePath;

@end

NS_ASSUME_NONNULL_END
