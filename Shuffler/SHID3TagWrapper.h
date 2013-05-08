//
//  SHID3TagWrapper.h
//  Shuffler
//
//  Created by Евгений Кратько on 07.05.13.
//  Copyright (c) 2013 Akki. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ID3Tag : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *album;
@property (nonatomic, strong) NSString *artist;
@property (nonatomic, strong) NSNumber *trackNumber;
@property (nonatomic, strong) NSNumber *totalTracks;
@property (nonatomic, strong) NSString *genre;
@property (nonatomic, strong) NSString *year;
@property (nonatomic, strong) NSNumber *approxDuration;
@property (nonatomic, strong) NSString *composer;
@property (nonatomic, strong) NSString *tempo;
@property (nonatomic, strong) NSString *keySignature;
@property (nonatomic, strong) NSString *timeSignature;
@property (nonatomic, strong) NSString *lyricist;
@property (nonatomic, strong) NSString *recordedDate;
@property (nonatomic, strong) NSString *comments;
@property (nonatomic, strong) NSString *copyright;
@property (nonatomic, strong) NSString *sourceEncoder;
@property (nonatomic, strong) NSString *encodingApplication;
@property (nonatomic, strong) NSString *bitRate;
@property (nonatomic, strong) NSStream *sourceBitRate;
@property (nonatomic, strong) NSString *channelLayout;
@property (nonatomic, strong) NSString *isrc;
@property (nonatomic, strong) NSString *subtitle;
@property (nonatomic, strong) NSArray *artworks;
@end

@interface SHID3TagWrapper : NSObject
+ (ID3Tag*)parseAudioForID3:(NSURL*)url;
+ (void)setID3Tag:(ID3Tag*)tag forURL:(NSURL*)url;
@end
