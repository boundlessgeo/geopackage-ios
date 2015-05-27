//
//  GPKGFeatureRow.h
//  geopackage-ios
//
//  Created by Brian Osborn on 5/26/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGUserRow.h"
#import "GPKGFeatureTable.h"
#import "GPKGGeometryData.h"

@interface GPKGFeatureRow : GPKGUserRow

@property (nonatomic, strong) GPKGFeatureTable *featureTable;

-(instancetype) initWithFeatureTable: (GPKGFeatureTable *) table andColumnTypes: (NSArray *) columnTypes andValues: (NSMutableArray *) values;

-(int) getGeometryColumnIndex;

-(GPKGFeatureColumn *) getGeometryColumn;

-(GPKGGeometryData *) getGeometry;

-(void) setGeometry: (GPKGGeometryData *) geometryData;

@end