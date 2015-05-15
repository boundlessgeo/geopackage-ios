//
//  GPKGSpatialReferenceSystemDao.m
//  geopackage-ios
//
//  Created by Brian Osborn on 5/15/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSpatialReferenceSystemDao.h"
#import "GPKGProjectionConstants.h"
#import "GPKGGeometryColumnsDao.h"

@implementation GPKGSpatialReferenceSystemDao

-(instancetype) initWithDatabase: (GPKGConnection *) database{
    self = [super initWithDatabase:database];
    if(self != nil){
        self.tableName = SRS_TABLE_NAME;
        self.idColumns = @[SRS_COLUMN_SRS_ID];
        self.columns = @[SRS_COLUMN_SRS_NAME, SRS_COLUMN_SRS_ID, SRS_COLUMN_ORGANIZATION, SRS_COLUMN_ORGANIZATION_COORDSYS_ID, SRS_COLUMN_DEFINITION, SRS_COLUMN_DESCRIPTION];
        [self initializeColumnIndex];
    }
    return self;
}

-(NSObject *) createObject{
    return [[GPKGSpatialReferenceSystem alloc] init];
}

-(void) setValueInObject: (NSObject*) object withColumnIndex: (int) columnIndex withValue: (NSObject *) value{
    
    GPKGSpatialReferenceSystem *setObject = (GPKGSpatialReferenceSystem*) object;
    
    switch(columnIndex){
        case 1:
            setObject.srsName = (NSString *) value;
            break;
        case 2:
            setObject.srsId = (NSNumber *) value;
            break;
        case 3:
            setObject.organization = (NSString *) value;
            break;
        case 4:
            setObject.organizationCoordsysId = (NSNumber *) value;
            break;
        case 5:
            setObject.definition = (NSString *) value;
            break;
        case 6:
            setObject.srsDescription = (NSString *) value;
            break;
        default:
            [NSException raise:@"Illegal Column Index" format:@"Unsupported column index: %d", columnIndex];
            break;
    }
    
}

-(NSObject *) getValueFromObject: (NSObject*) object withColumnIndex: (int) columnIndex{
    
    NSObject * value = nil;
    
    GPKGSpatialReferenceSystem *getObject = (GPKGSpatialReferenceSystem*) object;
    
    switch(columnIndex){
        case 1:
            value = getObject.srsName;
            break;
        case 2:
            value = getObject.srsId;
            break;
        case 3:
            value = getObject.organization;
            break;
        case 4:
            value = getObject.organizationCoordsysId;
            break;
        case 5:
            value = getObject.definition;
            break;
        case 6:
            value = getObject.srsDescription;
            break;
        default:
            [NSException raise:@"Illegal Column Index" format:@"Unsupported column index: %d", columnIndex];
            break;
    }
    
    return value;
}

-(GPKGSpatialReferenceSystem *) createWgs84{
    
    GPKGSpatialReferenceSystem * srs = [[GPKGSpatialReferenceSystem alloc] init];
    
    [self create:srs];
    
    return srs;
}

-(GPKGSpatialReferenceSystem *) createUndefinedCartesian{
    
    GPKGSpatialReferenceSystem * srs = [[GPKGSpatialReferenceSystem alloc] init];
    
    [self create:srs];
    
    return srs;
}

-(GPKGSpatialReferenceSystem *) createUndefinedGeographic{
    
    GPKGSpatialReferenceSystem * srs = [[GPKGSpatialReferenceSystem alloc] init];
    
    [self create:srs];
    
    return srs;
}

-(GPKGSpatialReferenceSystem *) createWebMercator{
    
    GPKGSpatialReferenceSystem * srs = [[GPKGSpatialReferenceSystem alloc] init];
    
    [self create:srs];
    
    return srs;
}

-(GPKGSpatialReferenceSystem *) getOrCreateWithSrsId: (NSNumber*) srsId{
    
    GPKGSpatialReferenceSystem * srs = (GPKGSpatialReferenceSystem *) [self queryForIdObject:srsId];
    
    if(srs == nil){
        
        long id = [srsId integerValue];
        
        if(id == PROJ_EPSG_WORLD_GEODETIC_SYSTEM){
            srs = [self createWgs84];
        } else if(id == PROJ_UNDEFINED_CARTESIAN){
            srs = [self createUndefinedCartesian];
        } else if(id == PROJ_UNDEFINED_GEOGRAPHIC){
            srs = [self createUndefinedGeographic];
        } else if(id == PROJ_EPSG_WEB_MERCATOR){
            srs = [self createWebMercator];
        } else{
            [NSException raise:@"SRS Not Support" format:@"Spatial Reference System not supported for metadata creation: %@", srsId];
        }
        
    }
    
    return srs;
}

-(int) deleteCascade: (GPKGSpatialReferenceSystem *) srs{
    
    int count = 0;
    
    if(srs != nil){
        
        // Delete contents
        //TODO
        
        // Delete Geometry Columns
        GPKGGeometryColumnsDao * geometryColumnsDao = [self getGeometryColumnsDao];
        if([geometryColumnsDao isTableExists]){
            GPKGResultSet * geometryColumns = [self getGeometryColumns:srs];
            while([geometryColumns moveToNext]){
                GPKGGeometryColumns * geometryColumn = (GPKGGeometryColumns *) [geometryColumnsDao getObject:geometryColumns];
                [geometryColumnsDao delete:geometryColumn];
            }
            [geometryColumns close];
        }
        
        // Delete Tile Matrix Set
        //TODO
        
        // Delete
        count = [self delete:srs];
    }

    return count;
}

-(int) deleteCascadeWithCollection: (NSArray *) srsCollection{
    int count = 0;
    if(srsCollection != nil){
        for(GPKGSpatialReferenceSystem *srs in srsCollection){
            count += [self deleteCascade:srs];
        }
    }
    return count;
}

-(int) deleteCascadeWhere: (NSString *) where{
    int count = 0;
    if(where != nil){
        GPKGResultSet *results = [self queryWhere:where];
        while([results moveToNext]){
            GPKGSpatialReferenceSystem *srs = (GPKGSpatialReferenceSystem *)[self getObject:results];
            count += [self deleteCascade:srs];
        }
        [results close];
    }
    return count;
}

-(int) deleteByIdCascade: (NSNumber *) id{
    int count = 0;
    if(id != nil){
        GPKGSpatialReferenceSystem *srs = (GPKGSpatialReferenceSystem *) [self queryForIdObject:id];
        if(srs != nil){
            count = [self deleteCascade:srs];
        }
    }
    return count;
}

-(int) deleteIdsCascade: (NSArray *) idCollection{
    int count = 0;
    if(idCollection != nil){
        for(NSNumber * id in idCollection){
            count += [self deleteByIdCascade:id];
        }
    }
    return count;
}

//TODO
//-(GPKGContents *) getContents: (GPKGSpatialReferenceSystem *) srs{
//
//}

-(GPKGResultSet *) getGeometryColumns: (GPKGSpatialReferenceSystem *) srs{
    GPKGGeometryColumnsDao * dao = [self getGeometryColumnsDao];
    GPKGResultSet * results = [dao queryForEqWithField:GC_COLUMN_SRS_ID andValue:srs.srsId];
    return results;
}

//TODO
//-(GPKGTileMatrixSet *) getTileMatrixSet: (GPKGSpatialReferenceSystem *) srs{
//
//}

//TODO
//-(GPKGContentsDao *) getContentsDao{
//    return [[GPKGContentsDao alloc] initWithDatabase:self.database];
//}

-(GPKGGeometryColumnsDao *) getGeometryColumnsDao{
    return [[GPKGGeometryColumnsDao alloc] initWithDatabase:self.database];
}

//TODO
//-(GPKGTileMatrixSetDao *) getTileMatrixSetDao{
//    return [[GPKGTileMatrixSetDao alloc] initWithDatabase:self.database];
//}

@end