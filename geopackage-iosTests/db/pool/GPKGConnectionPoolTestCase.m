//
//  GPKGConnectionPoolTestCase.m
//  geopackage-ios
//
//  Created by Brian Osborn on 10/27/15.
//  Copyright © 2015 NGA. All rights reserved.
//

#import "GPKGConnectionPoolTestCase.h"
#import "GPKGTestUtils.h"
#import "GPKGProjectionConstants.h"

@implementation GPKGConnectionPoolTestCase

- (void)testNestedQuery {

  NSArray *featureTables = [self.geoPackage getFeatureTables];
  for (NSString *featureTable in featureTables) {

    GPKGFeatureDao *featureDao =
        [self.geoPackage getFeatureDaoWithTableName:featureTable];
    GPKGResultSet *featureResults = [featureDao queryForAll];
    NSNumber *connectionId1 = [featureResults.connection getConnectionId];

    while ([featureResults moveToNext]) {

      GPKGFeatureRow *featureRow = [featureDao getFeatureRow:featureResults];
      [GPKGTestUtils assertNotNil:featureRow];

      NSArray *tileTables = [self.geoPackage getTileTables];
      for (NSString *tileTable in tileTables) {

        GPKGTileDao *tileDao =
            [self.geoPackage getTileDaoWithTableName:tileTable];
        GPKGResultSet *tileResults = [tileDao queryForAll];
        NSNumber *connectionId2 = [tileResults.connection getConnectionId];

        [GPKGTestUtils
            assertFalse:[connectionId1 intValue] == [connectionId2 intValue]];

        while ([tileResults moveToNext]) {

          GPKGTileRow *tileRow = [tileDao getTileRow:tileResults];
          [GPKGTestUtils assertNotNil:tileRow];
        }

        [tileResults close];
      }
    }

    [featureResults close];
  }
}

- (void)testMultiThreadedQuery {

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                 ^{

                   NSArray *tileTables = [self.geoPackage getTileTables];
                   for (NSString *tileTable in tileTables) {

                     GPKGTileDao *tileDao =
                         [self.geoPackage getTileDaoWithTableName:tileTable];
                     GPKGResultSet *tileResults = [tileDao queryForAll];

                     while ([tileResults moveToNext]) {

                       GPKGTileRow *tileRow = [tileDao getTileRow:tileResults];
                       [GPKGTestUtils assertNotNil:tileRow];

                       [NSThread sleepForTimeInterval:.1];
                     }

                     [tileResults close];
                   }

                 });

  NSArray *featureTables = [self.geoPackage getFeatureTables];
  for (NSString *featureTable in featureTables) {

    GPKGFeatureDao *featureDao =
        [self.geoPackage getFeatureDaoWithTableName:featureTable];
    GPKGResultSet *featureResults = [featureDao queryForAll];

    while ([featureResults moveToNext]) {

      GPKGFeatureRow *featureRow = [featureDao getFeatureRow:featureResults];
      [GPKGTestUtils assertNotNil:featureRow];

      [NSThread sleepForTimeInterval:.1];
    }

    [featureResults close];
  }
}

- (void)testNestedUpdate {

  NSArray *featureTables = [self.geoPackage getFeatureTables];
  for (NSString *featureTable in featureTables) {

    GPKGFeatureDao *featureDao =
        [self.geoPackage getFeatureDaoWithTableName:featureTable];
    GPKGResultSet *featureResults = [featureDao queryForAll];

    while ([featureResults moveToNext]) {

      GPKGFeatureRow *featureRow = [featureDao getFeatureRow:featureResults];
      [GPKGTestUtils assertNotNil:featureRow];

      GPKGGeometryData *geomData = [[GPKGGeometryData alloc]
          initWithSrsId:[NSNumber
                            numberWithInt:PROJ_EPSG_WORLD_GEODETIC_SYSTEM]];
      [geomData
          setGeometry:
              [[WKBPoint alloc]
                  initWithX:[[NSDecimalNumber alloc] initWithDouble:45.1]
                       andY:[[NSDecimalNumber alloc] initWithDouble:23.2]]];
      [featureRow setGeometry:geomData];

      int updated = [featureDao update:featureRow];
      [GPKGTestUtils assertEqualIntWithValue:1 andValue2:updated];
    }

    [featureResults close];
  }
}

/**
 *  When multiple result connections are open, updates are not possible due to a
 * database lock
 */
- (void)testNestedQueryAndUpdateFailure {

  NSArray *featureTables = [self.geoPackage getFeatureTables];
  for (NSString *featureTable in featureTables) {

    GPKGFeatureDao *featureDao =
        [self.geoPackage getFeatureDaoWithTableName:featureTable];
    GPKGResultSet *featureResults = [featureDao queryForAll];
    NSNumber *connectionId1 = [featureResults.connection getConnectionId];

    while ([featureResults moveToNext]) {

      GPKGFeatureRow *featureRow = [featureDao getFeatureRow:featureResults];
      [GPKGTestUtils assertNotNil:featureRow];

      NSArray *tileTables = [self.geoPackage getTileTables];
      for (NSString *tileTable in tileTables) {

        GPKGTileDao *tileDao =
            [self.geoPackage getTileDaoWithTableName:tileTable];
        GPKGResultSet *tileResults = [tileDao queryForAll];
        NSNumber *connectionId2 = [tileResults.connection getConnectionId];

        [GPKGTestUtils
            assertFalse:[connectionId1 intValue] == [connectionId2 intValue]];

        while ([tileResults moveToNext]) {

          GPKGTileRow *tileRow = [tileDao getTileRow:tileResults];
          [GPKGTestUtils assertNotNil:tileRow];

          NSString *string = @"garbage";
          NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
          [tileRow setTileData:data];

          @try {
            [tileDao update:tileRow];
            [NSException
                 raise:@"Unexpected Success"
                format:@"Did not encounter expected failure, updating the "
                       @"database with multiple open result connections"];
          } @catch (NSException *exception) {
            // Expected failure
          }
        }

        [tileResults close];
      }
    }

    [featureResults close];
  }
}


- (void)testTransactionUpdateCommit {
    
    NSArray * featureTables = [self.geoPackage getFeatureTables];
    for(NSString * featureTable in featureTables){
        
        GPKGFeatureDao * featureDao = [self.geoPackage getFeatureDaoWithTableName:featureTable];
        
        [featureDao beginTransaction];
        
        int updated = [self transactionUpdateHelperWithFeatureDao:featureDao];
        
        [featureDao commitTransaction];
        
        // Validate updates
        int checked = [self transactionUpdateValidatorWithFeatureDao:featureDao andUpdated:true];
        
        [GPKGTestUtils assertEqualIntWithValue:updated andValue2:checked];
    }
}

- (void)testTransactionUpdateRollback {
    
    NSArray * featureTables = [self.geoPackage getFeatureTables];
    for(NSString * featureTable in featureTables){
        
        GPKGFeatureDao * featureDao = [self.geoPackage getFeatureDaoWithTableName:featureTable];
        
        [featureDao beginTransaction];
        
        int updated = [self transactionUpdateHelperWithFeatureDao:featureDao];
        
        [featureDao rollbackTransaction];
        
        // Validate rollback
        int checked = [self transactionUpdateValidatorWithFeatureDao:featureDao andUpdated:false];
        
        [GPKGTestUtils assertEqualIntWithValue:updated andValue2:checked];
    }
}

- (void)testQueryTransactionUpdateCommit {
    
    NSArray * featureTables = [self.geoPackage getFeatureTables];
    for(NSString * featureTable in featureTables){
        
        GPKGFeatureDao * featureDao = [self.geoPackage getFeatureDaoWithTableName:featureTable];
        
        GPKGResultSet * featureResults = [featureDao queryForAll];
        
        while([featureResults moveToNext]){
        
            [featureDao beginTransaction];
            
            int updated = [self transactionUpdateHelperWithFeatureDao:featureDao];
            
            [featureDao commitTransaction];
            
            // Validate updates
            int checked = [self transactionUpdateValidatorWithFeatureDao:featureDao andUpdated:true];
            
            [GPKGTestUtils assertEqualIntWithValue:updated andValue2:checked];
        }
        
        [featureResults close];
    }
}

- (void)testQueryTransactionUpdateRollback {
    
    NSArray * featureTables = [self.geoPackage getFeatureTables];
    for(NSString * featureTable in featureTables){
        
        GPKGFeatureDao * featureDao = [self.geoPackage getFeatureDaoWithTableName:featureTable];
        
        GPKGResultSet * featureResults = [featureDao queryForAll];
        
        while([featureResults moveToNext]){
            
            [featureDao beginTransaction];
            
            int updated = [self transactionUpdateHelperWithFeatureDao:featureDao];
            
            [featureDao rollbackTransaction];
            
            // Validate rollback
            int checked = [self transactionUpdateValidatorWithFeatureDao:featureDao andUpdated:false];
            
            [GPKGTestUtils assertEqualIntWithValue:updated andValue2:checked];
        }
        
        [featureResults close];
    }
}

- (void)testTransactionChunkUpdateCommit {
    
    NSArray * featureTables = [self.geoPackage getFeatureTables];
    for(NSString * featureTable in featureTables){
        
        GPKGFeatureDao * featureDao = [self.geoPackage getFeatureDaoWithTableName:featureTable];
        
        int updated = [self transactionChunkUpdateHelperWithFeatureDao:featureDao andCommit:true];
        
        // Validate updates
        int checked = [self transactionUpdateValidatorWithFeatureDao:featureDao andUpdated:true];
        
        [GPKGTestUtils assertEqualIntWithValue:updated andValue2:checked];
    }
}

- (void)testTransactionChunkUpdateRollback {
    
    NSArray * featureTables = [self.geoPackage getFeatureTables];
    for(NSString * featureTable in featureTables){
        
        GPKGFeatureDao * featureDao = [self.geoPackage getFeatureDaoWithTableName:featureTable];
        
        int updated = [self transactionChunkUpdateHelperWithFeatureDao:featureDao andCommit:false];
        
        // Validate updates
        int checked = [self transactionUpdateValidatorWithFeatureDao:featureDao andUpdated:false];
        
        [GPKGTestUtils assertEqualIntWithValue:updated andValue2:checked];
    }
}

- (int)transactionUpdateHelperWithFeatureDao: (GPKGFeatureDao *) featureDao{
    
    int totalUpdated = 0;
    
    GPKGResultSet * featureResults = [featureDao queryForAll];
    
    while([featureResults moveToNext]){
        GPKGFeatureRow * featureRow = [featureDao getFeatureRow:featureResults];
        totalUpdated += [self transactionUpdateHelperWithFeatureDao:featureDao andFeatureRow:featureRow];
    }
    
    [GPKGTestUtils assertEqualIntWithValue:featureResults.count andValue2:[featureDao count]];
    
    [featureResults close];
    
    [GPKGTestUtils assertEqualIntWithValue:featureResults.count andValue2:totalUpdated];
    
    return totalUpdated;
    
}

- (int)transactionChunkUpdateHelperWithFeatureDao: (GPKGFeatureDao *) featureDao andCommit: (BOOL) commit{
    
    int totalUpdated = 0;
    
    GPKGResultSet * featureResults = [featureDao queryForAll];
    
    int count = 0;
    
    while([featureResults moveToNext]){
        if(count == 0){
            [featureDao beginTransaction];
        }
        GPKGFeatureRow * featureRow = [featureDao getFeatureRow:featureResults];
        count = [self transactionUpdateHelperWithFeatureDao:featureDao andFeatureRow:featureRow];
        totalUpdated += count;
        if(count >= 2){
            if(commit){
                [featureDao commitTransaction];
            }else{
                [featureDao rollbackTransaction];
            }
            count = 0;
        }
    }
    if(count > 0){
        if(commit){
            [featureDao commitTransaction];
        }else{
            [featureDao rollbackTransaction];
        }
    }
    
    [GPKGTestUtils assertEqualIntWithValue:featureResults.count andValue2:[featureDao count]];
    
    [featureResults close];
    
    [GPKGTestUtils assertEqualIntWithValue:featureResults.count andValue2:totalUpdated];
    
    return totalUpdated;
}

- (int)transactionUpdateHelperWithFeatureDao: (GPKGFeatureDao *) featureDao andFeatureRow: (GPKGFeatureRow *) featureRow{
    [GPKGTestUtils assertNotNil:featureRow];
    
    GPKGGeometryData * geomData = [[GPKGGeometryData alloc] initWithSrsId:[NSNumber numberWithInt:PROJ_EPSG_WORLD_GEODETIC_SYSTEM]];
    [geomData setGeometry:[[WKBPoint alloc] initWithX:[[NSDecimalNumber alloc] initWithDouble:45.1] andY:[[NSDecimalNumber alloc] initWithDouble:23.2]]];
    [featureRow setGeometry:geomData];
    
    int updated = [featureDao update:featureRow];
    [GPKGTestUtils assertEqualIntWithValue:1 andValue2:updated];
    return updated;
}

- (int)transactionUpdateValidatorWithFeatureDao: (GPKGFeatureDao *) featureDao andUpdated: (BOOL) updated{
    
    int totalChecked = 0;
    
    GPKGResultSet * featureResults = [featureDao queryForAll];
    
    while([featureResults moveToNext]){
        
        GPKGFeatureRow * featureRow = [featureDao getFeatureRow:featureResults];
        [self transactionUpdateValidatorWithFeatureDao:featureDao andUpdated:updated andFeatureRow:featureRow];
        totalChecked++;
    }
    
    [GPKGTestUtils assertEqualIntWithValue:featureResults.count andValue2:[featureDao count]];
    
    [featureResults close];
    
    [GPKGTestUtils assertEqualIntWithValue:featureResults.count andValue2:totalChecked];
    
    return totalChecked;
}

- (void)transactionUpdateValidatorWithFeatureDao: (GPKGFeatureDao *) featureDao andUpdated: (BOOL) updated andFeatureRow: (GPKGFeatureRow *) featureRow{
    if(updated){
        [GPKGTestUtils assertNotNil:featureRow];
        
        GPKGGeometryData * geomData = [featureRow getGeometry];
        [GPKGTestUtils assertNotNil:geomData];
        
        WKBGeometry * geometry = geomData.geometry;
        [GPKGTestUtils assertNotNil:geometry];
        
        enum WKBGeometryType geometryType = geometry.geometryType;
        [GPKGTestUtils assertEqualWithValue:[WKBGeometryTypes name:WKB_POINT] andValue2:[WKBGeometryTypes name:geometryType]];
        
        WKBPoint * point = (WKBPoint *) geometry;
        [GPKGTestUtils assertNotNil:point];
        
        [GPKGTestUtils assertEqualDoubleWithValue:45.1 andValue2:[point.x doubleValue]];
        [GPKGTestUtils assertEqualDoubleWithValue:23.2 andValue2:[point.y doubleValue]];
        
    } else {
        if(featureRow != nil){
            GPKGGeometryData * geomData = [featureRow getGeometry];
            if(geomData != nil){
                WKBGeometry * geometry = geomData.geometry;
                if(geometry != nil){
                    enum WKBGeometryType geometryType = geometry.geometryType;
                    if([WKBGeometryTypes name:WKB_POINT] == [WKBGeometryTypes name:geometryType]){
                        WKBPoint * point = (WKBPoint *) geometry;
                        if(point != nil){
                            if([point.x doubleValue] == 45.1 && [point.y doubleValue] == 23.2){
                                [NSException raise:@"Rollback Failed" format:@"Rollback failed and update was made"];
                            }
                        }
                    }
                }
            }
        }
    }
}

@end
