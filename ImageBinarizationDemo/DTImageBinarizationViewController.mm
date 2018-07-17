//
//  DTImageBinarizationViewController.m
//  alishuju
//
//  Created by 谭真 on 2018/7/16.
//  Copyright © 2018 Alibaba. All rights reserved.
//

#import "DTImageBinarizationViewController.h"
// 如果遇到'opencv2/opencv.hpp' file not found，请先将项目中的opencv2.framework.zip解压并拖入项目中。为了避免github的文件最大100M限制...
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc/types_c.h>
#import <opencv2/imgcodecs/ios.h>
#import "TZImagePickerController.h"

@interface DTImageBinarizationViewController ()
@property (strong, nonatomic) UIButton *selectButton;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UITextField *textFiled;
@property (strong, nonatomic) UIButton *processButton;
@property (strong, nonatomic) UIImageView *resultImageView;
@end

@implementation DTImageBinarizationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat rgb = 246 / 255.0;
    self.view.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:1.0];
    
    _selectButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_selectButton setTitle:@"选择图片" forState:UIControlStateNormal];
    [_selectButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [_selectButton addTarget:self action:@selector(selectButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_selectButton];
    
    _imageView = [UIImageView new];
    UIImage *image = [UIImage imageNamed:@"testImage"];
    _imageView.image = image;
    _imageView.clipsToBounds = YES;
    _imageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectButtonClick)];
    [_imageView addGestureRecognizer:tap];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:_imageView];
    
    _textFiled = [[UITextField alloc] init];
    _textFiled.text = @"阈值:235";
    _textFiled.backgroundColor = [UIColor whiteColor];
    _textFiled.placeholder = @"输入阈值（1~254之间）";
    _textFiled.font = [UIFont systemFontOfSize:15];
    _textFiled.textColor = [UIColor blackColor];
    [self.view addSubview:_textFiled];
    
    _processButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_processButton setTitle:@"重新二值化" forState:UIControlStateNormal];
    [_processButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_processButton addTarget:self action:@selector(processButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_processButton setBackgroundColor:[UIColor orangeColor]];
    [self.view addSubview:_processButton];
    
    _resultImageView = [UIImageView new];
    _resultImageView.clipsToBounds = YES;
    _resultImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *resultImageViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resultImageClick)];
    [_resultImageView addGestureRecognizer:resultImageViewTap];
    _resultImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:_resultImageView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.imageView.image) {
        [self processButtonClick];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat imageViewWH = 150;
    _imageView.frame = CGRectMake((self.view.frame.size.width - imageViewWH) / 2, 30, imageViewWH, imageViewWH);
    _selectButton.frame = CGRectMake((self.view.frame.size.width - 100) / 2, imageViewWH / 2, 100, 44);
    CGFloat textFiledWidth = (self.view.frame.size.width - 45) / 2;
    _textFiled.frame = CGRectMake(15, CGRectGetMaxY(_imageView.frame) + 12, textFiledWidth, 44);
    _processButton.frame = CGRectMake(CGRectGetMaxX(_textFiled.frame) + 15, CGRectGetMaxY(_imageView.frame) + 12, textFiledWidth, 44);
    _resultImageView.frame = CGRectMake(15, CGRectGetMaxY(_processButton.frame) + 12, self.view.frame.size.width - 30, self.view.frame.size.height - CGRectGetMaxY(_processButton.frame) - 24);
}

#pragma mark - Click

- (void)selectButtonClick {
    TZImagePickerController *imagePicker = [[TZImagePickerController alloc] initWithMaxImagesCount:1 delegate:nil];
    imagePicker.allowPickingVideo = NO;
    imagePicker.allowPickingGif = NO;
    imagePicker.allowPickingOriginalPhoto = NO;
    imagePicker.iconThemeColor = [UIColor orangeColor];
    imagePicker.navigationBar.barTintColor = [UIColor orangeColor];
    [imagePicker setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
        if (photos.count) {
            self.imageView.image = [photos firstObject];
            [self processButtonClick];
        }
    }];
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)resultImageClick {
    // 查看大图...
}

- (void)processButtonClick {
    [self.textFiled endEditing:YES];
    self.resultImageView.image = [self getBinarizationImage:self.imageView.image];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.textFiled endEditing:YES];
}

#pragma mark - Private

/// 图片二值化
- (UIImage *)getBinarizationImage:(UIImage *)soucreImage {
    cv::Mat matImage = [self cvMatFromUIImage:soucreImage];
    cv::Mat matGrey;
    cv::cvtColor(matImage, matGrey, CV_BGR2GRAY);
    int threshold = [[self.textFiled.text stringByReplacingOccurrencesOfString:@"阈值:" withString:@""] intValue];
    cv::Mat matBinary;
    cv::threshold(matGrey, matBinary, threshold, 255, cv::THRESH_BINARY);
    UIImage *image = [self UIImageFromCVMat:matBinary];
    return image;
}

// UIImage to cvMat
- (cv::Mat)cvMatFromUIImage:(UIImage *)image {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    if (contextRef == NULL) {
        return cvMat;
    }
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    return cvMat;
}

// CvMat to UIImage
- (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat {
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 // width
                                        cvMat.rows,                                 // height
                                        8,                                          // bits per component
                                        8 * cvMat.elemSize(),                       // bits per pixel
                                        cvMat.step[0],                              // bytesPerRow
                                        colorSpace,                                 // colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   // CGDataProviderRef
                                        NULL,                                       // decode
                                        false,                                      // should interpolate
                                        kCGRenderingIntentDefault                   // intent
                                        );
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return finalImage;
}

@end
