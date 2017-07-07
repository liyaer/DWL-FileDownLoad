//
//  AFNetWorkingVC.m
//  FileDownLoad
//
//  Created by 杜文亮 on 17/7/4.
//  Copyright © 2017年 pro. All rights reserved.
//

#import "AFNetWorkingVC.h"

@interface AFNetWorkingVC ()

@property (nonatomic,strong) UILabel *lblMessage;

- (void)showAlert:(NSString *)msg;
- (void)checkNetwork;
- (void)layoutUI;
- (NSMutableURLRequest *)downloadRequest;
- (NSURL *)saveURL:(NSURLResponse *)response deleteExistFile:(BOOL)deleteExistFile;
- (void)updateProgress:(int64_t)receiveDataLength totalDataLength:(int64_t)totalDataLength;

@end

@implementation AFNetWorkingVC

-(UILabel *)lblMessage
{
    if (!_lblMessage)
    {
        _lblMessage = [[UILabel alloc] initWithFrame:CGRectMake(100, 200, 150, 30)];
    }
    return _lblMessage;
}

- (void)showAlert:(NSString *)msg
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"网络情况"
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"确定", nil];
    [alert show];
}

- (void)checkNetwork
{
    NSURL *baseURL = [NSURL URLWithString:@"http://www.baidu.com/"];
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
    
    NSOperationQueue *operationQueue = manager.operationQueue;
    [manager.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWiFi:
                [self showAlert:@"Wi-Fi 网络下"];
                [operationQueue setSuspended:NO];
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                [self showAlert:@"2G/3G/4G 蜂窝移动网络下"];
                [operationQueue setSuspended:YES];
                break;
            case AFNetworkReachabilityStatusNotReachable:
            default:
                [self showAlert:@"未连接网络"];
                [operationQueue setSuspended:YES];
                break;
        }
    }];
    
    [manager.reachabilityManager startMonitoring];
}

- (void)layoutUI
{
    self.view.backgroundColor = [UIColor brownColor];
    
    [self.view addSubview:self.lblMessage];
    
    //进度效果
    _hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    _hud.mode = 1;
    _hud.backgroundView.style = 0;
    _hud.backgroundView.color = [UIColor colorWithWhite:0.0f alpha:0.2f];
    _hud.label.text = @"下载中...";
//    [_hud hideAnimated:YES];
    
    //检查网络情况
    [self checkNetwork];
    
    //启动网络活动指示器；会根据网络交互情况，实时显示或隐藏网络活动指示器；他通过「通知与消息机制」来实现 [UIApplication sharedApplication].networkActivityIndicatorVisible 的控制
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
}

- (NSMutableURLRequest *)downloadRequest
{
    NSString *fileURLStr = DownLoadURL;
    //编码操作；对应的解码操作是用 stringByRemovingPercentEncoding 方法
    fileURLStr = [fileURLStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *fileURL = [NSURL URLWithString:fileURLStr];
    
    //创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fileURL];
    return request;
}

- (NSURL *)saveURL:(NSURLResponse *)response deleteExistFile:(BOOL)deleteExistFile
{
    NSString *fileName = response ? [response suggestedFilename] : @"AFNetWorking-Font";
    
    //方法一
    //    NSString *savePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    //    savePath = [savePath stringByAppendingPathComponent:fileName];
    //    NSURL *saveURL = [NSURL fileURLWithPath:savePath];
    
    //方法二
    NSURL *saveURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    saveURL = [saveURL URLByAppendingPathComponent:fileName];
    NSString *savePath = [saveURL path];
    
    if (deleteExistFile) {
        NSError *saveError;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        //判断是否存在旧的目标文件，如果存在就先移除；避免无法复制问题
        if ([fileManager fileExistsAtPath:savePath]) {
            [fileManager removeItemAtPath:savePath error:&saveError];
            if (saveError) {
                NSLog(@"移除旧的目标文件失败，错误信息：%@", saveError.localizedDescription);
            }
        }
    }
    
    return saveURL;
}

- (void)updateProgress:(int64_t)receiveDataLength totalDataLength:(int64_t)totalDataLength
{
    dispatch_async(dispatch_get_main_queue(), ^{ //使用主队列异步方式（主线程）执行更新 UI 操作
        
        _hud.progress = (float)receiveDataLength / totalDataLength;
        
        if (receiveDataLength == totalDataLength) {
            _lblMessage.text =  receiveDataLength < 0 ? @"下载失败" : @"下载完成";
            //kApplication.networkActivityIndicatorVisible = NO;
            [_hud hideAnimated:YES];
        } else {
            _lblMessage.text = @"下载中...";
            //kApplication.networkActivityIndicatorVisible = YES;
            [_hud showAnimated:YES];
        }
    });
}







- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self layoutUI];
    
//    [self startDownLoadByConnction];
    
    [self startDownLoadBySession];
}




-(void)startDownLoadByConnction
{
    //创建请求
    NSMutableURLRequest *request = [self downloadRequest];
    
    //创建请求操作
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    NSString *savePath = [[self saveURL:nil deleteExistFile:NO] path];
    
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        NSLog(@"已经接收到响应数据，数据长度为%lld字节...", totalBytesRead);
        
        [self updateProgress:totalBytesRead totalDataLength:totalBytesExpectedToRead];
    }];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"已经接收完所有响应数据");
        
        NSData *data = (NSData *)responseObject;
        [data writeToFile:savePath atomically:YES]; //responseObject 的对象类型是 NSData
        
        [self updateProgress:100 totalDataLength:100];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"下载失败，错误信息：%@", error.localizedDescription);
        
        [self updateProgress:-1 totalDataLength:-1];
    }];
    
    //启动请求操作
    [operation start];
}

-(void)startDownLoadBySession
{
    //创建请求
    NSMutableURLRequest *request = [self downloadRequest];
    
    //创建会话配置「进程内会话」
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = 60.0; //请求超时时间；默认为60秒
    sessionConfiguration.allowsCellularAccess = YES; //是否允许蜂窝网络访问（2G/3G/4G）
    sessionConfiguration.HTTPMaximumConnectionsPerHost = 4; //限制每次最多连接数；在 iOS 中默认值为4
    
    //创建会话管理器
    AFURLSessionManager *sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:sessionConfiguration];
    
    //创建会话下载任务，并且启动他；在非主线程中执行
    NSURLSessionDownloadTask *task = [sessionManager
                                      downloadTaskWithRequest:request
                                      progress:nil
                                      destination:^ NSURL*(NSURL *targetPath, NSURLResponse *response) {
                                          //当 sessionManager 调用 setDownloadTaskDidFinishDownloadingBlock: 方法，并且方法代码块返回值不为 nil 时（优先级高），下面的两句代码是不执行的（优先级低）
                                          NSLog(@"下载后的临时保存路径：%@", targetPath);
                                          return [self saveURL:response deleteExistFile:YES];
                                      } completionHandler:^ (NSURLResponse *response, NSURL *filePath, NSError *error) {
                                          if (!error) {
                                              NSLog(@"下载后的保存路径：%@", filePath); //为上面代码块返回的路径
                                              
                                              [self updateProgress:100 totalDataLength:100];
                                          } else {
                                              NSLog(@"下载失败，错误信息：%@", error.localizedDescription);
                                              
                                              [self updateProgress:-1 totalDataLength:-1];
                                          }
                                    }];
    
    //类似 NSURLSessionDownloadDelegate 的方法操作
    //- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;
    [sessionManager setDownloadTaskDidWriteDataBlock:^ (NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite)
    {
        NSLog(@"已经接收到响应数据，数据长度为%lld字节...", totalBytesWritten);
        
        [self updateProgress:totalBytesWritten totalDataLength:totalBytesExpectedToWrite];
    }];
    
    //- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location;
    [sessionManager setDownloadTaskDidFinishDownloadingBlock:^ NSURL*(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location)
    {
        NSLog(@"已经接收完所有响应数据，下载后的临时保存路径：%@", location);
        return [self saveURL:nil deleteExistFile:YES];
    }];
    
    [task resume];
}







- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
