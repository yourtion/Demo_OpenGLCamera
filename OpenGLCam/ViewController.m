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
    
    [dataOutput setSampleBufferDelegate:self queue:dispatch_queue_create("Video", DISPATCH_QUEUE_SERIAL)];
    
    
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
    
    
    
    [session startRunning];
}
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    NSDate *start = [NSDate date];
    connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    CIFilter *crystallize = [CIFilter filterWithName:@"CIPhotoEffectChrome" keysAndValues:kCIInputImageKey, image, nil];
    [crystallize setValue:image forKey:kCIInputImageKey];
    [_glView bindDrawable];
    [_ciContext drawImage:crystallize.outputImage inRect:image.extent fromRect:image.extent];
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
