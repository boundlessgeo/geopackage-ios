//
//  GPKGExtensionsDao.m
//  geopackage-ios
//
//  Created by Brian Osborn on 5/20/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGExtensionsDao.h"

@implementation GPKGExtensionsDao

-(instancetype) initWithDatabase: (GPKGConnection *) database{
    self = [super initWithDatabase:database];
    if(self != nil){
        self.tableName = EX_TABLE_NAME;
        self.idColumns = @[EX_COLUMN_TABLE_NAME, EX_COLUMN_COLUMN_NAME, EX_COLUMN_EXTENSION_NAME];
        self.columns = @[EX_COLUMN_TABLE_NAME, EX_COLUMN_COLUMN_NAME, EX_COLUMN_EXTENSION_NAME, EX_COLUMN_DEFINITION, EX_COLUMN_SCOPE];
        [self initializeColumnIndex];
    }
    return self;
}

-(NSObject *) createObject{
    return [[GPKGExtensions alloc] init];
}

-(void) setValueInObject: (NSObject*) object withColumnIndex: (int) columnIndex withValue: (NSObject *) value{
    
    GPKGExtensions *setObject = (GPKGExtensions*) object;
    
    switch(columnIndex){
        case 0:
            setObject.tableName = (NSString *) value;
            break;
        case 1:
            setObject.columnName = (NSString *) value;
            break;
        case 2:
            setObject.extensionName = (NSString *) value;
            break;
        case 3:
            setObject.definition = (NSString *) value;
            break;
        case 4:
            setObject.scope = (NSString *) value;
            break;
        default:
            [NSException raise:@"Illegal Column Index" format:@"Unsupported column index: %d", columnIndex];
            break;
    }
    
}

-(NSObject *) getValueFromObject: (NSObject*) object withColumnIndex: (int) columnIndex{
    
    NSObject * value = nil;
    
    GPKGExtensions *getObject = (GPKGExtensions*) object;
    
    switch(columnIndex){
        case 0:
            value = getObject.tableName;
            break;
        case 1:
            value = getObject.columnName;
            break;
        case 2:
            value = getObject.extensionName;
            break;
        case 3:
            value = getObject.definition;
            break;
        case 4:
            value = getObject.scope;
            break;
        default:
            [NSException raise:@"Illegal Column Index" format:@"Unsupported column index: %d", columnIndex];
            break;
    }
    
    return value;
}

-(int) deleteByExtension: (NSString *) extensionName{
    NSString * where = [self buildWhereWithField:EX_COLUMN_EXTENSION_NAME andValue:extensionName];
    int count = [self deleteWhere:where];
    return count;
}

-(int) deleteByExtension: (NSString *) extensionName andTable: (NSString *) tableName{
    
    NSMutableDictionary *values = [[NSMutableDictionary alloc] init];
    [values setObject:extensionName forKey:EX_COLUMN_EXTENSION_NAME];
    [values setObject:tableName forKey:EX_COLUMN_TABLE_NAME];
    
    NSString * where = [self buildWhereWithFields:values];
    int count = [self deleteWhere:where];
    return count;
}

-(int) deleteByExtension: (NSString *) extensionName andTable: (NSString *) tableName andColumnName: (NSString *) columnName{
    
    NSMutableDictionary *values = [[NSMutableDictionary alloc] init];
    [values setObject:extensionName forKey:EX_COLUMN_EXTENSION_NAME];
    [values setObject:tableName forKey:EX_COLUMN_TABLE_NAME];
    [values setObject:columnName forKey:EX_COLUMN_COLUMN_NAME];
    
    NSString * where = [self buildWhereWithFields:values];
    int count = [self deleteWhere:where];
    return count;
}

-(GPKGResultSet *) queryByExtension: (NSString *) extensionName{
    return [self queryForEqWithField:EX_COLUMN_EXTENSION_NAME andValue:extensionName];
}

-(GPKGResultSet *) queryByExtension: (NSString *) extensionName andTable: (NSString *) tableName{
    
    NSMutableDictionary *values = [[NSMutableDictionary alloc] init];
    [values setObject:extensionName forKey:EX_COLUMN_EXTENSION_NAME];
    [values setObject:tableName forKey:EX_COLUMN_TABLE_NAME];
    
    return [self queryForFieldValues:values];
}

-(GPKGResultSet *) queryByExtension: (NSString *) extensionName andTable: (NSString *) tableName andColumnName: (NSString *) columnName{
    
    NSMutableDictionary *values = [[NSMutableDictionary alloc] init];
    [values setObject:extensionName forKey:EX_COLUMN_EXTENSION_NAME];
    [values setObject:tableName forKey:EX_COLUMN_TABLE_NAME];
    [values setObject:columnName forKey:EX_COLUMN_COLUMN_NAME];
    
    return [self queryForFieldValues:values];
}

@end
