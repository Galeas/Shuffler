//
//  SHID3TagWrapper.m
//  Shuffler
//
//  Created by Евгений Кратько on 07.05.13.
//  Copyright (c) 2013 Akki. All rights reserved.
//

#import "SHID3TagWrapper.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@implementation ID3Tag

@end

@implementation SHID3TagWrapper

+ (ID3Tag *)parseAudioForID3:(NSURL *)url
{
    if (!url) {
        return nil;
    }
    
    AudioFileID fileID = NULL;
    OSStatus status = noErr;
    
    status = AudioFileOpenURL((__bridge CFURLRef)url, kAudioFileReadPermission, 0, &fileID);
    if (status != noErr) {
        NSLog(@"Audio open failed");
        return nil;
    }
    else {
        UInt32 id3DataSize = 0;
        char* rawID3Tag = NULL;
        
        //  Reads in the raw ID3 tag info
        status = AudioFileGetPropertyInfo(fileID, kAudioFilePropertyID3Tag, &id3DataSize, NULL);
        if(status != noErr) {
            return nil;
        }
        
        //  Allocate the raw tag data
        rawID3Tag = (char *) malloc(id3DataSize);
        
        if(rawID3Tag == NULL) {
            return nil;
        }
        
        status = AudioFileGetProperty(fileID, kAudioFilePropertyID3Tag, &id3DataSize, rawID3Tag);
        if(status != noErr) {
            free(rawID3Tag);
            return nil;
        }
        
        UInt32 id3TagSize = 0;
        UInt32 id3TagSizeLength = 0;
        status = AudioFormatGetProperty(kAudioFormatProperty_ID3TagSize, id3DataSize, rawID3Tag, &id3TagSizeLength, &id3TagSize);
        
        if(status != noErr) {
            switch(status) {
                case kAudioFormatUnspecifiedError:
                    NSLog(@"status: audio format unspecified error");
                    free(rawID3Tag);
                    return nil;
                case kAudioFormatUnsupportedPropertyError:
                    NSLog(@"status: audio format unsupported property error");
                    free(rawID3Tag);
                    return nil;
                case kAudioFormatBadPropertySizeError:
                    NSLog(@"status: audio format bad property size error");
                    free(rawID3Tag);
                    return nil;
                case kAudioFormatBadSpecifierSizeError:
                    NSLog(@"status: audio format bad specifier size error");
                    free(rawID3Tag);
                    return nil;
                case kAudioFormatUnsupportedDataFormatError:
                    NSLog(@"status: audio format unsupported data format error");
                    free(rawID3Tag);
                    return nil;
                case kAudioFormatUnknownFormatError:
                    NSLog(@"status: audio format unknown format error");
                    free(rawID3Tag);
                    return nil;
                default:
                    NSLog(@"status: some other audio format error");
                    free(rawID3Tag);
                    return nil;
            }
        }
        
        CFDictionaryRef piDict = nil;
        UInt32 piDataSize = sizeof(piDict);
        
        //  Populates a CFDictionary with the ID3 tag properties
        status = AudioFileGetProperty(fileID, kAudioFilePropertyInfoDictionary, &piDataSize, &piDict);
        if(status != noErr) {
            NSLog(@"AudioFileGetProperty failed for property info dictionary");
            free(rawID3Tag);
            return nil;
        }
        
        //  Toll free bridge the CFDictionary so that we can interact with it via objc
        
        NSDictionary* nsDict = (__bridge NSDictionary*)piDict;
        
        ID3Tag* tag = [[ID3Tag alloc] init];
        
        tag.album = [nsDict objectForKey:[NSString stringWithUTF8String: kAFInfoDictionary_Album]];
        tag.approxDuration = [NSNumber numberWithInt:[[nsDict objectForKey:[NSString stringWithUTF8String: kAFInfoDictionary_ApproximateDurationInSeconds]] intValue]];
        tag.artist = [nsDict objectForKey:[NSString stringWithUTF8String: kAFInfoDictionary_Artist]];
        tag.bitRate = [nsDict objectForKey:[NSString stringWithUTF8String: kAFInfoDictionary_NominalBitRate]];
        tag.channelLayout = [nsDict objectForKey:[NSString stringWithUTF8String: kAFInfoDictionary_ChannelLayout]];
        tag.comments = [nsDict objectForKey:[NSString stringWithUTF8String: kAFInfoDictionary_Comments]];
        tag.composer = [nsDict objectForKey:[NSString stringWithUTF8String: kAFInfoDictionary_Composer]];
        tag.copyright = [nsDict objectForKey:[NSString stringWithUTF8String: kAFInfoDictionary_Copyright]];
        tag.encodingApplication = [nsDict objectForKey:[NSString stringWithUTF8String: kAFInfoDictionary_EncodingApplication]];
        tag.genre = [nsDict objectForKey:[NSString stringWithUTF8String: kAFInfoDictionary_Genre]];
        tag.isrc = [nsDict objectForKey:[NSString stringWithUTF8String: kAFInfoDictionary_ISRC]];
        tag.keySignature = [nsDict objectForKey:[NSString stringWithUTF8String: kAFInfoDictionary_KeySignature]];
        tag.lyricist = [nsDict objectForKey:[NSString stringWithUTF8String: kAFInfoDictionary_Lyricist]];
        tag.recordedDate = [nsDict objectForKey:[NSString stringWithUTF8String: kAFInfoDictionary_RecordedDate]];
        tag.sourceBitRate = [nsDict objectForKey:[NSString stringWithUTF8String: kAFInfoDictionary_SourceBitDepth]];
        tag.sourceEncoder = [nsDict objectForKey:[NSString stringWithUTF8String: kAFInfoDictionary_SourceEncoder]];
        tag.subtitle = [nsDict objectForKey:[NSString stringWithUTF8String: kAFInfoDictionary_SubTitle]];
        tag.tempo = [nsDict objectForKey:[NSString stringWithUTF8String: kAFInfoDictionary_Tempo]];
        tag.timeSignature = [nsDict objectForKey:[NSString stringWithUTF8String: kAFInfoDictionary_TimeSignature]];
        tag.title = [nsDict objectForKey:[NSString stringWithUTF8String: kAFInfoDictionary_Title]];
        tag.year = [nsDict objectForKey:[NSString stringWithUTF8String: kAFInfoDictionary_Year]];
        
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
        NSArray *buffer = [AVMetadataItem metadataItemsFromArray:asset.commonMetadata withKey:AVMetadataCommonKeyArtwork keySpace:AVMetadataKeySpaceCommon];
        NSMutableArray *images = [NSMutableArray new];
        for (AVMetadataItem *item in buffer) {
            NSString *keyspace = item.keySpace;
#ifndef UI_USER_INTERFACE_IDIOM
            NSImage *image = nil;
#else
            UIImage *image = nil;
#endif
            if ([keyspace isEqualToString:AVMetadataKeySpaceID3]) {
                NSDictionary *metadata = [item.value copyWithZone:nil];
#ifndef UI_USER_INTERFACE_IDIOM
                image = [[NSImage alloc] initWithData:[metadata objectForKey:@"data"]];
#else
                image = [UIImage imageWithData:[d objectForKey:@"data"]];
#endif
            }
            else if ([keyspace isEqualToString:AVMetadataKeySpaceiTunes]) {
#ifndef UI_USER_INTERFACE_IDIOM
                image = [[NSImage alloc] initWithData:[item.value copyWithZone:nil]];
#else
                image = [UIImage imageWithData:[i.value copyWithZone:nil]];
#endif
            }
            if (image) {
                [images addObject:image];
            }
        }
        tag.artworks = (NSArray*)images;
        
        /*
         *  We're going to parse tracks differently so that we can perform queries on the data. This means we need to look
         *  for a '/' so that we can seperate out the track from the total tracks on the source compilation (if it's there).
         */
        NSString* tracks = [nsDict objectForKey:[NSString stringWithUTF8String: kAFInfoDictionary_TrackNumber]];
        
        NSUInteger slashLocation = [tracks rangeOfString:@"/"].location;
        
        if (slashLocation == NSNotFound) {
            tag.trackNumber = [NSNumber numberWithInt:[tracks intValue]];
        } else {
            tag.trackNumber = [NSNumber numberWithInt:[[tracks substringToIndex:slashLocation] intValue]];
            tag.totalTracks = [NSNumber numberWithInt:[[tracks substringFromIndex:(slashLocation+1 < [tracks length] ? slashLocation+1 : 0 )] intValue]];
        }
        
        //  ALWAYS CLEAN UP!
        CFRelease(piDict);
        nsDict = nil;
        free(rawID3Tag);
        
        return tag;
    }
}

+ (void)setID3Tag:(ID3Tag *)tag forURL:(NSURL *)url
{
    if (!url) {
        return;
    }
    
    AudioFileID fileID = NULL;
    OSStatus status = noErr;
    
    status = AudioFileOpenURL((__bridge CFURLRef)url, kAudioFileWritePermission, 0, &fileID);
    if (status != noErr) {
        NSLog(@"Audio open failed");
        return;
    }
    else {
        //AudioFileSetProperty(fileID, AudioFilePropertyID inPropertyID, <#UInt32 inDataSize#>, <#const void *inPropertyData#>)
        AVURLAsset *asset = [AVURLAsset assetWithURL:url];
        
    }
}

@end
