//
//  SHAppDelegate.m
//  Shuffler
//
//  Created by Евгений Кратько on 16.04.13.
//  Copyright (c) 2013 Akki. All rights reserved.
//

#import "SHAppDelegate.h"
#import "YRKSpinningProgressIndicator.h"

@interface SHAppDelegate()
{
    BOOL needReload;
}
@end

@implementation SHAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    needReload = NO;
    [self setNameLength:@(5)];
    [self setPercentage:@(0)];
    [self setIncludeSubdirs:YES];
    [self addObserver:self forKeyPath:@"includeSubdirs" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"includeSubdirs"]) {
        [self setToPerform:nil];
        [self.foundLabel setStringValue:[NSString stringWithFormat:@"Found %ld files.", self.toPerform.count]];
        [self.totalSizeLabel setStringValue:[self sizeToPerformString]];
    }
}

- (IBAction)shuffle:(id)sender
{
    [self setPercentage:@(0)];
    if (needReload) {
        [self setItems:nil];
        [self setToPerform:nil];
        [self pathsFrom:self.pathURL completion:^(NSArray* array){
            [self setItems:array];
            [self shuffleByIndex:[self.radioGroup selectedRow]];
        }];
    }
    else {
        [self shuffleByIndex:[self.radioGroup selectedRow]];
    }
}

- (IBAction)loadContent:(id)sender
{
    [self setAllEnabled:NO];
    self.items = nil;
    [self pathsFrom:self.pathURL completion:^(NSArray* array){
        [self setItems:array];
        
        if (self.items) {
            [self setAllEnabled:YES];
            [self.foundLabel setStringValue:[NSString stringWithFormat:@"Found %ld files.", self.toPerform.count]];
            [self.totalSizeLabel setStringValue:[self sizeToPerformString]];
            if (needReload) needReload = NO;
        }
    }];
}

- (void)shuffleByIndex:(NSInteger)index
{
    switch (index) {
        case 0: {
            [self renameByNumbers:[self toPerform]];
            break;
        }
        case 1: {
            [self renameByLetters:[self toPerform]];
            break;
        }
        default: break;
    }
    needReload = YES;
}

- (void)setAllEnabled:(BOOL)enabled
{
    for (NSView *view in [self.window.contentView subviews]) {
        if ([view respondsToSelector:@selector(setEnabled:)]) {
            NSControl *control = (NSControl*)view;
            if (control.tag == 999 || control.tag == 998) {
                if (self.stringSelected)
                    [control setEnabled:enabled];
            }
        }
    }
}
/*
- (NSArray *)items
{
    if (!_items) {
        _items = [self pathsFrom:self.pathURL];
        needReload = NO;
    }
    return _items;
}
*/
- (NSArray *)toPerform
{
    if (!_toPerform) {
        NSString *myPath = self.pathURL.path;
        if (self.includeSubdirs) {
            _toPerform = [self.items copy];
        }
        else {
            NSMutableArray *result = [NSMutableArray new];
            for (NSString *path in self.items) {
                if ([[[[path componentsSeparatedByString:myPath] objectAtIndex:1] pathComponents] count] == 2) {
                    [result addObject:path];
                }
            }
            _toPerform = result;
        }
    }
    return _toPerform;
}

- (void)pathsFrom:(NSURL*)folderURL completion:(void(^)(NSArray*))completionHandler
{
    [self setPercentage:@(0)];
    NSURL *weakURL = [folderURL copy];
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:weakURL includingPropertiesForKeys:@[NSURLIsDirectoryKey] options:0 errorHandler:^BOOL(NSURL *url, NSError *error){return YES;}];
    __block NSEnumerator *testEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:weakURL includingPropertiesForKeys:@[NSURLIsDirectoryKey] options:0 errorHandler:^BOOL(NSURL *url, NSError *error){return YES;}];;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        __block YRKSpinningProgressIndicator *ind = [[YRKSpinningProgressIndicator alloc] initWithFrame:[self.window.contentView bounds]];
        [ind setIndeterminate:YES];
        [ind setDrawsBackground:YES];
        [ind setBackgroundColor:[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:.5]];
        [ind setColor:[NSColor colorWithCalibratedRed:1 green:.7 blue:.7 alpha:.5]];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.window.contentView addSubview:ind];
            [ind startAnimation:self];
        });
        
        NSUInteger allCount = [[testEnumerator allObjects] count];
        testEnumerator = nil;
        NSMutableArray *result = nil;
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [ind stopAnimation:self];
            [ind removeFromSuperview];
            ind = nil;
        });
        
        for (NSURL *url in enumerator) {
            NSError *error;
            NSNumber *isDirectory = nil;
            if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
                // handle error
            }
            else if ([isDirectory boolValue]) {
                allCount--;
            }
            else {
                // No error and it’s not a directory; do something with the file
                BOOL isHidden = NO;
                for (NSString *component in url.pathComponents) {
                    if ([component hasPrefix:@"."]) {
                        isHidden = YES;
                        allCount--;
                        break;
                    }
                }
                if (!isHidden) {
                    if (!result) result = [NSMutableArray new];
                    [result addObject:url.path];
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self setPercentage:@(((float)result.count/(float)allCount)*100)];
                        [self.foundLabel setStringValue:[NSString stringWithFormat:@"Found %ld files.", result.count]];
                    });
                }
            }
        }
        if (completionHandler) {
            completionHandler(result);
        }
    });
}

- (void)renameByLetters:(NSArray*)paths
{
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSInteger length = [self.nameLength integerValue];
    NSInteger total = self.items.count;
    __weak NSArray *weakPaths = paths;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *used = [NSMutableArray new];
        NSError *error = nil;
        while (used.count < weakPaths.count) {
            NSString *item = [[weakPaths objectAtIndex:used.count] lastPathComponent];
            NSString *directoryPath = [[weakPaths objectAtIndex:used.count] stringByDeletingLastPathComponent];
            if (![item hasPrefix:@"."]) {
                NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
                for (int i=0; i<length; i++) {
                    [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
                }
                if ([used containsObject:randomString]) {
                    while ([used containsObject:randomString]) {
                        randomString = nil;
                        NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
                        for (int i=0; i<length; i++) {
                            [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
                        }
                    }
                }
                else {
                    NSString *old_path = [weakPaths objectAtIndex:used.count];
                    NSString *ext = [item pathExtension];
                    NSString *new_path = [[directoryPath stringByAppendingPathComponent:randomString] stringByAppendingPathExtension:ext];
                    [[NSFileManager defaultManager] moveItemAtPath:old_path toPath:new_path error:&error];
                    [used addObject:randomString];
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self.foundLabel setStringValue:[NSString stringWithFormat:@"Found %ld files. Renamed: %ld", total, used.count]];
                        [self setPercentage:@(((float)used.count/(float)paths.count)*100)];
                    });
                }
            }
            else {
                [used addObject:@"error123"];
            }
        }
    });
}

- (void)renameByNumbers:(NSArray*)paths
{
    __weak NSArray *weakPaths = paths;
    NSInteger total = self.items.count;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *used = [NSMutableArray new];
        NSError *error = nil;
        
        while (used.count < weakPaths.count) {
            NSString *item = [[weakPaths objectAtIndex:used.count] lastPathComponent];
            NSString *directoryPath = [[weakPaths objectAtIndex:used.count] stringByDeletingLastPathComponent];
            if (![item hasPrefix:@"."]) {
                int random = arc4random()%(weakPaths.count + 1);
                if ([used containsObject:@(random)]) {
                    while ([used containsObject:@(random)]) {
                        random = arc4random()%(weakPaths.count + 1);
                    }
                }
                else {
                    NSString *old_path = [weakPaths objectAtIndex:used.count];
                    NSString *ext = [item pathExtension];
                    NSString *new_path = [[directoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", random]] stringByAppendingPathExtension:ext];
                    [[NSFileManager defaultManager] moveItemAtPath:old_path toPath:new_path error:&error];
                    [used addObject:@(random)];
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self.foundLabel setStringValue:[NSString stringWithFormat:@"Found %ld files. Renamed: %ld", total, used.count]];
                        [self setPercentage:@(((float)used.count/(float)paths.count)*100)];
                    });
                }
            }
            else {
                [used addObject:@"error123"];
            }
        }
    });
}

- (id)transformedValue:(id)value
{
    
    double convertedValue = [value doubleValue];
    int multiplyFactor = 0;
    
    NSArray *tokens = [NSArray arrayWithObjects:@"bytes",@"KiB",@"MiB",@"GiB",@"TiB",nil];
    
    while (convertedValue > 1024) {
        convertedValue /= 1024;
        multiplyFactor++;
    }
    return [NSString stringWithFormat:@"%4.2f %@",convertedValue, [tokens objectAtIndex:multiplyFactor]];
}

- (unsigned long long)sizeToPerform
{
    unsigned long long totalSize = 0;
    for (NSString *path in self.toPerform) {
        NSError *error = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
        if (!error) {
            totalSize += [attributes fileSize];
        }
    }
    return totalSize;
}

- (NSString*)sizeToPerformString
{
    return [NSString stringWithFormat:@"%@", [self transformedValue:@([self sizeToPerform])]];
}

@end
