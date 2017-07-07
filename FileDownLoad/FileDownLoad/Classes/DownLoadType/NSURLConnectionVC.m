//
//  ViewController.m
//  FileDownLoad
//
//  Created by pro on 17/5/31.
//  Copyright © 2017年 pro. All rights reserved.
//

#import "NSURLConnectionVC.h"

/*
 *  类的扩展
 */

@interface NSURLConnectionVC ()

@end

/*
 *  类的实现
 */

@implementation NSURLConnectionVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor greenColor];
    
    
    NSString *fileURLStr = DownLoadURL;
    NSURL *fileURL = [NSURL URLWithString:fileURLStr];
    
    //创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fileURL];
        
    //创建连接；Apple 提供的处理一般请求的两种方法，他们不需要进行一系列的 NSURLConnectionDataDelegate 委托协议方法操作，简洁直观
    //方法一：发送一个同步请求；不建议使用，因为当前线程是主线程的话，会造成线程阻塞，一般比较少用
//        NSURLResponse *response;
//        NSError *connectionError;
//        NSData *data = [NSURLConnection sendSynchronousRequest:request
//                                             returningResponse:&response
//                                               error:&connectionError];
    
//        DLog(@"====同步执行，等下载完毕才会打印该句话====");

//        if (!connectionError) {
//            [self saveDataToDisk:data];
//            NSLog(@"保存成功");
//        } else {
//            NSLog(@"下载失败，错误信息：%@", connectionError.localizedDescription);
//        }
    
    //方法二：发送一个异步请求
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (!connectionError) {
                                   [self saveDataToDisk:data];
                                   NSLog(@"保存成功");
                                   
                               } else {
                                   NSLog(@"下载失败，错误信息：%@", connectionError.localizedDescription);
                               }
                           }];
    DLog(@"====是异步执行，会直接打印该句话====");

}


- (void)saveDataToDisk:(NSData *)data {
    //数据接收完保存文件；注意苹果官方要求：下载数据只能保存在缓存目录（/Library/Caches）
    NSString *savePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    savePath = [savePath stringByAppendingPathComponent:@"NSURLConnection-Font"];
    [data writeToFile:savePath atomically:YES]; //writeToFile: 方法：如果 savePath 文件存在，他会执行覆盖
    DLog(@"%@",savePath);
}






@end
