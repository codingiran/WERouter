# WERouter
一个简单的 URL 路由跳转方案


### 使用方法

#### 实现协议&注册URL

```objc
@interface UserInfoViewController : UIViewController<WERouterHandlerProtocol>

...

@implementation

#pragma mark - WERouterHandlerProtocol

+ (NSString *)routePath
{
    return @"/mine/userInfo/";
}

```


#### 创建请求&执行跳转

```objc

// 传参，支持任何 NSObject 对象
WERouterParameters parameters = /*any object*/;
// 创建请求
WERouterRequest *request = [[WERouterRequest alloc] initWithPath:@"/mine/userInfo/" parameters:parameters];
// 执行路由跳转
[WERouter.sharedRouter executeRequest:request withExecutingController:self completionHandler:^(WERouterResult  _Nullable WERouterResult, NSError * _Nullable error) {
     if (error) {
        // 处理错误
     } else {
        // 成功回调
     }
}];

```

#### 一个页面注册多个 URL

```objc

#pragma mark - WERouterHandlerProtocol

+ (NSArray<NSString *> *)multiRoutePath
{
    return @[
        @"/mine/userInfo/edit",
        @"/mine/userInfo/show"
        ...
    ];
}

```

#### 拦截路由请求

```objc

+ (void)handleRouterRequest:(WERouterRequest *)routerRequest withPreviousController:(__kindof UIViewController *)previousViewController completionHandler:(WERouterCompletionHandler)completionHandler
{
    NSString *URL = routerRequest.requestPath;
    WERouterParameters parameters = routerRequest.parameters;
    ...
    [previousViewController showDetailViewController:... sender:nil];
}

```

#### 自定义跳转页面的初始化

```objc

+ (id<WERouterHandlerProtocol>)routerInstanceWithRouterRequest:(WERouterRequest *)routerRequest
{
    // 默认使用 [[Class alloc] init]，如果需要自定义初始化
    if ([routerRequest.requestPath isEqualToString:@"/mine/userInfo/edit"]) {
        return [[UserInfoViewController alloc] initWithType:UserInfoTypeEdit];
    }
    else if ([routerRequest.requestPath isEqualToString:@"/mine/userInfo/show"]) {
        return [[UserInfoViewController alloc] initWithType:UserInfoTypeShow];
    }
    return nil;
}

```

