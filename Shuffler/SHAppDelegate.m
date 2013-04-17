//
//  SHAppDelegate.m
//  Shuffler
//
//  Created by Евгений Кратько on 16.04.13.
//  Copyright (c) 2013 Akki. All rights reserved.
//

#import "SHAppDelegate.h"

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
    }
    switch ([self.radioGroup selectedRow]) {
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

- (IBAction)loadContent:(id)sender
{
    [self setAllEnabled:NO];
    self.items = nil;
    [self setItems:[self pathsFrom:self.pathURL]];
    if (self.items) {
        [self setAllEnabled:YES];
        [self.foundLabel setStringValue:[NSString stringWithFormat:@"Found %ld files.", self.toPerform.count]];
        [self.totalSizeLabel setStringValue:[self sizeToPerformString]];
    }
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

- (NSArray *)items
{
    if (!_items) {
        _items = [self pathsFrom:self.pathURL];
        needReload = NO;
    }
    return _items;
}

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

- (NSArray*)pathsFrom:(NSURL*)folderURL
{
    NSMutableArray *result = nil;
    [self setPercentage:nil];
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:folderURL includingPropertiesForKeys:@[NSURLIsDirectoryKey] options:0 errorHandler:^BOOL(NSURL *url, NSError *error){return YES;}];
    NSEnumerator *testEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:folderURL includingPropertiesForKeys:@[NSURLIsDirectoryKey] options:0 errorHandler:^BOOL(NSURL *url, NSError *error){return YES;}];;
    NSArray *arr = [testEnumerator allObjects];
    NSUInteger allCount = [arr count];
    testEnumerator = nil;
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
            }
        }
        [self setPercentage:@(((float)result.count/(float)allCount)*100)];
    }
    return result;
}

- (void)renameByLetters:(NSArray*)paths
{
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSMutableArray *used = [NSMutableArray new];
    NSInteger length = [self.nameLength integerValue];
    NSError *error = nil;
    
    NSInteger total = self.items.count;
    
    while (used.count < paths.count) {
        NSString *item = [[paths objectAtIndex:used.count] lastPathComponent];
        NSString *directoryPath = [[paths objectAtIndex:used.count] stringByDeletingLastPathComponent];
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
                NSString *old_path = [paths objectAtIndex:used.count];
                NSString *ext = [item pathExtension];
                NSString *new_path = [[directoryPath stringByAppendingPathComponent:randomString] stringByAppendingPathExtension:ext];
                [[NSFileManager defaultManager] moveItemAtPath:old_path toPath:new_path error:&error];
                [used addObject:randomString];
                [self.foundLabel setStringValue:[NSString stringWithFormat:@"Found %ld files. Renamed: %ld", total, used.count]];
                [self setPercentage:@(((float)used.count/(float)paths.count)*100)];
            }
        }
        else {
            [used addObject:@"error123"];
        }
    }
}

- (void)renameByNumbers:(NSArray*)paths
{
    NSMutableArray *used = [NSMutableArray new];
    NSError *error = nil;
    
    NSInteger total = self.items.count;
    
    while (used.count < paths.count) {
        NSString *item = [[paths objectAtIndex:used.count] lastPathComponent];
        NSString *directoryPath = [[paths objectAtIndex:used.count] stringByDeletingLastPathComponent];
        if (![item hasPrefix:@"."]) {
            int random = arc4random()%(paths.count + 1);
            if ([used containsObject:@(random)]) {
                while ([used containsObject:@(random)]) {
                    random = arc4random()%(paths.count + 1);
                }
            }
            else {
                NSString *old_path = [paths objectAtIndex:used.count];
                NSString *ext = [item pathExtension];
                NSString *new_path = [[directoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", random]] stringByAppendingPathExtension:ext];
                [[NSFileManager defaultManager] moveItemAtPath:old_path toPath:new_path error:&error];
                [used addObject:@(random)];
                [self.foundLabel setStringValue:[NSString stringWithFormat:@"Found %ld files. Renamed: %ld", total, used.count]];
                [self setPercentage:@(((float)used.count/(float)paths.count)*100)];
            }
        }
        else {
            [used addObject:@"error123"];
        }
    }
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
