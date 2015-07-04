//
//  MSBluetoothManager.m
//  ThermometerDemo
//
//  Created by xubin luo on 14-4-30.
//  Copyright (c) 2014年 Coolball. All rights reserved.
//

#import "MSBluetoothManager.h"
#import "TKAlertCenter.h"
#define SCACN_INTERVALS 1.5


@interface MSBluetoothManager()
@property BOOL cbReady;
@property (nonatomic,strong) CBCentralManager *cbCM;
@property (strong,nonatomic) NSMutableArray *nDevices;
@property (strong,nonatomic) NSMutableArray *nServices;
@property (strong,nonatomic) NSMutableArray *nCharacteristics;

@property (strong,nonatomic) CBPeripheral *cbPeripheral;
@property (strong,nonatomic) CBService *cbServices;
@property (strong,nonatomic) CBCharacteristic *cbCharacteristcs;


@end



@implementation MSBluetoothManager

+(MSBluetoothManager*)shareInstance
{
    static dispatch_once_t pred = 0;
    __strong static MSBluetoothManager *_sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init]; // or some other init method
    });
    return _sharedObject;
}


#pragma mark -对外接口
/**
 *  开始扫描
 */
-(void)startScan
{
    
    if(_bluetoothPowerOn)
    {
        if( !_cbReady   )
        {
            [self updateLog:@"Scan for Peripheral..."];
            [_cbCM scanForPeripheralsWithServices:nil options:nil];
            
            //        [self performSelector:@selector(startScan) withObject:nil afterDelay:SCACN_INTERVALS];
        }
    }
    else
    {
        //弹框提示，请去系统中打开蓝牙
        [[TKAlertCenter defaultCenter]postAlertWithMessage:NSLocalizedString(@"Please open the Bluetooth on system settings", @"请到系统设置中打开蓝牙")];
    }
    
}

/**
 *  停止扫描
 */
-(void)stopScan
{
    [self updateLog:@"stop scan..."];
    [_cbCM stopScan];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startScan) object:nil];
}


/**
 *  连接
 */
-(void)startconnect
{
    if (_cbReady ==false)
    {
        [self.cbCM connectPeripheral:_cbPeripheral options:nil];
    }
}

/**
 *  取消连接
 */
-(void)cancelConnect
{
    if(_cbReady)
    {
        [_cbCM cancelPeripheralConnection:_cbPeripheral];
    }
    
}


/**
 *  向设备写数据
 */
-(BOOL)writeData:(NSData*)data
{
    BOOL ret = NO;
    if([data length] >0)
    {
        [self writeCharacteristic:_cbPeripheral sUUID:MySUUID cUUID:MyCUUID data:data];
        ret = YES;
    }

    return ret;
}


/**
 *  是否可以准备好写数据
 *
 *  @return 是否可以准备好写数据
 */
-(BOOL)isReady
{
    return _cbReady;
}

/**
 *  发送命令
 *
 *  @param command 命令内容
 *
 *  @return 是否发送成功
 */
-(BOOL)sendCommand:(EN_CommandType)command
{
    NSLog(@"begin send command:%d",command);
    BOOL ret  = NO;
    if([self isReady])
    {
        unsigned char data [6]= {0};
        data[0] = 0xa5;
        *(data+1) = 0x01;
        *(data+2) = 0x01;

        switch (command) {
            case EN_Command_Start:
            {
               
            }
                break;
            case EN_Command_Stop:
            {
                command = 0x00;
            }
                break;
            case EN_Command_Mode1:
                break;
            case EN_Command_Mode2:
                break;
            case EN_Command_Mode3:
                break;
            case EN_Command_Mode4:
            case EN_Command_Mode5:
            case EN_Command_Mode6:
            case EN_Command_Mode7:
            case EN_Command_Mode8:
            case EN_Command_Mode9:
            {
//                datastr = [NSString stringWithFormat:@"%d",command];
            }
                break;
            case EN_Command_Shutdown:
            {
                command = 0x5a;
            }
            default:
                break;
        }
        
        NSLog(@"send command:%d",command);
        
 
        
        *(data+3) = command;
        
//        datastr = @"1234567890";
        
//        NSNumber* num = @(0x01);
        
//        NSData* data = [datastr dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        
        
             do_crc(data,6);
      
//        char a[10]= {0x2,0x2,0x2,0x2,0x2,0x2,0x2,0x2,0x2,0x2};
        NSData *nsdata = [NSData dataWithBytes:data length: sizeof(char)*6];
        
        NSLog(@"send data: %@",nsdata);
        //真正发送命令
        ret = [self writeData:nsdata];
    }
    return ret;
}



#pragma mark -CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStatePoweredOff:
            [self updateLog:@"CoreBluetooth BLE hardware is Powered off"];
            //对外抛出断开连接的通知
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDisconnected object:nil];
            _cbReady = FALSE;
            _bluetoothPowerOn = FALSE;
            break;
        case CBCentralManagerStatePoweredOn:
            [self updateLog:@"CoreBluetooth BLE hardware is Powered on and ready"];
            _bluetoothPowerOn = YES;
            break;
            //cbReady = true;
        case CBCentralManagerStateResetting:
//            _cbReady = FALSE;
            [self updateLog:@"CoreBluetooth BLE hardware is resetting"];
            break;
        case CBCentralManagerStateUnauthorized:
            
            [self updateLog:@"CoreBluetooth BLE state is unauthorized"];
//            _cbReady = FALSE;
            
            break;
        case CBCentralManagerStateUnknown:
            
            [self updateLog:@"CoreBluetooth BLE state is unknown"];
            break;
        case CBCentralManagerStateUnsupported:
//            _cbReady = FALSE;
            [self updateLog:@"CoreBluetooth BLE hardware is unsupported on this platform"];
            break;
        default:
            break;
    }
}


//已发现从机设备
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
   
    [self updateLog:[NSString stringWithFormat:@"Did discover peripheral. peripheral: %@ rssi: %@, UUID: %@ advertisementData: %@ ", peripheral, RSSI, peripheral.identifier, advertisementData]];
    
    BOOL replace = NO;
    
    // Match if we have this device from before
    for (int ii=0; ii < _nDevices.count; ii++) {
        CBPeripheral *p = [_nDevices objectAtIndex:ii];
        if ([p isEqual:peripheral]) {
            [_nDevices replaceObjectAtIndex:ii withObject:peripheral];
            replace = YES;
        }
    }
    if (!replace) {
        if ([peripheral.name isEqualToString:MyPeripheralName]) {
            [_nDevices addObject:peripheral];
            [self updateLog:@"has found MyPeripheralName！\r\n"];
            
            _cbPeripheral = peripheral;
         
            
        }
        
    }
    if(_cbPeripheral )
    {
        //开始连接
        [self startconnect];
    }
}


//已链接到从机
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    
    //取消重连
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startScan) object:nil];
    
    [self updateLog:[NSString stringWithFormat:@"Connection successfull to peripheral: %@ with UUID: %@",peripheral,peripheral.identifier]];
    //Do somenthing after successfull connection.
    
    //发现services
    //设置peripheral的delegate未self非常重要，否则，didDiscoverServices无法回调
    peripheral.delegate = self;
    [_cbPeripheral discoverServices:nil];
    _cbReady = true;
    [self updateLog:@"didConnectPeripheral"];
    
    //对外抛出连接的通知
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationConnected object:nil];
    
    
    //统计
    [AVAnalytics event:@"ConnectToHardWare"];
    
}


//已断开从机的链接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self updateLog:[NSString stringWithFormat:@"Disconnected from peripheral: %@ with UUID: %@",peripheral,peripheral.identifier]];
    //Do something when a peripheral is disconnected.
    _cbReady = false;
    
    //对外抛出断开连接的通知
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDisconnected object:nil];
    
    
    //统计
    [AVAnalytics event:@"DisconnectToHardWare"];
    
    //尝试重连
    dispatch_async(dispatch_get_main_queue(), ^{
        [self startScan];
        });
}



- (void) centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals {
    
    [self updateLog:[NSString stringWithFormat:@"Currently connected peripherals :"]];
    int i = 0;
    for(CBPeripheral *peripheral in peripherals) {
        [self updateLog:[NSString stringWithFormat:@"[%d] - peripheral : %@ with UUID : %@",i,peripheral,peripheral.identifier]];
        i++;
        //Do something on each connected peripheral.
    }
    
}

- (void) centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals {
    
    [self updateLog:[NSString stringWithFormat:@"Currently known peripherals :"]];
    int i = 0;
    for(CBPeripheral *peripheral in peripherals) {
        
        [self updateLog:[NSString stringWithFormat:@"[%d] - peripheral : %@ with UUID : %@",i,peripheral,peripheral.identifier]];
        i++;
        //Do something on each known peripheral.
    }
}





//delegate of CBPeripheral
//已搜索到services
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    
    [self updateLog:@"Found Services."];
    
    int i=0;
    for (CBService *s in peripheral.services) {
        
        [self.nServices addObject:s];
        
    }
    
    
    for (CBService *s in peripheral.services) {
        [self updateLog:[NSString stringWithFormat:@"%d :Service UUID: %@(%@)",i,s.UUID.data,s.UUID]];
        i++;
        [peripheral discoverCharacteristics:nil forService:s];
    }
}




#pragma mark -CBPeripheralDelegate
//
////已读到char
//-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
//    if (error) {
//        return;
//    }
//    unsigned char data[characteristic.value.length];
//    [characteristic.value getBytes:&data];
//    
//    
//}



//已搜索到Characteristics
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    [self updateLog:[NSString stringWithFormat:@"Found Characteristics in Service:%@ (%@)",service.UUID.data ,service.UUID]];
    
    for (CBCharacteristic *c in service.characteristics) {
        [self updateLog:[NSString stringWithFormat:@"Characteristic UUID: %@ (%@)",c.UUID.data,c.UUID]];
        [_nCharacteristics addObject:c];
        
    }
}




//已读到char
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        return;
    }
    unsigned char data[characteristic.value.length];
    [characteristic.value getBytes:&data];
    NSDate*date = [NSDate date];
    NSCalendar*calendar = [NSCalendar currentCalendar];
    NSDateComponents*comps;
    comps =[calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit |NSSecondCalendarUnit) fromDate:date];
    
    NSInteger hour = [comps hour];
    NSInteger minute = [comps minute];
    NSInteger second = [comps second];
    
    [self updateLog:[NSString stringWithFormat:@"char update! [%ld:%ld:%ld],char = %d",hour,minute,second,data[0]]];
}


#pragma mark -内部函数
-(id)init
{
    if(self = [super init])
    {
        _cbCM = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _cbServices =[[CBService alloc]init];
        _cbCharacteristcs =[[CBCharacteristic alloc]init];
        
        //列表初始化
        _nDevices = [[NSMutableArray alloc]init];
        _nServices = [[NSMutableArray alloc]init];
        _nCharacteristics = [[NSMutableArray alloc]init];
        
        _cbReady = FALSE;
        _bluetoothPowerOn = FALSE;
        
    }
    return self;
}



-(void)updateLog:(NSString *)s
{
    //用回NSLog，
    NSLog(@"%@",s );
}



-(void)writeCharacteristic:(CBPeripheral *)peripheral sUUID:(NSString *)sUUID cUUID:(NSString *)cUUID data:(NSData *)data {
    // Sends data to BLE peripheral to process HID and send EHIF command to PC
    for ( CBService *service in peripheral.services ) {
        
        if ([service.UUID isEqual:[CBUUID UUIDWithString:sUUID]]) {
            
            for ( CBCharacteristic *characteristic in service.characteristics ) {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:cUUID]]) {
                    [self updateLog:@"has reached\r\n"];
                    /* EVERYTHING IS FOUND, WRITE characteristic ! */
                    
                    [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                    
                }
            }
        }
    }
}


-(void)setNotificationForCharacteristic:(CBPeripheral *)peripheral sUUID:(NSString *)sUUID cUUID:(NSString *)cUUID enable:(BOOL)enable {
    for ( CBService *service in peripheral.services ) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:sUUID]]) {
            for (CBCharacteristic *characteristic in service.characteristics ) {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:cUUID]])
                {
                    /* Everything is found, set notification ! */
                    [peripheral setNotifyValue:enable forCharacteristic:characteristic];
                }
                
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error

{
    
    [self updateLog:[NSString stringWithFormat:@"%@",error]];
    
    
}


void  do_crc(unsigned char *data,
             unsigned short int length)
{
   //此处裤宝的加密算法，略去
    
}


@end
