//
//  SHAppDelegate.m
//  Shuffler
//
//  Created by Евгений Кратько on 16.04.13.
//  Copyright (c) 2013 Akki. All rights reserved.
//

#import "SHAppDelegate.h"

@implementation SHAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [self setNameLength:@(5)];
    [self setPercentage:@(0)];
    [self setIncludeSubdirs:NO];
}

- (IBAction)shuffle:(id)sender
{
    //NSURL *pathURL = self.pathControl.URL;
    NSArray *source = self.items;
    [self setPercentage:@(0)];
    switch ([self.radioGroup selectedRow]) {
        case 0: {
            [self renameByNumbers:source];
            break;
        }
        case 1: {
            [self renameByLetters:source];
            break;
        }
        default: break;
    }
}

- (IBAction)loadContent:(id)sender
{
    [self setAllEnabled:NO];
    self.items = nil;
    self.items = [self pathsFrom:[sender URL] includeSub:self.includeSubdirs];
    if (self.items) {
        [self setAllEnabled:YES];
        [self.foundLabel setStringValue:[NSString stringWithFormat:@"Found %ld files.", self.items.count]];
        /*NSString *path = [[sender URL] path];
        FSRef f;
        OSStatus os_status = FSPathMakeRef((const UInt8 *)[path fileSystemRepresentation], &f, NULL);
        if (os_status == noErr) {
            NSLog(@"%1.0f", ((double)[self folderSizeAtFSRef:&f]/1024)/1024);
        }*/
    }
}

- (IBAction)filterSubdirs:(id)sender
{
    [self loadContent:self.pathControl];
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
        _items = [self pathsFrom:[self.pathControl URL] includeSub:self.includeSubdirs];
    }
    return _items;
}

- (NSArray*)pathsFrom:(NSURL*)folderURL includeSub:(BOOL)include
{
    NSMutableArray *result = nil;
    if (include) {
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:folderURL includingPropertiesForKeys:@[NSURLIsDirectoryKey] options:0 errorHandler:^BOOL(NSURL *url, NSError *error){return YES;}];
        for (NSURL *url in enumerator) {
            NSError *error;
            NSNumber *isDirectory = nil;
            if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
                // handle error
            }
            else if (! [isDirectory boolValue]) {
                // No error and it’s not a directory; do something with the file
                BOOL isHidden = NO;
                for (NSString *component in url.pathComponents) {
                    if ([component hasPrefix:@"."]) {
                        isHidden = YES;
                        break;
                    }
                }
                if (!isHidden) {
                    if (!result) result = [NSMutableArray new];
                    [result addObject:url.path];
                }
            }
        }
    }
    else {
        NSError *error = nil;
        NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:folderURL includingPropertiesForKeys:@[NSURLIsDirectoryKey] options:0 error:&error];
        for (NSURL *url in content) {
            NSError *error;
            NSNumber *isDirectory = nil;
            if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
                // handle error
            }
            else if (! [isDirectory boolValue]) {
                BOOL isHidden = NO;
                for (NSString *component in url.pathComponents) {
                    if ([component hasPrefix:@"."]) {
                        isHidden = YES;
                        break;
                    }
                }
                if (!isHidden) {
                    if (!result) result = [NSMutableArray new];
                    [result addObject:url.path];
                }
            }
        }
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
/*
- (unsigned long long)folderSizeAtFSRef:(FSRef*)theFileRef
{
    FSIterator    thisDirEnum = NULL;
    unsigned long long totalSize = 0;
    
    // Iterate the directory contents, recursing as necessary
    if (FSOpenIterator(theFileRef, kFSIterateFlat, &thisDirEnum) == noErr)
    {
        const ItemCount kMaxEntriesPerFetch = 256;
        ItemCount actualFetched;
        FSRef    fetchedRefs[kMaxEntriesPerFetch];
        FSCatalogInfo fetchedInfos[kMaxEntriesPerFetch];
        
        // DCJ Note right now this is only fetching data fork sizes... if we decide to include
        // resource forks we will have to add kFSCatInfoRsrcSizes
            
        OSErr fsErr = FSGetCatalogInfoBulk(thisDirEnum,
                                            kMaxEntriesPerFetch, &actualFetched,
                                            NULL, kFSCatInfoDataSizes |
                                            kFSCatInfoNodeFlags, fetchedInfos,
                                            fetchedRefs, NULL, NULL);
        while ((fsErr == noErr) || (fsErr == errFSNoMoreItems))
        {
            ItemCount thisIndex;
            for (thisIndex = 0; thisIndex < actualFetched; thisIndex++)
            {
                // Recurse if it's a folder
                if (fetchedInfos[thisIndex].nodeFlags &
                    kFSNodeIsDirectoryMask)
                {
                    totalSize += [self folderSizeAtFSRef:&fetchedRefs[thisIndex]];
                }
                else
                {
                    // add the size for this item
                    totalSize += fetchedInfos
                    [thisIndex].dataLogicalSize;
                }
            }
            
            if (fsErr == errFSNoMoreItems)
            {
                break;
            }
            else
            {
                // get more items
                fsErr = FSGetCatalogInfoBulk(thisDirEnum,
                                             kMaxEntriesPerFetch, &actualFetched,
                                             NULL, kFSCatInfoDataSizes |
                                             kFSCatInfoNodeFlags, fetchedInfos,
                                             fetchedRefs, NULL, NULL);
            }
        }
        FSCloseIterator(thisDirEnum);
    }
    return totalSize;
}*/

@end
