//
//  IOSSocket.h
//  IOSSocket
//
//  Created by Boni on 2021/8/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@protocol IOSSocketServerDelegate;
@protocol IOSSocketClientDelegate;

@protocol IOSSocketDelegate <IOSSocketServerDelegate, IOSSocketClientDelegate>
@optional

- (void)socketDidStart;

- (void)socketDidFaild:(NSString *)reason;

- (void)socketDidLoad:(NSString *)message;

@end

#pragma mark - IOSSocket
@interface IOSSocket : NSObject

@property (nonatomic, strong) id<IOSSocketDelegate> delegate;

- (instancetype)initWithURL:(NSURL *)url ;

- (void)sendMessage:(NSString*)message ;

- (void)close ;

@end

#pragma mark - IOSSocket Server
@protocol IOSSocketServerDelegate <NSObject>
@optional

- (void)socketDidClose;

@end

@interface IOSSocket (Server)

- (void)open;

@end

#pragma mark - IOSSocket Client
@protocol IOSSocketClientDelegate <NSObject>
@optional

- (void)socketDidConnect;

@end

@interface IOSSocket (Client)

- (void)connect ;

@end

NS_ASSUME_NONNULL_END
