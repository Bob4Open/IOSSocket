//
//  IOSSocket.m
//  IOSSocket
//
//  Created by Boni on 2021/8/12.
//

#import "Socket.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

#define NotifyMainQueue(DES) dispatch_async(dispatch_get_main_queue(), ^{ DES; });

@interface IOSSocket ()
@property (nonatomic, strong) NSURL *socketUrl;
@property (nonatomic, assign) int socketId;
@property (nonatomic, strong) NSThread *socketThread;
@end

#pragma mark - IOSSocket
@implementation IOSSocket

- (instancetype)initWithURL:(NSURL *)url {
    if (self == [super init]) {
        _socketUrl = url;
    }
    return self;
}

- (int)createSocket {
    return socket(AF_INET, SOCK_STREAM, 0);
}

- (int)bindSocket {
    struct sockaddr_in server;
    bzero(&server, sizeof(server));
    server.sin_family = AF_INET;
    server.sin_port = htons([[_socketUrl port] integerValue]);
    server.sin_addr.s_addr = inet_addr([[_socketUrl host] UTF8String]);

    return bind(_socketId, (struct sockaddr *)&server, sizeof(server));
}

- (int)listen {
    return listen(_socketId, 1024);
}

- (int)acceptData {
    struct sockaddr_in client_address;
    socklen_t address_len;

    return accept(_socketId, (struct sockaddr *)&client_address, &address_len);
}

- (void)recv {
    while (true) {
        char buffer[1024];
        ssize_t sendedCount = recv(_socketId, (void *)buffer, 1024, 0);
        if (sendedCount > 0) {
            NSString *message = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
            NSLog(@"%@", NSStringFromSelector(_cmd));
            NotifyMainQueue([self performSelector:self.delegate selector:@selector(socketDidLoad:) data:message]);
        }
    }
}

- (int)connectServer {
    struct sockaddr_in server;
    bzero(&server, sizeof(server));
    server.sin_family = AF_INET;
    server.sin_port = htons([[_socketUrl port] integerValue]);
    server.sin_addr.s_addr = inet_addr([[_socketUrl host] UTF8String]);
    return connect(_socketId, (struct sockaddr *)&server, sizeof(server));
}

- (void)close {
    close(_socketId);
}

- (void)sendMessage:(NSString *)message {
    NSLog(@"%@", message);
    ssize_t result =  send(_socketId, [message UTF8String], 1024, 0);
    NSLog(@"%zi", result);
}

- (void)performSelector:(NSObject *)object selector:(SEL)selector data:(id)data {
    if (object && [object respondsToSelector:selector]) {
        IMP imp = [object methodForSelector:selector];
        void (*func)(id, SEL, id) = (void *)imp;
        func(object, selector, data);
        return;
    }
    NSLog(@"%@ is NotImplement!", NSStringFromSelector(selector));
}

@end

#pragma mark - IOSSocket Server
@implementation IOSSocket (Server)

- (void)open {
    _socketThread = [[NSThread alloc]initWithTarget:self selector:@selector(initSocketForServer) object:nil];
    [_socketThread start];
}

- (void)initSocketForServer {
    _socketId = [self createSocket];
    if (_socketId == -1) {
        NotifyMainQueue([self performSelector:self.delegate selector:@selector(socketDidFaild:) data:@"something wrong occured when initialize socketDescription"])
        return;
    }

    NotifyMainQueue([self performSelector:self.delegate selector:@selector(socketDidStart) data:nil])
    int bindResult = [self bindSocket];
    if (bindResult == -1) {
        NotifyMainQueue([self performSelector:self.delegate selector:@selector(socketDidFaild:) data:@"something wrong when binding socket configuration"])
        return;
    }

    int listenResult = [self listen];
    if (listenResult == -1) {
        NotifyMainQueue([self performSelector:self.delegate selector:@selector(socketDidFaild:) data:@"listen Socket failed"])
        return;
    }

    int acceptResult = [self acceptData];
    if (acceptResult == -1) {
        NotifyMainQueue([self performSelector:self.delegate selector:@selector(socketDidFaild:) data:@"something wrong in accept function"])
        return;
    } else {
        self->_socketId = acceptResult;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"acceptance done");
        });
    }

    [self recv];
}

@end

#pragma mark - IOSSocket Client
@implementation IOSSocket (Client)

- (void)connect {
    _socketThread = [[NSThread alloc]initWithTarget:self selector:@selector(initSocketForClient) object:nil];
    [_socketThread start];
}

- (void)initSocketForClient {
    _socketId = [self createSocket];
    if (_socketId == -1) {
        
        NotifyMainQueue([self performSelector:self.delegate selector:@selector(socketDidFaild:) data:@"something wrong occured when initialize socketDescription"])
        return;
    }
    
    NotifyMainQueue([self performSelector:self.delegate selector:@selector(socketDidStart) data:nil])
    int connectResult = [self connectServer];
    if (connectResult == -1) {
        NotifyMainQueue([self performSelector:self.delegate selector:@selector(socketDidFaild:) data:@"something wrong in connection action"]);
        return;
    }
    
    NotifyMainQueue([self performSelector:self.delegate selector:@selector(socketDidConnect) data:nil]);
    [self recv];
}

@end
