//
//  ViewController.m
//  OpenGLCam
//
//  Created by YourtionGuo on 1/28/16.
//  Copyright © 2016 Yourtion. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <GLKit/GLKit.h>

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic , strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer ;
@property (nonatomic) int time;
@property (nonatomic , strong) dispatch_queue_t sessionQueue;
@end

@implementation ViewController{
    GLKView* _glView;
    EAGLContext* _glContext;
    CIContext* _ciContext;
    AVCaptureSession *session ;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    _ciContext = [CIContext contextWithEAGLContext:_glContext];
    _glView = [[GLKView alloc] initWithFrame:self.view.frame context:_glContext];
    _glView.context = _glContext;

    if (![EAGLContext setCurrentContext:_glContext]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
    [self.view addSubview:_glView];
    session = [[AVCaptureSession alloc] init];
    
    session.sessionPreset = AVCaptureSessionPreset640x480;
    
    AVCaptureDevice *deviceFront ;
    
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        if ([device hasMediaType:AVMediaTypeVideo]) {
            
            if ([device position] == AVCaptureDevicePositionFront) {
                deviceFront = device;
            }
        }
    }
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:deviceFront error:&error];
    if (!input) {
        // Handle the error appropriately.
        NSLog(@"ERROR: trying to open camera: %@", error);
    }
    AVCaptureVideoDataOutput * dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [dataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [dataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    self.sessionQueue = dispatch_queue_create("Video", DISPATCH_QUEUE_SERIAL);
    [dataOutput setSampleBufferDelegate:self queue:self.sessionQueue];
    
    
    if ([session canAddInput:input]) {
        [session addInput:input];
    }
    if ([session canAddOutput:dataOutput]) {
        [session addOutput:dataOutput];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
    
    dispatch_async(self.sessionQueue, ^{
    [session startRunning];
    });
}
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    NSDate *start = [NSDate date];
    connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    connection.videoMirrored = YES;
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    CIFilter *filter = [CIFilter filterWithName:@"CIPhotoEffectChrome" keysAndValues:kCIInputImageKey, image, nil];
    
//    NSDictionary *options = [NSDictionary dictionaryWithObject:@"NO" forKey:kCIImageAutoAdjustRedEye];
//    NSArray *adjustments = [image autoAdjustmentFiltersWithOptions:options];
//    
//    for (CIFilter *filter in adjustments) {
//        [filter setValue:image forKey:kCIInputImageKey];
//        image = filter.outputImage;
//    }
 
    [filter setValue:image forKey:kCIInputImageKey];
    [_glView bindDrawable];
    CGFloat width = _glView.drawableHeight/640.f*480.f;
    CGFloat height = _glView.drawableHeight;
    CGFloat x = (_glView.drawableWidth - width) /2;
    
    
    [_ciContext drawImage:filter.outputImage inRect:CGRectMake(x, 0, width, height) fromRect:CGRectMake(0, 0, 480, 640)];
    [_glView display];
//    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
//    uint8_t *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
//
//    
//    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    self.time = -[start timeIntervalSinceNow]*1000;
    NSLog(@"time : %d",self.time);
}

@end
