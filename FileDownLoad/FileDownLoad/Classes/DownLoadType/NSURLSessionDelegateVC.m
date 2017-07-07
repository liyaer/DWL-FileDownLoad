//
//  NSURLSessionDelegateVC.m
//  FileDownLoad
//
//  Created by pro on 17/6/2.
//  Copyright © 2017年 pro. All rights reserved.
//

#import "NSURLSessionDelegateVC.h"

/*
 *  类的扩展
 */

@interface NSURLSessionDelegateVC ()<NSURLSessionDelegate>

@property (nonatomic,strong) NSArray *btnTitles;
@property (nonatomic,strong) UILabel *mesLab;
@property (nonatomic,strong) UIProgressView *progVDownloadFile;
@property (nonatomic,strong) NSURLSessionDownloadTask *downloadTask;

- (NSURLSession *)defaultSession;
- (NSURLSession *)backgroundSession;
- (void)updateProgress:(int64_t)receiveDataLength totalDataLength:(int64_t)totalDataLength;

@end

/*
 *  类的实现
 */

@implementation NSURLSessionDelegateVC

#pragma mark - 实现类的扩展中声明的方法

-(NSArray *)btnTitles
{
    if (!_btnTitles)
    {
        _btnTitles = @[@"暂停",@"继续",@"取消"];
    }
    return _btnTitles;
}

-(UILabel *)mesLab
{
    if (!_mesLab)
    {
        _mesLab = [[UILabel alloc] initWithFrame:CGRectMake(100, 200, 150, 50)];
        _mesLab.font = [UIFont boldSystemFontOfSize:20.0];
        _mesLab.text = @"👌😂👌";
    }
    return _mesLab;
}

-(UIProgressView *)progVDownloadFile
{
    if (!_progVDownloadFile)
    {
        _progVDownloadFile = [[UIProgressView alloc] initWithFrame:CGRectMake(100, 300, 150, 50)];
        _progVDownloadFile.backgroundColor = [UIColor whiteColor];
    }
    return _progVDownloadFile;
}

- (NSURLSession *)defaultSession {
    /*
     NSURLSession 支持进程三种会话：
     1、defaultSessionConfiguration：进程内会话（默认会话），用硬盘来缓存数据。
     2、ephemeralSessionConfiguration：临时的进程内会话（内存），不会将 cookie、缓存储存到本地，只会放到内存中，当应用程序退出后数据也会消失。
     3、backgroundSessionConfiguration：后台会话，相比默认会话，该会话会在后台开启一个线程进行网络数据处理。
     */
    
    //创建会话配置「进程内会话」
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = 60.0; //请求超时时间；默认为60秒
    sessionConfiguration.allowsCellularAccess = YES; //是否允许蜂窝网络访问（2G/3G/4G）
    sessionConfiguration.HTTPMaximumConnectionsPerHost = 4; //限制每次最多连接数；在 iOS 中默认值为4
    
    //创建会话
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                          delegate:self
                                                     delegateQueue:nil];
    return session;
}

- (NSURLSession *)backgroundSession {
    static NSURLSession *session;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ //应用程序生命周期内，只执行一次；保证只有一个「后台会话」
        //创建会话配置「后台会话」
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"KMDownloadFile.NSURLSessionDelegateViewController"];
        sessionConfiguration.timeoutIntervalForRequest = 60.0; //请求超时时间；默认为60秒
        sessionConfiguration.allowsCellularAccess = YES; //是否允许蜂窝网络访问（2G/3G/4G）
        sessionConfiguration.HTTPMaximumConnectionsPerHost = 4; //限制每次最多连接数；在 iOS 中默认值为4
        sessionConfiguration.discretionary = YES; //是否自动选择最佳网络访问，仅对「后台会话」有效
        
        //创建会话
        session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                delegate:self
                                           delegateQueue:nil];
    });
    return session;
}

- (void)updateProgress:(int64_t)receiveDataLength totalDataLength:(int64_t)totalDataLength
{
    dispatch_async(dispatch_get_main_queue(), ^{ //使用主队列异步方式（主线程）执行更新 UI 操作
        if (receiveDataLength == totalDataLength) {
            self.mesLab.text = @"下载完成";
//            kApplication.networkActivityIndicatorVisible = NO;
            self.progVDownloadFile.progress = 1.0;
        } else {
//            self.mesLab.text = @"下载中...";
//            kApplication.networkActivityIndicatorVisible = YES;
            self.progVDownloadFile.progress = (float)receiveDataLength / totalDataLength;
            self.mesLab.text = [NSString stringWithFormat:@"%.2f%%",self.progVDownloadFile.progress * 100];
        }
    });
}





#pragma mark - viewDidLoad 初始化

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setUI];
    
    //开始下载任务
    [self setNSURLSession];

}

-(void)setUI
{
    self.view.backgroundColor = [UIColor purpleColor];
    
    [self.view addSubview:self.mesLab];
    [self.view addSubview:self.progVDownloadFile];
    
    for (int i = 0; i < 3; i++)
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        [btn setFrame:CGRectMake(20 + i * (60+20), 100, 60, 30)];
        btn.tag = i;
        [btn setTitle:self.btnTitles[i] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
}
-(void)btnClicked:(UIButton *)sender
{
    switch (sender.tag) {
        case 0:
        {
            [self.downloadTask suspend];
        }
            break;
        case 1:
        {
            [self.downloadTask resume];
        }
            break;
        case 2:
        {
            [self.downloadTask cancel];
        }
            break;
            
        default:
            break;
    }
}

-(void)setNSURLSession
{
    //构造URL
    NSString *fileURLStr = DownLoadURL;
    NSURL *fileURL = [NSURL URLWithString:fileURLStr];
    
    //创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fileURL];
    
    //创建会话「进程内会话」；如要用「后台会话」就使用自定义的[self backgroundSession] 方法
    NSURLSession *session = [self defaultSession];
    
    //创建下载任务，并且启动他；在非主线程中执行
    _downloadTask = [session downloadTaskWithRequest:request];
//    [_downloadTask resume];
    
    /*
     会话任务状态
     typedef NS_ENUM(NSInteger, NSURLSessionTaskState) {
     NSURLSessionTaskStateRunning = 0, //正在执行
     NSURLSessionTaskStateSuspended = 1, //已挂起
     NSURLSessionTaskStateCanceling = 2, //正在取消
     NSURLSessionTaskStateCompleted = 3, //已完成
     } NS_ENUM_AVAILABLE(NSURLSESSION_AVAILABLE, 7_0);
     */
}






#pragma mark - NSURLSession  Download  Delegate

//下载过程中一直在调用，显示已下载了多少
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
        
    NSLog(@"已经接收到响应数据，数据长度为%lld字节...", totalBytesWritten);
    
    [self updateProgress:totalBytesWritten totalDataLength:totalBytesExpectedToWrite];
}

//下载结束后对文件的处理
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    //下载文件会临时保存，正常流程下系统最终会自动清除此临时文件；保存路径目录根据会话类型而有所不同：
    //「进程内会话（默认会话）」和「临时的进程内会话（内存）」，路径目录为：/tmp，可以通过 NSTemporaryDirectory() 方法获取
    //「后台会话」，路径目录为：/Library/Caches/com.apple.nsurlsessiond/Downloads/com.kenmu.KMDownloadFile
    NSLog(@"已经接收完所有响应数据，下载后的临时保存路径：%@", location);
    
    __block void (^updateUI)(); //声明用于主线程更新 UI 的代码块
    
    NSString *savePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    savePath = [savePath stringByAppendingPathComponent:@"NSURLSessionDelegate-Font"];
    NSURL *saveURL = [NSURL fileURLWithPath:savePath];
    NSError *saveError;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //判断是否存在旧的目标文件，如果存在就先移除；避免无法复制问题
    if ([fileManager fileExistsAtPath:savePath]) {
        [fileManager removeItemAtPath:savePath error:&saveError];
        if (saveError) {
            NSLog(@"移除旧的目标文件失败，错误信息：%@", saveError.localizedDescription);
            
            updateUI = ^ {
                self.mesLab.text = @"下载失败";
            };
        }
    }
    if (!saveError) {
        //把源文件复制到目标文件，当目标文件存在时，会抛出一个错误到 error 参数指向的对象实例
        //方法一（path 不能有 file:// 前缀）
        //                [fileManager copyItemAtPath:[location path]
        //                                     toPath:savePath
        //                                      error:&saveError];
        
        //方法二
        [fileManager copyItemAtURL:location
                             toURL:saveURL
                             error:&saveError];
        
        if (!saveError) {
            NSLog(@"保存成功");
            
            updateUI = ^ {
                self.mesLab.text = @"下载完成";
            };
        } else {
            NSLog(@"保存失败，错误信息：%@", saveError.localizedDescription);
            
            updateUI = ^ {
                self.mesLab.text = @"下载失败";
            };
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), updateUI); //使用主队列异步方式（主线程）执行更新 UI 的代码块
}

//下载结束时调用
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    NSLog(@"无论下载成功还是失败，最终都会执行一次");
    
    if (error) {
        NSString *desc = error.localizedDescription;
        NSLog(@"下载失败，错误信息：%@", desc);
        
        dispatch_async(dispatch_get_main_queue(), ^{ //使用主队列异步方式（主线程）执行更新 UI 操作
            self.mesLab.text = [desc isEqualToString:@"cancelled"] ? @"下载已取消" : @"下载失败";
//            kApplication.networkActivityIndicatorVisible = NO;
            _progVDownloadFile.progress = 0.0;
        });
    }
}

@end
