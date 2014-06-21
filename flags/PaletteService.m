//
//  PaletteService.m
//  flags
//
//  Created by Chris Patuzzo on 21/06/2014.
//  Copyright (c) 2014 chris. All rights reserved.
//

#import "PaletteService.h"
#import "Utils.h"

@implementation PaletteService

+ (NSArray *)shuffledColors:(NSString *)flagName
{
    NSMutableArray *correct = [self correctColors:flagName];
    NSMutableArray *incorrect = [self incorrectColors:flagName];
    
    NSArray *colors = [correct arrayByAddingObjectsFromArray:incorrect];

    colors = [Utils unique:colors];
    colors = [Utils shuffle:colors];
    
    return colors;
}

+ (NSMutableArray *)correctColors:(NSString *)flagName
{
    NSArray *paths = [Utils pathsFor:flagName];
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    // TODO: deal with duplicate colors for regions
    for (NSString *path in paths) {
        UIColor *color = [self colorFromPath:path];
        if (color) {
            [array addObject:color];
        }
    }
    
    return array;
}

+ (UIColor *)colorFromPath:(NSString *)path
{
    NSString *name = [path lastPathComponent];
    name = [name stringByDeletingPathExtension];
    name = [[name componentsSeparatedByString:@"-"] lastObject];
    
    return [Utils colorWithHexString:name];
}

+ (NSMutableArray *)incorrectColors:(NSString *)flagName
{
    NSDictionary *metadata = [self metadata:flagName];
    NSArray *incorrectColors = [metadata objectForKey:@"incorrectColors"];
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    for (NSString *hex in incorrectColors) {
        [array addObject:[Utils colorWithHexString:hex]];
    }
    
    return array;
}

+ (NSDictionary *)metadata:(NSString *)flagName
{
    NSString *filename = [[NSBundle mainBundle] pathForResource:@"metadata" ofType:@"json" inDirectory:flagName];
    NSData *json = [NSData dataWithContentsOfFile:filename options:NSDataReadingMappedIfSafe error:nil];
    return [NSJSONSerialization JSONObjectWithData:json options:NSJSONReadingMutableContainers error:nil];
}


@end