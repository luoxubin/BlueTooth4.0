Demo code show how to control a hardware by iPhone with bluetooth4.0
封装了Corebluetooth.framework的一些基础方法，提供以下核心功能接口，

/**
 *  开始扫描
 */
-(void)startScan;

/**
 *  停止扫描
 */
-(void)stopScan;


/**
 *  连接
 */
-(void)startconnect;

/**
 *  取消连接
 */
-(void)cancelConnect;

/**
 *  向设备写数据
 */
-(BOOL)writeData:(NSData*)data;

/**
 *  是否可以准备好写数据
 *
 *  @return 是否可以准备好写数据
 */
-(BOOL)isReady;



该方法应用于裤宝，蓝牙4.0连接的外设不需要MFi认证，已安全上架。
裤宝：
https://itunes.apple.com/cn/app/coolballplay/id900830047?l=ch&mt=8



