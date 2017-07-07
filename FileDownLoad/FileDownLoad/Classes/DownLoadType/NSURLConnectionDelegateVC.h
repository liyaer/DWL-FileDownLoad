//
//  NSURLConnectionDelegateVC.h
//  FileDownLoad
//
//  Created by 杜文亮 on 17/7/4.
//  Copyright © 2017年 pro. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSURLConnectionDelegateVC : UIViewController

@property (strong, nonatomic) NSMutableData *mDataReceive;
@property (assign, nonatomic) NSUInteger totalDataLength;

@end
