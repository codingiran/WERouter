//
//  WERouter.m
//  WekidsEducation
//
//  Created by CodingIran on 2019/2/26.
//  Copyright © 2019 wekids. All rights reserved.
//

#import "WERouter.h"

static NSString * const kNullRouterPrompt = @"功能未开放";

@interface WERouter ()

/// 所有实现`WERouterHandlerProtocol`协议的类名，key为routePath
@property(nonnull, nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *handlers;

@end

@implementation WERouter

#pragma mark - life cycle

/// 完整的ARC单例
ZJSingletonM(WERouter, sharedRouter)

- (instancetype)init
{
    if (self = [super init]) {
        // 初始化
        self.handlers = [NSMutableDictionary dictionary];
        
        unsigned int img_count = 0;
        // 全部Objective-C 框架 以及动态库名称（包含系统框架）
        const char **imgs = objc_copyImageNames(&img_count);
        // 我们自己写的类和引入的库的路径名称
        const char *main = NSBundle.mainBundle.bundlePath.UTF8String;
        Protocol *protocol = @protocol(WERouterHandlerProtocol);// 路由协议
        Protocol *web_protocol = @protocol(WEWebUrlRouterHandlerProtocol);// web路由协议
        SEL sel_path = @selector(routePath);// 单路由selector
        SEL sel_multiPath = @selector(multiRoutePath);// 多路由selector
        SEL sel_web_selector = @selector(handleWebUrlRouterRequest:withPreviousController:completionHandler:);// web协议方法selector
        // 第一层循环拿到所有库的名称
        for (unsigned int i = 0 ; i < img_count ; i++) {
            const char *img = imgs[i];
            // 过滤掉系统的image
            if (!strstr(img, main)) continue;// strstr(str1,str2)判断str2是否为str1的子串
            unsigned int cls_count = 0;
            // 获取自己写的类以及引入库中的类的名称
            const char **classeNames = objc_copyClassNamesForImage(img, &cls_count);
            // 第二次循环拿到每个库中类的名称
            for (unsigned int i = 0; i < cls_count; i++) {
                const char *cls_name = classeNames[i];
                Class _Nullable cls = objc_getClass(cls_name);
                // class不存在
                if (!cls) continue;
                // 没有实现协议（校验父类）
                if (!we_class_conformsToProtocol(cls, protocol)) continue;
                // 判断是否实现类方法
                Class metaCls = object_getClass(cls);//获取元类(类方法保存在元类)
                if (class_respondsToSelector(metaCls, sel_path)) {// 单路由地址
                    IMP funcIMP = class_getMethodImplementation(metaCls, sel_path);
                    NSString * (*pathSelectorIMP)(id, SEL);
                    pathSelectorIMP = (NSString * (*)(id, SEL))funcIMP;
                    NSString *routePath = pathSelectorIMP(cls, sel_path);
                    if (routePath.length) {
                        self->_handlers[routePath] = [NSString stringWithUTF8String:cls_name];
                    }
                } else if (class_respondsToSelector(metaCls, sel_multiPath)) {// 多路由地址
                    IMP funcIMP = class_getMethodImplementation(metaCls, sel_multiPath);
                    NSArray<NSString *> *(*multiPathSelectorIMP)(id, SEL);
                    multiPathSelectorIMP = (NSArray<NSString *> * (*)(id, SEL))funcIMP;
                    NSArray<NSString *> *miltiRoutePath = multiPathSelectorIMP(cls, sel_multiPath);
                    for (NSString *routePath in miltiRoutePath) {
                        if (routePath.length) {
                            self->_handlers[routePath] = [NSString stringWithUTF8String:cls_name];
                        }
                    }
                }
                // web协议不去校验父类是否遵循协议，目的是为了直接拿到 WEBaseWebViewController
                if (class_conformsToProtocol(cls, web_protocol) && class_respondsToSelector(metaCls, sel_web_selector)) {
                    self->_handlers[@"WKWebView"] = [NSString stringWithUTF8String:cls_name];
                }
            }
            if (classeNames) free(classeNames);
        }
        if (imgs) free(imgs);
    }
    return self;
}

#pragma mark - public method

- (void)executeRequest:(WERouterRequest *)request completionHandler:(nullable WERouterCompletionHandler)completionHandler
{
    [self executeRequest:request withExecutingController:[QMUIHelper visibleViewController] completionHandler:completionHandler];
}

- (void)executeRequest:(WERouterRequest *)request withExecutingController:(__kindof UIViewController *)executingController completionHandler:(nullable WERouterCompletionHandler)completionHandler
{
    NSError *error = nil;
    if (!request) {
        if (completionHandler) {
            error = [NSError customErrorWithDescription:@"无效的路由"];
            completionHandler(nil, error);
        }
        return;
    }
    if (!self->_handlers.count) {
        if (completionHandler) {
            error = [NSError customErrorWithDescription:@"路由组件异常"];
            completionHandler(nil, error);
        }
        return;
    }
    
    if (self->_handlers[request.requestPath]) {
        NSString *clsName = self->_handlers[request.requestPath];
        Class<WERouterHandlerProtocol> handlerCls = NSClassFromString(clsName);
        if (handlerCls && [handlerCls respondsToSelector:@selector(handleRouterRequest:withPreviousController:completionHandler:)]) {
            // 实现了`handleRouterRequest:withPreviousController:completionHandler:`方法
            [handlerCls handleRouterRequest:request withPreviousController:executingController completionHandler:completionHandler];
            if (completionHandler) {
                completionHandler(nil, nil);
            }
        } else {
            // 不实现`handleRouterRequest:withPreviousController:completionHandler:`则使用默认的跳转方式
            id<WERouterHandlerProtocol> routerClassInstance = [self routerClassInstanceWithRouterRequest:request];
            if (!routerClassInstance || ![routerClassInstance isKindOfClass:UIViewController.class] || !executingController) {
                if (completionHandler) {
                    error = [NSError customErrorWithDescription:@"跳转失败"];
                    completionHandler(nil, error);
                }
                return;
            }
            __kindof UIViewController *viewController = (__kindof UIViewController *)routerClassInstance;
            if (request.verifySameController && [NSStringFromClass(handlerCls) isEqualToString:NSStringFromClass(executingController.class)]) {
                if (completionHandler) {
                    error = [NSError customErrorWithDescription:@"已设置不能跳往相同的页面"];
                    completionHandler(nil, error);
                }
                return;
            }
            if ([executingController isKindOfClass:[UINavigationController class]]) {
                __kindof UINavigationController *navigationController = (__kindof UINavigationController *)executingController;
                [navigationController pushViewController:viewController animated:YES];
                if (completionHandler) {
                    completionHandler(nil, nil);
                }
            } else {
                if (executingController.navigationController) {
                    [executingController.navigationController pushViewController:viewController animated:YES];
                    if (completionHandler) {
                        completionHandler(nil, nil);
                    }
                } else {
                    if (completionHandler) {
                        error = [NSError customErrorWithDescription:@"执行跳转的控制器既不是也没有导航栏控制器"];
                        completionHandler(nil, error);
                    }
                    ZJLog(@"WERouter Warning: 执行跳转的控制器既不是也没有导航栏控制器");
                }
            }
        }
    } else {
        // 找不到对应的原生页面，尝试使用webview打开
        if ([self->_handlers objectForKey:@"WKWebView"] && request.openInWebView) {
            NSString *clsName = self->_handlers[@"WKWebView"];
            Class<WEWebUrlRouterHandlerProtocol> handlerCls = NSClassFromString(clsName);
            // WEWebUrlRouterHandlerProtocol协议的方法是@required
            if (handlerCls && [handlerCls respondsToSelector:@selector(handleWebUrlRouterRequest:withPreviousController:completionHandler:)]) {
                [handlerCls handleWebUrlRouterRequest:request withPreviousController:executingController completionHandler:completionHandler];
            }
            if (completionHandler) {
                completionHandler(nil, nil);
            }
        } else {
            if (completionHandler) {
                error = [NSError customErrorWithDescription:kNullRouterPrompt];
                completionHandler(nil, error);
            }
        }
    }
}

- (nullable NSString *)routerClassNameWithRouterPath:(NSString *)routerPath
{
    if (!routerPath || !routerPath.length) return nil;
    NSString *routerClassName = [self.handlers safeStringForKey:routerPath];
    return routerClassName;
}

- (nullable NSString *)routerClassNameWithRouterRequest:(WERouterRequest *)routerRequest
{
    if (!routerRequest || !routerRequest.requestPath) return nil;
    NSString *routerPath = routerRequest.requestPath;
    return [self routerClassNameWithRouterPath:routerPath];
}

- (nullable id<WERouterHandlerProtocol>)routerClassInstanceWithRouterRequest:(WERouterRequest *)routerRequest
{
    NSString *routerClassName = [self routerClassNameWithRouterRequest:routerRequest];
    if (!routerClassName) return nil;
    Class routerClass = NSClassFromString(routerClassName);
    if (!routerClass) return nil;
    Class metaClass = object_getClass(routerClass);//获取元类(类方法保存在元类)
    SEL sel_routerInstance = @selector(routerInstanceWithRouterRequest:);// 创建实例的方法
    id<WERouterHandlerProtocol> routerInstance = nil;
    if (!class_respondsToSelector(metaClass, sel_routerInstance)) {
        // 没有实现 routerInstanceWithRouterRequest:，则直接使用 class new 一个实例
        routerInstance = [[(id)routerClass alloc] init];
        return routerInstance;
    }
    IMP funcIMP = class_getMethodImplementation(metaClass, sel_routerInstance);
    id<WERouterHandlerProtocol> (*instanceSelectorIMP)(id, SEL, WERouterRequest *);
    instanceSelectorIMP = (id<WERouterHandlerProtocol> (*)(id, SEL, WERouterRequest *))funcIMP;
    routerInstance = instanceSelectorIMP(routerClass, sel_routerInstance, routerRequest);
    return routerInstance;
}

- (nullable id<WERouterHandlerProtocol>)routerClassInstanceWithRouterPath:(NSString *)routerPath
{
    return [self routerClassInstanceWithRouterRequest:[[WERouterRequest alloc] initWithPath:routerPath parameters:nil]];
}

#pragma mark - private mehod
/**
 runtime 的 class_conformsToProtocol 函数只校验本类是否遵循协议，we_class_conformsToProtocol 会校验其父类
 @discussion 不使用 Foudation 层的 conformsToProtocol 是为了不触发该类的 Initialize 方法
 @param cls  需要校验的类
 @param prot 需要校验的协议
 @return cls 是否遵循prot
 */
CG_INLINE BOOL
we_class_conformsToProtocol(Class cls, Protocol *prot)
{
    if (!cls) return NO;
    if (!prot) return NO;
    
    Class superCls;
    for (superCls = cls; superCls; superCls = class_getSuperclass(superCls)) {
        if (class_conformsToProtocol(superCls, prot)) return YES;
    }
    return NO;
}

@end
