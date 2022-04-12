//
//  WERouter.h
//  WekidsEducation
//
//  Created by CodingIran on 2019/2/26.
//  Copyright © 2019 wekids. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WERouterRequest.h"
#import "ZJRouterStorage.h"

NS_ASSUME_NONNULL_BEGIN

/// 路由结果定义
typedef id WERouterResult;

/// 路由完成回调定义
typedef void (^WERouterCompletionHandler)(WERouterResult _Nullable WERouterResult, NSError * _Nullable error);

@protocol WERouterHandlerProtocol <NSObject>

@optional// 如果不实现方法则使用executingController(不指定则用visibleVc)进行push操作

/**
 处理路由请求

 @param routerRequest 传入的参数
 @param previousViewController 当前需要执行跳转操作的控制器
 @param completionHandler 完成回调
 */
+ (void)handleRouterRequest:(WERouterRequest *)routerRequest withPreviousController:(nullable __kindof UIViewController *)previousViewController completionHandler:(nullable WERouterCompletionHandler)completionHandler;

/**
 单路由地址
 */
+ (NSString *)routePath;

/**
 多路由地址
 */
+ (NSArray<NSString *> *)multiRoutePath;

/**
 创建类的实例
 */
+ (id<WERouterHandlerProtocol>)routerInstanceWithRouterRequest:(WERouterRequest *)routerRequest;

@end

/// webview特供
@protocol WEWebUrlRouterHandlerProtocol <WERouterHandlerProtocol>

@required

/**
 处理web请求

 @param routerRequest web请求
 @param previousViewController 上一个控制器，比如使用router从 A push 到 B，则A为previousViewController
 @param completionHandler 回程回调
 */
+ (void)handleWebUrlRouterRequest:(WERouterRequest *)routerRequest
           withPreviousController:(nullable __kindof UIViewController *)previousViewController
                completionHandler:(nullable WERouterCompletionHandler)completionHandler;

@end

@interface WERouter : NSObject

/**
 全局单例初始化方法

 @return 实例对象
 */
+ (instancetype)sharedRouter;

/**
 执行请求

 @param request 路由请求
 @param completionHandler 完成回调
 */
- (void)executeRequest:(WERouterRequest *)request completionHandler:(nullable WERouterCompletionHandler)completionHandler;

/**
 执行请求

 @param request 路由请求
 @param executingController 执行跳转的控制器，一般传self
 @param completionHandler 完成回调
 */
- (void)executeRequest:(WERouterRequest *)request withExecutingController:(__kindof UIViewController *)executingController completionHandler:(nullable WERouterCompletionHandler)completionHandler;

/**
 根据路由地址获取类名
 @param routerRequest 路由请求
 */
- (nullable NSString *)routerClassNameWithRouterRequest:(WERouterRequest *)routerRequest;
- (nullable NSString *)routerClassNameWithRouterPath:(NSString *)routerPath;

/**
 根据路由地址获取类的实例
 @param routerRequest 路由请求
 */
- (nullable id<WERouterHandlerProtocol>)routerClassInstanceWithRouterRequest:(WERouterRequest *)routerRequest;
- (nullable id<WERouterHandlerProtocol>)routerClassInstanceWithRouterPath:(NSString *)routerPath;

@end

NS_ASSUME_NONNULL_END
