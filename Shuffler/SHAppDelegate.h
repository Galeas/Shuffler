//
//  SHAppDelegate.h
//  Shuffler
//
//  Created by Евгений Кратько on 16.04.13.
//  Copyright (c) 2013 Akki. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SHAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSPathControl *pathControl;
@property (weak) IBOutlet NSMatrix *radioGroup;
@property (weak) IBOutlet NSTextField *foundLabel;

@property (weak) id nameLength;
@property (assign) BOOL stringSelected;
@property (weak) id percentage;
@property (assign) BOOL includeSubdirs;
@property (weak) NSURL *pathURL;

@property (strong, nonatomic) NSArray *items;

- (IBAction)shuffle:(id)sender;
- (IBAction)loadContent:(id)sender;
- (IBAction)filterSubdirs:(id)sender;

@end
