//
//  AlivcPushConfigViewController.m
//  AlivcLiveCaptureDev
//
//  Created by lyz on 2017/9/20.
//  Copyright © 2017年 Alivc. All rights reserved.
//

#import "AlivcLivePushConfigViewController.h"
#import "AlivcParamTableViewCell.h"
#import "AlivcParamModel.h"
#import "AlivcWatermarkSettingView.h"
#import "AlivcLivePusherViewController.h"
#import "AlivcQRCodeViewController.h"

#import <AlivcLivePusher/AlivcLivePusherHeader.h>

@interface AlivcLivePushConfigViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITextField *publisherURLTextField;
@property (nonatomic, strong) UIButton *QRCodeButton;
@property (nonatomic, strong) UIButton *urlCopyButton;
@property (nonatomic, strong) UITableView *paramTableView;
@property (nonatomic, strong) UIButton *publisherButton;
@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, strong) AlivcWatermarkSettingView *waterSettingView;

@property (nonatomic, assign) BOOL isUseAsync; // 是否使用异步接口
@property (nonatomic, assign) BOOL isUseWatermark; // 是否使用水印
@property (nonatomic, copy) NSString *authDuration; // 测试鉴权，过期时长
@property (nonatomic, copy) NSString *authKey; // 测试鉴权，账号key


@property (nonatomic, strong) AlivcLivePushConfig *pushConfig;

@property (nonatomic, assign) BOOL isUserMainStream;
@property (nonatomic, assign) BOOL isUserMixStream;

@property (nonatomic, assign) BOOL isKeyboardShow;
@property (nonatomic, assign) CGRect tableViewFrame;

@property (nonatomic, strong) UILabel *infoLabel;


@end

@implementation AlivcLivePushConfigViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupParamData];
    [self setupSubviews];
    [self addKeyboardNoti];
    [self setupInfoLabel];
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#define KIsiPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)


#pragma mark - UI
- (void)setupSubviews {
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = NSLocalizedString(@"pusher_setting", nil);
    
    CGFloat retractX = 10;
    CGFloat viewWidth = AlivcScreenWidth - retractX * 2;
    
    self.publisherURLTextField = [[UITextField alloc] init];
    
    if(KIsiPhoneX) {
        self.publisherURLTextField.frame = CGRectMake(retractX, 100, viewWidth - 100, AlivcSizeHeight(40));
    }else {
        self.publisherURLTextField.frame = CGRectMake(retractX, 70, viewWidth - 100, AlivcSizeHeight(40));
    }
    
    self.publisherURLTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.publisherURLTextField.placeholder = NSLocalizedString(@"input_tips", nil);
    self.publisherURLTextField.font = [UIFont systemFontOfSize:14.f];
    self.publisherURLTextField.clearsOnBeginEditing = NO;
    self.publisherURLTextField.clearButtonMode = UITextFieldViewModeAlways;
    self.publisherURLTextField.text = AlivcTextPushURL;
    
    UILabel *noticeLabel = [[UILabel alloc] init];
    noticeLabel.frame = CGRectMake(retractX,
                                   CGRectGetMaxY(self.publisherURLTextField.frame) + 2,
                                   CGRectGetWidth(self.view.frame),
                                   AlivcSizeHeight(25));
    noticeLabel.textAlignment = NSTextAlignmentLeft;
    noticeLabel.font = [UIFont systemFontOfSize:12.f];
    noticeLabel.textColor = AlivcRGB(175, 175, 175);
    noticeLabel.numberOfLines = 0;
    noticeLabel.text = NSLocalizedString(@"push_url_notice_text", nil);
    
    self.QRCodeButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    self.QRCodeButton.frame = CGRectMake(CGRectGetMaxX(self.publisherURLTextField.frame),
                                         CGRectGetMinY(self.publisherURLTextField.frame),
                                         95,
                                         CGRectGetHeight(self.publisherURLTextField.frame));
    [self.QRCodeButton setImage:[UIImage imageNamed:@"QR"] forState:(UIControlStateNormal)];
    self.QRCodeButton.layer.masksToBounds = YES;
    self.QRCodeButton.layer.cornerRadius = 10;
    [self.QRCodeButton addTarget:self action:@selector(QRCodeButtonAction:) forControlEvents:(UIControlEventTouchUpInside)];
    
    self.urlCopyButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    self.urlCopyButton.frame = CGRectMake(CGRectGetMaxX(self.publisherURLTextField.frame)+40,
                                         CGRectGetMinY(self.publisherURLTextField.frame),
                                         95,
                                         CGRectGetHeight(self.publisherURLTextField.frame));
    [self.urlCopyButton setImage:[UIImage imageNamed:@"copy"] forState:(UIControlStateNormal)];
    self.urlCopyButton.layer.masksToBounds = YES;
    self.urlCopyButton.layer.cornerRadius = 10;
    [self.urlCopyButton addTarget:self action:@selector(urlCopyButtonAction:) forControlEvents:(UIControlEventTouchUpInside)];
    
    
    
    
    
    self.publisherButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    self.publisherButton.frame = CGRectMake(0, 0, 150, 50);
    self.publisherButton.center = CGPointMake(AlivcScreenWidth / 2, AlivcScreenHeight - 40);
    self.publisherButton.backgroundColor = [UIColor blueColor];
    [self.publisherButton setTitle:NSLocalizedString(@"start_button", nil) forState:(UIControlStateNormal)];
    self.publisherButton.layer.masksToBounds = YES;
    self.publisherButton.layer.cornerRadius = 10;
    [self.publisherButton addTarget:self action:@selector(publiherButtonAction:) forControlEvents:(UIControlEventTouchUpInside)];
    
    self.paramTableView = [[UITableView alloc] init];
    self.paramTableView.frame = CGRectMake(retractX,
                                           CGRectGetMaxY(noticeLabel.frame) + 5,
                                           viewWidth,
                                           CGRectGetMinY(self.publisherButton.frame) - CGRectGetMaxY(noticeLabel.frame) - 10);
    self.paramTableView.delegate = (id)self;
    self.paramTableView.dataSource = (id)self;
    self.paramTableView.separatorStyle = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.paramTableView reloadData];
        [self updateBitrateAndFPSCell];
    });

    
    self.waterSettingView = [[AlivcWatermarkSettingView alloc] initWithFrame:(CGRectMake(0, AlivcScreenHeight - AlivcSizeHeight(330), AlivcScreenWidth, AlivcSizeHeight(330)))];
    
    [self.view addSubview:self.publisherURLTextField];
    [self.view addSubview:noticeLabel];
    [self.view addSubview:self.QRCodeButton];
    [self.view addSubview:self.urlCopyButton];
    [self.view addSubview:self.publisherButton];
    [self.view addSubview:self.paramTableView];
    self.isKeyboardShow = false;
    self.tableViewFrame = self.paramTableView.frame;
    
}



#pragma mark - Data
- (void)setupParamData {
    self.isUseWatermark = YES;
    self.isUseAsync = YES;
    
    self.pushConfig = [[AlivcLivePushConfig alloc] init];
    
    AlivcParamModel *resolutionModel = [[AlivcParamModel alloc] init];
    resolutionModel.title = NSLocalizedString(@"resolution_label", nil);
    resolutionModel.placeHolder = @"540P";
    resolutionModel.infoText = @"540P";
    resolutionModel.defaultValue = 4.0/6.0;
    resolutionModel.reuseId = AlivcParamModelReuseCellSlider;
    resolutionModel.sliderBlock = ^(int value){
        self.pushConfig.resolution = value;
        [self updateBitrateAndFPSCell];
    };
    
    AlivcParamModel *targetBitrateModel = [[AlivcParamModel alloc] init];
    targetBitrateModel.title = NSLocalizedString(@"target_bitrate", nil);
    targetBitrateModel.placeHolder = @"800";
    targetBitrateModel.infoText = @"Kbps";
    targetBitrateModel.reuseId = AlivcParamModelReuseCellInput;
    targetBitrateModel.valueBlock = ^(int value) {
        self.pushConfig.targetVideoBitrate = value;
    };
    
    AlivcParamModel *minBitrateModel = [[AlivcParamModel alloc] init];
    minBitrateModel.title = NSLocalizedString(@"min_bitrate", nil);
    minBitrateModel.placeHolder = @"200";
    minBitrateModel.infoText = @"Kbps";
    minBitrateModel.reuseId = AlivcParamModelReuseCellInput;
    minBitrateModel.valueBlock = ^(int value) {
        self.pushConfig.minVideoBitrate = value;
    };
    
    AlivcParamModel *initBitrateModel = [[AlivcParamModel alloc] init];
    initBitrateModel.title = NSLocalizedString(@"initial_bitrate", nil);
    initBitrateModel.placeHolder = @"800";
    initBitrateModel.infoText = @"Kbps";
    initBitrateModel.reuseId = AlivcParamModelReuseCellInput;
    initBitrateModel.valueBlock = ^(int value) {
        self.pushConfig.initialVideoBitrate = value;
    };
    
    AlivcParamModel *audioBitrateModel = [[AlivcParamModel alloc] init];
    audioBitrateModel.title = NSLocalizedString(@"audio_bitrate", nil);
    audioBitrateModel.placeHolder = @"64";
    audioBitrateModel.infoText = @"Kbps";
    audioBitrateModel.reuseId = AlivcParamModelReuseCellInput;
    audioBitrateModel.valueBlock = ^(int value) {
        self.pushConfig.audioBitrate = value;
    };
    
    AlivcParamModel *audioSampelModel = [[AlivcParamModel alloc] init];
    audioSampelModel.title = NSLocalizedString(@"audio_sampling_rate", nil);
    audioSampelModel.placeHolder = @"32kHz";
    audioSampelModel.infoText = @"32kHz";
    audioSampelModel.defaultValue = 1.0/2.0;
    audioSampelModel.reuseId = AlivcParamModelReuseCellSlider;
    audioSampelModel.sliderBlock = ^(int value) {
        self.pushConfig.audioSampleRate = value;
    };
    
    AlivcParamModel *fpsModel = [[AlivcParamModel alloc] init];
    fpsModel.title = NSLocalizedString(@"captrue_fps", nil);
    fpsModel.segmentTitleArray = @[@"8",@"10",@"12",@"15",@"20",@"25",@"30"];
    fpsModel.defaultValue = 4;
    fpsModel.reuseId = AlivcParamModelReuseCellSegment;
    fpsModel.segmentBlock = ^(int value) {
        self.pushConfig.fps = value;
    };
    
    AlivcParamModel *minFPSModel = [[AlivcParamModel alloc] init];
    minFPSModel.title = NSLocalizedString(@"min_fps", nil);
    minFPSModel.segmentTitleArray = @[@"8",@"10",@"12",@"15",@"20",@"25",@"30"];
    minFPSModel.defaultValue = 0;
    minFPSModel.reuseId = AlivcParamModelReuseCellSegment;
    minFPSModel.segmentBlock = ^(int value) {
        self.pushConfig.minFps = value;
    };
    
    AlivcParamModel *gopModel = [[AlivcParamModel alloc] init];
    gopModel.title = NSLocalizedString(@"keyframe_interval", nil);
    gopModel.segmentTitleArray = @[@"1s",@"2s",@"3s",@"4s",@"5s"];
    gopModel.defaultValue = 1.0;
    gopModel.reuseId = AlivcParamModelReuseCellSegment;
    gopModel.segmentBlock = ^(int value) {
        self.pushConfig.videoEncodeGop = value;
    };
    
    AlivcParamModel *reconnectDurationModel = [[AlivcParamModel alloc] init];
    reconnectDurationModel.title = NSLocalizedString(@"reconnect_duration", nil);
    reconnectDurationModel.placeHolder = @"1000";
    reconnectDurationModel.infoText = @"ms";
    reconnectDurationModel.reuseId = AlivcParamModelReuseCellInput;
    reconnectDurationModel.valueBlock = ^(int value) {
        self.pushConfig.connectRetryInterval = value;
    };
    
    AlivcParamModel *reconnectTimeModel = [[AlivcParamModel alloc] init];
    reconnectTimeModel.title = NSLocalizedString(@"reconnect_times", nil);
    reconnectTimeModel.placeHolder = @"5";
    reconnectTimeModel.infoText = @"次";
    reconnectTimeModel.reuseId = AlivcParamModelReuseCellInput;
    reconnectTimeModel.valueBlock = ^(int value) {
        self.pushConfig.connectRetryCount = value;
    };
    
    AlivcParamModel *orientationModel = [[AlivcParamModel alloc] init];
    orientationModel.title = NSLocalizedString(@"landscape_model", nil);
    orientationModel.segmentTitleArray = @[@"Portrait",@"HomeLeft",@"HomeRight"];
    orientationModel.defaultValue = 0;
    orientationModel.reuseId = AlivcParamModelReuseCellSegment;
    orientationModel.segmentBlock = ^(int value) {
        self.pushConfig.orientation = value;
        
        if(self.pushConfig.pauseImg) {
            if(self.pushConfig.orientation == AlivcLivePushOrientationPortrait) {
                self.pushConfig.pauseImg = [UIImage imageNamed:@"background_push.png"];
            } else{
                self.pushConfig.pauseImg = [UIImage imageNamed:@"background_push_land.png"];
            }
        }
        
        if(self.pushConfig.networkPoorImg) {
            if(self.pushConfig.orientation == AlivcLivePushOrientationPortrait) {
                self.pushConfig.networkPoorImg = [UIImage imageNamed:@"poor_network.png"];
            } else{
                self.pushConfig.networkPoorImg = [UIImage imageNamed:@"poor_network_land.png"];
            }
        }

    };
    
    AlivcParamModel *audioChannelModel = [[AlivcParamModel alloc] init];
    audioChannelModel.title = NSLocalizedString(@"sound_track", nil);
    audioChannelModel.segmentTitleArray = @[NSLocalizedString(@"single_track", nil),NSLocalizedString(@"dual_track", nil)];
    audioChannelModel.defaultValue = 1.0;
    audioChannelModel.reuseId = AlivcParamModelReuseCellSegment;
    audioChannelModel.segmentBlock = ^(int value) {
        self.pushConfig.audioChannel = value;
    };
    
    AlivcParamModel *audioProfileModel = [[AlivcParamModel alloc] init];
    audioProfileModel.title = NSLocalizedString(@"audio_profile", nil);
    audioProfileModel.segmentTitleArray = @[@"AAC_LC",@"HE_AAC",@"HEAAC_V2",@"AAC_LD"];
    audioProfileModel.defaultValue = 0;
    audioProfileModel.reuseId = AlivcParamModelReuseCellSegment;
    audioProfileModel.segmentBlock = ^(int value) {
        self.pushConfig.audioEncoderProfile = value;
    };
    
    AlivcParamModel *mirrorModel = [[AlivcParamModel alloc] init];
    mirrorModel.title = NSLocalizedString(@"push_mirror", nil);
    mirrorModel.defaultValue = 0;
    mirrorModel.titleAppose = NSLocalizedString(@"preview_mirror", nil);
    mirrorModel.defaultValueAppose = 0;
    mirrorModel.reuseId = AlivcParamModelReuseCellSwitch;
    mirrorModel.switchBlock = ^(int index, BOOL open) {
        if (index == 0) {
            self.pushConfig.pushMirror = open?true:false;
        } else {
            self.pushConfig.previewMirror = open?true:false;
        }
    };
    
    
    AlivcParamModel *audiOnly_encodeModeModel = [[AlivcParamModel alloc] init];
    audiOnly_encodeModeModel.title = NSLocalizedString(@"audio_only_push_streaming", nil);
    audiOnly_encodeModeModel.defaultValue = 0;
    audiOnly_encodeModeModel.titleAppose = NSLocalizedString(@"video_hardware_encode", nil);
    audiOnly_encodeModeModel.defaultValueAppose = 1.0;
    audiOnly_encodeModeModel.reuseId = AlivcParamModelReuseCellSwitch;
    audiOnly_encodeModeModel.switchBlock = ^(int index, BOOL open) {
        if (index == 0) {
            self.pushConfig.audioOnly = open?true:false;
        } else {
            self.pushConfig.videoEncoderMode = open?AlivcLivePushVideoEncoderModeHard:AlivcLivePushVideoEncoderModeSoft;
        }
    };
    
    AlivcParamModel *autoFocus_FlashModel = [[AlivcParamModel alloc] init];
    autoFocus_FlashModel.title = NSLocalizedString(@"auto_focus", nil);
    autoFocus_FlashModel.defaultValue = 1.0;
    autoFocus_FlashModel.titleAppose = NSLocalizedString(@"flash", nil);
    autoFocus_FlashModel.defaultValueAppose = 0;
    autoFocus_FlashModel.reuseId = AlivcParamModelReuseCellSwitch;
    autoFocus_FlashModel.switchBlock = ^(int index, BOOL open) {
        if (index == 0) {
            self.pushConfig.autoFocus = open?true:false;
        } else {
            self.pushConfig.flash = open?true:false;
        }
    };
    
    AlivcParamModel *beauty_cameraTypeModel = [[AlivcParamModel alloc] init];
    beauty_cameraTypeModel.title = NSLocalizedString(@"beauty_button", nil);
    beauty_cameraTypeModel.defaultValue = 1.0;
    beauty_cameraTypeModel.titleAppose = NSLocalizedString(@"front_camera", nil);
    beauty_cameraTypeModel.defaultValueAppose = 1.0;
    beauty_cameraTypeModel.reuseId = AlivcParamModelReuseCellSwitch;
    beauty_cameraTypeModel.switchBlock = ^(int index, BOOL open) {
        if (index == 0) {
            self.pushConfig.beautyOn = open?true:false;
        } else {
            self.pushConfig.cameraType = open?AlivcLivePushCameraTypeFront:AlivcLivePushCameraTypeBack;
        }
    };
    
    AlivcParamModel *autoBitrate_resolutionModel = [[AlivcParamModel alloc] init];
    autoBitrate_resolutionModel.title = NSLocalizedString(@"auto_bitrate", nil);
    autoBitrate_resolutionModel.defaultValue = 1.0;
    autoBitrate_resolutionModel.titleAppose = NSLocalizedString(@"auto_resolution", nil);
    autoBitrate_resolutionModel.defaultValueAppose = 0;
    autoBitrate_resolutionModel.reuseId = AlivcParamModelReuseCellSwitch;
    autoBitrate_resolutionModel.switchBlock = ^(int index, BOOL open) {
        if (index == 0) {
            self.pushConfig.enableAutoBitrate = open?true:false;
        } else {
            self.pushConfig.enableAutoResolution = open?true:false;
        }
    };
    
    AlivcParamModel *userMainStream_userMixStreamModel = [[AlivcParamModel alloc] init];
    userMainStream_userMixStreamModel.title = NSLocalizedString(@"user_main_stream", nil);
    userMainStream_userMixStreamModel.reuseId = AlivcParamModelReuseCellSwitch;
    userMainStream_userMixStreamModel.defaultValue = 0.0;
    //userMainStream_userMixStreamModel.titleAppose = NSLocalizedString(@"user_mix_stream", nil);
   // userMainStream_userMixStreamModel.defaultValueAppose = 0.0;
    //userMainStream_userMixStreamModel.reuseId = AlivcParamModelReuseCellSwitch;
    userMainStream_userMixStreamModel.switchBlock = ^(int index, BOOL open) {
        if (index == 0) {
            self.isUserMainStream = open?true:false;
        }
        //else {
        //    self.isUserMixStream = open?true:false;
        //}
    };
    
    AlivcParamModel *asyncModel = [[AlivcParamModel alloc] init];
    asyncModel.title = NSLocalizedString(@"asynchronous_interface", nil);
    asyncModel.reuseId = AlivcParamModelReuseCellSwitch;
    asyncModel.defaultValue = 1.0;
    asyncModel.switchBlock = ^(int index, BOOL open) {
        if (index == 0) {
            self.isUseAsync = open;
        }
    };
    
    AlivcParamModel *watermarkModel = [[AlivcParamModel alloc] init];
    watermarkModel.title = NSLocalizedString(@"watermark", nil);
    watermarkModel.reuseId = AlivcParamModelReuseCellSwitchButton;
    watermarkModel.defaultValue = 1.0;
    watermarkModel.infoText = NSLocalizedString(@"watermark_setting", nil);
    watermarkModel.switchBlock = ^(int index, BOOL open) {
        self.isUseWatermark = open;
    };
    watermarkModel.switchButtonBlock = ^(){
        [self.view addSubview:self.waterSettingView];
    };
    
    AlivcParamModel *beautyWhiteModel = [[AlivcParamModel alloc] init];
    beautyWhiteModel.title = NSLocalizedString(@"beauty_white", nil);
    beautyWhiteModel.placeHolder = @"70";
    beautyWhiteModel.infoText = @"70";
    beautyWhiteModel.defaultValue = 0.7;
    beautyWhiteModel.reuseId = AlivcParamModelReuseCellSlider;
    beautyWhiteModel.sliderBlock = ^(int value){
        self.pushConfig.beautyWhite = value;
    };
    
    AlivcParamModel *beautyBuffingModel = [[AlivcParamModel alloc] init];
    beautyBuffingModel.title = NSLocalizedString(@"beauty_skin_smooth", nil);
    beautyBuffingModel.placeHolder = @"40";
    beautyBuffingModel.infoText = @"40";
    beautyBuffingModel.defaultValue = 0.4;
    beautyBuffingModel.reuseId = AlivcParamModelReuseCellSlider;
    beautyBuffingModel.sliderBlock = ^(int value){
        self.pushConfig.beautyBuffing = value;
    };
    
    AlivcParamModel *beautyRuddyModel = [[AlivcParamModel alloc] init];
    beautyRuddyModel.title = NSLocalizedString(@"beauty_ruddy", nil);
    beautyRuddyModel.placeHolder = @"40";
    beautyRuddyModel.infoText = @"40";
    beautyRuddyModel.defaultValue = 0.4;
    beautyRuddyModel.reuseId = AlivcParamModelReuseCellSlider;
    beautyRuddyModel.sliderBlock = ^(int value){
        self.pushConfig.beautyRuddy = value;
    };
    
    AlivcParamModel *beautyCheekPinkModel = [[AlivcParamModel alloc] init];
    beautyCheekPinkModel.title = NSLocalizedString(@"beauty_cheekpink", nil);
    beautyCheekPinkModel.placeHolder = @"15";
    beautyCheekPinkModel.infoText = @"15";
    beautyCheekPinkModel.defaultValue = 0.15;
    beautyCheekPinkModel.reuseId = AlivcParamModelReuseCellSlider;
    beautyCheekPinkModel.sliderBlock = ^(int value){
        self.pushConfig.beautyCheekPink = value;
    };
    
    AlivcParamModel *beautyThinFaceModel = [[AlivcParamModel alloc] init];
    beautyThinFaceModel.title = NSLocalizedString(@"beauty_thinface", nil);
    beautyThinFaceModel.placeHolder = @"40";
    beautyThinFaceModel.infoText = @"40";
    beautyThinFaceModel.defaultValue = 0.4;
    beautyThinFaceModel.reuseId = AlivcParamModelReuseCellSlider;
    beautyThinFaceModel.sliderBlock = ^(int value){
        self.pushConfig.beautyThinFace = value;
    };
    
    AlivcParamModel *beautyShortenFaceModel = [[AlivcParamModel alloc] init];
    beautyShortenFaceModel.title = NSLocalizedString(@"beauty_shortenface", nil);
    beautyShortenFaceModel.placeHolder = @"50";
    beautyShortenFaceModel.infoText = @"50";
    beautyShortenFaceModel.defaultValue = 0.5;
    beautyShortenFaceModel.reuseId = AlivcParamModelReuseCellSlider;
    beautyShortenFaceModel.sliderBlock = ^(int value){
        self.pushConfig.beautyShortenFace = value;
    };
    
    AlivcParamModel *beautyBigEyeModel = [[AlivcParamModel alloc] init];
    beautyBigEyeModel.title = NSLocalizedString(@"beauty_bigeye", nil);
    beautyBigEyeModel.placeHolder = @"30";
    beautyBigEyeModel.infoText = @"30";
    beautyBigEyeModel.defaultValue = 0.3;
    beautyBigEyeModel.reuseId = AlivcParamModelReuseCellSlider;
    beautyBigEyeModel.sliderBlock = ^(int value){
        self.pushConfig.beautyBigEye = value;
    };
    
    
    AlivcParamModel *videoOnly_audioHardwareEncodeModel = [[AlivcParamModel alloc] init];
    videoOnly_audioHardwareEncodeModel.title = NSLocalizedString(@"video_only_push_streaming", nil);
    videoOnly_audioHardwareEncodeModel.defaultValue = 0;
    videoOnly_audioHardwareEncodeModel.titleAppose = NSLocalizedString(@"audio_hardware_encode", nil);
    videoOnly_audioHardwareEncodeModel.defaultValueAppose = 1.0;
    
    videoOnly_audioHardwareEncodeModel.reuseId = AlivcParamModelReuseCellSwitch;
    videoOnly_audioHardwareEncodeModel.switchBlock = ^(int index, BOOL open) {
        if (index == 0) {
            self.pushConfig.videoOnly = open?true:false;
        } else {
            self.pushConfig.audioEncoderMode = open?AlivcLivePushAudioEncoderModeHard:AlivcLivePushAudioEncoderModeSoft;
        }
    };
    
    AlivcParamModel *backgroundImage_networkWeakImageModel = [[AlivcParamModel alloc] init];
    backgroundImage_networkWeakImageModel.title = NSLocalizedString(@"background_image", nil);
    backgroundImage_networkWeakImageModel.defaultValue = 1.0;
    backgroundImage_networkWeakImageModel.titleAppose = NSLocalizedString(@"network_weak_image", nil);
    backgroundImage_networkWeakImageModel.defaultValueAppose = 1.0;
    
    backgroundImage_networkWeakImageModel.reuseId = AlivcParamModelReuseCellSwitch;
    backgroundImage_networkWeakImageModel.switchBlock = ^(int index, BOOL open) {
        if (index == 0) {
            
            // 设置占位图片
            if(open) {
                if(self.pushConfig.orientation == AlivcLivePushOrientationPortrait) {
                    self.pushConfig.pauseImg = [UIImage imageNamed:@"background_push.png"];
                } else{
                    self.pushConfig.pauseImg = [UIImage imageNamed:@"background_push_land.png"];
                }
            }else {
                self.pushConfig.pauseImg = nil;
            }
            
        } else {
            if(open) {
                if(self.pushConfig.orientation == AlivcLivePushOrientationPortrait) {
                    self.pushConfig.networkPoorImg = [UIImage imageNamed:@"poor_network.png"];
                } else{
                    self.pushConfig.networkPoorImg = [UIImage imageNamed:@"poor_network_land.png"];
                }
            }else {
                self.pushConfig.networkPoorImg = nil;
            }
        }
    };
    
    AlivcParamModel *qualityModeModel = [[AlivcParamModel alloc] init];
    qualityModeModel.title = NSLocalizedString(@"quality_mode_label", nil);
    qualityModeModel.segmentTitleArray = @[@"清晰优先",@"流畅优先",@"自定义"];
    qualityModeModel.defaultValue = 0;
    qualityModeModel.reuseId = AlivcParamModelReuseCellSegment;
    qualityModeModel.segmentBlock = ^(int value) {
        self.pushConfig.qualityMode = value;
        [self updateBitrateAndFPSCell];
    };
    
    AlivcParamModel *beautyModeModel = [[AlivcParamModel alloc] init];
    beautyModeModel.title = NSLocalizedString(@"beauty_mode_label", nil);
    beautyModeModel.segmentTitleArray = @[@"普通版",@"专业版"];
    beautyModeModel.defaultValue = 1.0;
    beautyModeModel.reuseId = AlivcParamModelReuseCellSegment;
    beautyModeModel.segmentBlock = ^(int value) {
        self.pushConfig.beautyMode = value;
    };
    
    AlivcParamModel *authTimeModel = [[AlivcParamModel alloc] init];
    authTimeModel.title = NSLocalizedString(@"AuthTime", nil);
    authTimeModel.placeHolder = @"";
    authTimeModel.infoText = @"ms";
    authTimeModel.reuseId = AlivcParamModelReuseCellInput;
    authTimeModel.stringBlock = ^(NSString *message) {
        self.authDuration = message;
    };
    
    AlivcParamModel *authKeyModel = [[AlivcParamModel alloc] init];
    authKeyModel.title = NSLocalizedString(@"AuthKey", nil);
    authKeyModel.placeHolder = @"";
    authKeyModel.infoText = @"";
    authKeyModel.reuseId = AlivcParamModelReuseCellInput;
    authKeyModel.stringBlock = ^(NSString *message) {
        self.authKey = message;
    };

    self.dataArray = [NSMutableArray arrayWithObjects:resolutionModel, qualityModeModel,targetBitrateModel, minBitrateModel, initBitrateModel, audioBitrateModel, audioSampelModel, fpsModel, minFPSModel, gopModel, reconnectDurationModel, reconnectTimeModel, orientationModel, audioChannelModel, audioProfileModel, mirrorModel, audiOnly_encodeModeModel, videoOnly_audioHardwareEncodeModel,backgroundImage_networkWeakImageModel,autoFocus_FlashModel, beauty_cameraTypeModel, autoBitrate_resolutionModel, userMainStream_userMixStreamModel, asyncModel, watermarkModel,beautyModeModel, beautyWhiteModel, beautyBuffingModel, beautyRuddyModel, beautyCheekPinkModel, beautyThinFaceModel, beautyShortenFaceModel, beautyBigEyeModel, nil];
  
    // Demo 中pushConfig初始值设置
    // 默认支持背景图片和弱网图片推流
    self.pushConfig.pauseImg = [UIImage imageNamed:@"background_push.png"];
    self.pushConfig.networkPoorImg = [UIImage imageNamed:@"poor_network.png"];
}


- (void)updateBitrateAndFPSCell {
    
    int targetBitrate = 0;
    int minBitrate = 0;
    int initBitrate = 0;
    BOOL enable = NO;
    
    if (self.pushConfig.qualityMode == AlivcLivePushQualityModeFluencyFirst) {
        // 流畅度优先模式，bitrate 固定值不可修改
        enable = NO;
        switch (self.pushConfig.resolution) {
            case AlivcLivePushResolution180P:
                targetBitrate = 250;
                minBitrate = 80;
                initBitrate = 200;
                break;
            case AlivcLivePushResolution240P:
                targetBitrate = 350;
                minBitrate = 120;
                initBitrate = 300;
                break;
            case AlivcLivePushResolution360P:
                targetBitrate = 600;
                minBitrate = 200;
                initBitrate = 400;
                break;
            case AlivcLivePushResolution480P:
                targetBitrate = 800;
                minBitrate = 300;
                initBitrate = 600;
                break;
            case AlivcLivePushResolution540P:
                targetBitrate = 1000;
                minBitrate = 300;
                initBitrate = 800;
                break;
            case AlivcLivePushResolution720P:
                targetBitrate = 1200;
                minBitrate = 300;
                initBitrate = 1000;
                break;
            default:
                break;
        }
    }
    
    if (self.pushConfig.qualityMode == AlivcLivePushQualityModeResolutionFirst) {
        // 清晰度优先模式，bitrate 固定值不可修改
        enable = NO;
        switch (self.pushConfig.resolution) {
            case AlivcLivePushResolution180P:
                targetBitrate = 550;
                minBitrate = 120;
                initBitrate = 300;
                break;
            case AlivcLivePushResolution240P:
                targetBitrate = 750;
                minBitrate = 180;
                initBitrate = 450;
                break;
            case AlivcLivePushResolution360P:
                targetBitrate = 1000;
                minBitrate = 300;
                initBitrate = 600;
                break;
            case AlivcLivePushResolution480P:
                targetBitrate = 1200;
                minBitrate = 300;
                initBitrate = 800;
                break;
            case AlivcLivePushResolution540P:
                targetBitrate = 1400;
                minBitrate = 600;
                initBitrate = 1000;
                break;
            case AlivcLivePushResolution720P:
                targetBitrate = 2000;
                minBitrate = 600;
                initBitrate = 1500;
                break;
            default:
                break;
        }
    }
    
    if (self.pushConfig.qualityMode == AlivcLivePushQualityModeCustom) {
        // 自定义模式，bitrate 固定值可修改
        enable = YES;
        targetBitrate = self.pushConfig.targetVideoBitrate;
        minBitrate = self.pushConfig.minVideoBitrate;
        initBitrate = self.pushConfig.initialVideoBitrate;
    }
    
    AlivcParamTableViewCell *targetCell = [self.paramTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    [targetCell updateDefaultValue:targetBitrate enable:enable];
    
    AlivcParamTableViewCell *minCell = [self.paramTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    [minCell updateDefaultValue:minBitrate enable:enable];
    
    AlivcParamTableViewCell *initCell = [self.paramTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];
    [initCell updateDefaultValue:initBitrate enable:enable];
}

- (NSString *)getWatermarkPathWithIndex:(NSInteger)index {
    
    NSString *watermarkBundlePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"watermark"] ofType:@"png"];
    
    return watermarkBundlePath;
}

#pragma mark - TableViewdelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    AlivcParamModel *model = self.dataArray[indexPath.row];
    if (model) {
        NSString *cellIdentifier = [NSString stringWithFormat:@"AlivcLivePushTableViewIdentifier%ld", (long)indexPath.row];
        AlivcParamTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[AlivcParamTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            [cell configureCellModel:model];
        }
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (![self.waterSettingView isEditing]) {
        [self.waterSettingView removeFromSuperview];
    }
    [self.view endEditing:YES];
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    [self.view endEditing:YES];
}


#pragma mark - Keyboard

- (void)addKeyboardNoti {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}


- (void)keyboardWillShow:(NSNotification *)sender {
  
    if(!self.isKeyboardShow){
     
        //获取键盘的frame
        CGRect keyboardFrame = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        // 修改tableView frame
        [UIView animateWithDuration:0 animations:^{
            CGRect frame = self.paramTableView.frame;
            frame.size.height = frame.size.height - keyboardFrame.size.height;
            self.paramTableView.frame = frame;
        }];
        
        self.isKeyboardShow = true;
    }
 
}


- (void)keyboardWillHide:(NSNotification *)sender {
  
    if(self.isKeyboardShow){
        self.paramTableView.frame = self.tableViewFrame;
        self.isKeyboardShow = false;
    }
  
}




#pragma mark - TO PublisherVC
- (void)publiherButtonAction:(UIButton *)sender {
    
    NSString *pushURLString = self.publisherURLTextField.text;
    if (!pushURLString) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"请输入推流地址" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    // 更新水印坐标
    if (self.isUseWatermark) {
        for (int index = 0; index <= 3; index++) {
            AlivcWatermarkSettingStruct watermarkSetting = [self.waterSettingView getWatermarkSettingsWithCount:index];
            NSString *watermarkPath = [self getWatermarkPathWithIndex:index];
            [self.pushConfig addWatermarkWithPath:watermarkPath
                                  watermarkCoordX:watermarkSetting.watermarkX
                                  watermarkCoordY:watermarkSetting.watermarkY
                                   watermarkWidth:watermarkSetting.watermarkWidth];
        }
    }else {
        
        NSArray *watermarkArr = [self.pushConfig getAllWatermarks];
        for (NSDictionary *watermark in watermarkArr) {
            
            NSString *path = [watermark objectForKey:@"watermarkPath"];
            [self.pushConfig removeWatermarkWithPath:path];

        }
    }
    
    AlivcLivePusherViewController *publisherVC = [[AlivcLivePusherViewController alloc] init];
    publisherVC.pushURL = self.publisherURLTextField.text;
    publisherVC.pushConfig = self.pushConfig;
    publisherVC.isUseAsyncInterface = self.isUseAsync;
    publisherVC.authKey = self.authKey;
    publisherVC.authDuration = self.authDuration;
    publisherVC.isUserMainStream = self.isUserMainStream;

    
    [self presentViewController:publisherVC animated:YES completion:nil];
    
}


#pragma mark - TO QRCodeVC
- (void)QRCodeButtonAction:(UIButton *)sender {
    
    [self.view endEditing:YES];
    AlivcQRCodeViewController *QRController = [[AlivcQRCodeViewController alloc] init];
    __weak typeof(self) weakSelf = self;
    QRController.backValueBlock = ^(NSString *value) {
        
        if (value) {
            weakSelf.publisherURLTextField.text = value;
        }
    };
    [self.navigationController pushViewController:QRController animated:YES];
}

#pragma mark - TO urlCpoy
- (void)urlCopyButtonAction:(UIButton *)sender {

    [UIPasteboard generalPasteboard].string = @"rtmp://push-demo.aliyunlive.com/test/stream45";
    [self updateInfoText:NSLocalizedString(@"url_copy_tips", nil)];
    

}

- (void)setupInfoLabel {
    
    self.infoLabel = [[UILabel alloc] init];
    self.infoLabel.frame = CGRectMake(20, 100, self.view.bounds.size.width - 40, 100);
    self.infoLabel.textColor = [UIColor blackColor];
    self.infoLabel.backgroundColor = AlivcRGBA(255, 255, 255, 1.0);
    self.infoLabel.font = [UIFont systemFontOfSize:14.f];
    self.infoLabel.layer.masksToBounds = YES;
    self.infoLabel.layer.cornerRadius = 10;
    self.infoLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.infoLabel];
    self.infoLabel.hidden = YES;
}

- (void)updateInfoText:(NSString *)text {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.infoLabel setHidden:NO];
        self.infoLabel.text = text;
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(hiddenInfoLabel) withObject:nil afterDelay:2.0];
        
    });
}

- (void)hiddenInfoLabel {
    
    [self.infoLabel setHidden:YES];
}


@end

