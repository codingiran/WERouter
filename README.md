# WERouter
一个简单的 URL 路由跳转方案


### 使用方法

#### 实现协议&注册URL

```objc
@interface WEUserInfoViewController : UIViewController<WERouterHandlerProtocol>

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

WERouterParameters parameters = /*any object*/;
WERouterRequest *request = [[WERouterRequest alloc] initWithPath:@"/mine/userInfo/" parameters:parameters];
[WERouter.sharedRouter executeRequest:request withExecutingController:self completionHandler:^(WERouterResult  _Nullable WERouterResult, NSError * _Nullable error) {
     // call back   
}];

```

