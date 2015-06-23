//
//  GPKGMapPoint.m
//  geopackage-ios
//
//  Created by Brian Osborn on 6/22/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGMapPoint.h"

@implementation GPKGMapPoint

static NSUInteger idCounter = 0;

- (id)initWithLocation: (CLLocationCoordinate2D) coord {
    self = [super init];
    if (self) {
        self.coordinate = coord;
        self.id = idCounter++;
    }
    return self;
}

- (id)initWithLatitude: (double) latitude andLongitude: (double) longitude {
    CLLocationCoordinate2D theCoordinate = CLLocationCoordinate2DMake(latitude, longitude);
    return [self initWithLocation:theCoordinate];
}

- (id)initWithPoint: (WKBPoint *) point {
    return [self initWithLatitude:[point.y doubleValue] andLongitude:[point.x doubleValue]];
}

@end
