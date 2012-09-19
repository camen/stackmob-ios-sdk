/**
 * Copyright 2012 StackMob
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Kiwi/Kiwi.h>
#import "StackMob.h"
#import "SMClient.h"
#import "SMCoreDataStore.h"
#import "Superpower.h"

SPEC_BEGIN(SMRelationshipHeadersSpec)

describe(@"SMRelationshipHeaders", ^{
    
    __block NSManagedObjectContext *moc;
    __block NSManagedObjectModel *mom;
    __block NSString *StackMobRelationsHeader = @"X-StackMob-Relations";
    
    beforeEach(^{
        if (mom == nil) {
           mom = [NSManagedObjectModel mergedModelFromBundles:[NSBundle allBundles]]; 
        }
        
        SMClient *client = [[SMClient alloc] initWithAPIVersion:@"0" publicKey:@"1234"];
        SMCoreDataStore *cds = [client coreDataStoreWithManagedObjectModel:mom];
        moc = [cds managedObjectContext];
    });
    
    afterEach(^{
        mom = nil;
    });
    
    describe(@"No headers should be created if no related objects are present", ^{
        __block NSManagedObject *aPerson = nil;
        beforeEach(^{
            aPerson = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:moc];
            [aPerson setValue:@"the" forKey:@"first_name"];
            [aPerson setValue:@"dude" forKey:@"last_name"];
            [aPerson setValue:[aPerson sm_assignObjectId] forKey:[aPerson sm_primaryKeyField]];
        });
        
        it(@"Should contain no relationship headers", ^{
            NSDictionary *dict = [aPerson sm_dictionarySerialization];
            NSLog(@"serialized dict is %@", dict);
            NSLog(@"%@: %@", StackMobRelationsHeader, [dict objectForKey:StackMobRelationsHeader]);
            [[theValue([dict count]) should] equal:theValue(1)];
        });
        it(@"Should not include relationships in the serialized dictionary", ^{
            NSDictionary *dict = [aPerson sm_dictionarySerialization];
            NSLog(@"serialized dict is %@", dict);
            [[[dict objectForKey:@"SerializedDict"] objectForKey:@"superpower"] shouldBeNil];
            [[[dict objectForKey:@"SerializedDict"] objectForKey:@"interests"] shouldBeNil];
            [[[dict objectForKey:@"SerializedDict"] objectForKey:@"favorites"] shouldBeNil];

        });
    });
    
    describe(@"Headers for one-to-one relationships", ^{
        __block NSManagedObject *aPerson = nil;
        __block NSManagedObject *aSuperpower = nil;
        beforeEach(^{
            aPerson = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:moc];
            [aPerson setValue:@"the" forKey:@"first_name"];
            [aPerson setValue:@"dude" forKey:@"last_name"];
            [aPerson setValue:[aPerson sm_assignObjectId] forKey:[aPerson sm_primaryKeyField]];
            
            aSuperpower = [NSEntityDescription insertNewObjectForEntityForName:@"Superpower" inManagedObjectContext:moc];
            [aSuperpower setValue:@"sweet" forKey:@"name"];
            [aSuperpower setValue:[aSuperpower sm_assignObjectId] forKey:[aSuperpower sm_primaryKeyField]];
            [aSuperpower setValue:aPerson forKey:@"person"];
        });
        
        it(@"Should contain a relationship headers", ^{
            NSDictionary *dict = [aPerson sm_dictionarySerialization];
            NSLog(@"serialized dict is %@", dict);
            NSLog(@"%@: %@", StackMobRelationsHeader, [dict objectForKey:StackMobRelationsHeader]);
            [[[dict objectForKey:StackMobRelationsHeader] should] equal:@"superpower=superpower&superpower.person=person"];
            
            dict = [aSuperpower sm_dictionarySerialization];
            NSLog(@"serialized dict is %@", dict);
            NSLog(@"%@: %@", StackMobRelationsHeader, [dict objectForKey:StackMobRelationsHeader]);
            [[[dict objectForKey:StackMobRelationsHeader] should] equal:@"person=person&person.superpower=superpower"];
            
        });
        it(@"Should include relationships in the serialized dictionary for superpower", ^{
            NSDictionary *dict = [aPerson sm_dictionarySerialization];
            NSLog(@"serialized dict is %@", dict);
            [[[dict objectForKey:@"SerializedDict"] objectForKey:@"superpower"] shouldNotBeNil];
            [[[dict objectForKey:@"SerializedDict"] objectForKey:@"interests"] shouldBeNil];
            [[[dict objectForKey:@"SerializedDict"] objectForKey:@"favorites"] shouldBeNil];
        });
    });
    
    describe(@"Headers for one-to-many relationships", ^{
        __block NSManagedObject *aPerson = nil;
        __block NSManagedObject *anInterest = nil;
        beforeEach(^{
            aPerson = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:moc];
            [aPerson setValue:@"the" forKey:@"first_name"];
            [aPerson setValue:@"dude" forKey:@"last_name"];
            [aPerson setValue:[aPerson sm_assignObjectId] forKey:[aPerson sm_primaryKeyField]];
            
            anInterest = [NSEntityDescription insertNewObjectForEntityForName:@"Interest" inManagedObjectContext:moc];
            [anInterest setValue:@"sports" forKey:@"name"];
            [anInterest setValue:[anInterest sm_assignObjectId] forKey:[anInterest sm_primaryKeyField]];
            
            [aPerson setValue:[NSMutableSet setWithObject:anInterest] forKey:@"interests"];
        });
        
        it(@"Should contain a relationship headers", ^{
            NSDictionary *dict = [aPerson sm_dictionarySerialization];
            NSLog(@"serialized dict is %@", dict);
            NSLog(@"%@: %@", StackMobRelationsHeader, [dict objectForKey:StackMobRelationsHeader]);
            [[[dict objectForKey:StackMobRelationsHeader] should] equal:@"interests=interest"];
            
            dict = [anInterest sm_dictionarySerialization];
            NSLog(@"serialized dict is %@", dict);
            NSLog(@"%@: %@", StackMobRelationsHeader, [dict objectForKey:StackMobRelationsHeader]);
            [[[dict objectForKey:StackMobRelationsHeader] should] equal:@"person=person&person.interests=interest"];
            
        });
        it(@"Should include relationships in the serialized dictionary for superpower", ^{
            NSDictionary *dict = [aPerson sm_dictionarySerialization];
            NSLog(@"serialized dict is %@", dict);
            [[[dict objectForKey:@"SerializedDict"] objectForKey:@"superpower"] shouldBeNil];
            [[[dict objectForKey:@"SerializedDict"] objectForKey:@"interests"] shouldNotBeNil];
            [[[dict objectForKey:@"SerializedDict"] objectForKey:@"favorites"] shouldBeNil];
        });

    });
    
    describe(@"Headers for many-to-many relationships", ^{
        __block NSManagedObject *aPerson = nil;
        __block NSManagedObject *aFavorite = nil;
        beforeEach(^{
            aPerson = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:moc];
            [aPerson setValue:@"the" forKey:@"first_name"];
            [aPerson setValue:@"dude" forKey:@"last_name"];
            [aPerson setValue:[aPerson sm_assignObjectId] forKey:[aPerson sm_primaryKeyField]];
            
            aFavorite = [NSEntityDescription insertNewObjectForEntityForName:@"Favorite" inManagedObjectContext:moc];
            [aFavorite setValue:@"Sports" forKey:@"genre"];
            [aFavorite setValue:[aFavorite sm_assignObjectId] forKey:[aFavorite sm_primaryKeyField]];
            
            [aPerson setValue:[NSMutableSet setWithObject:aFavorite] forKey:@"favorites"];
            
            [aFavorite setValue:[NSMutableSet setWithObject:aPerson] forKey:@"persons"];
            
        });
        
        it(@"Should contain a relationship headers", ^{
            NSDictionary *dict = [aPerson sm_dictionarySerialization];
            NSLog(@"serialized dict is %@", dict);
            NSLog(@"%@: %@", StackMobRelationsHeader, [dict objectForKey:StackMobRelationsHeader]);
            [[[dict objectForKey:StackMobRelationsHeader] should] equal:@"favorites=favorite"];
            
            dict = [aFavorite sm_dictionarySerialization];
            NSLog(@"serialized dict is %@", dict);
            NSLog(@"%@: %@", StackMobRelationsHeader, [dict objectForKey:StackMobRelationsHeader]);
            [[[dict objectForKey:StackMobRelationsHeader] should] equal:@"persons=person"];
            
        });
        it(@"Should include relationships in the serialized dictionary for superpower", ^{
            NSDictionary *dict = [aPerson sm_dictionarySerialization];
            NSLog(@"serialized dict is %@", dict);
            [[[dict objectForKey:@"SerializedDict"] objectForKey:@"superpower"] shouldBeNil];
            [[[dict objectForKey:@"SerializedDict"] objectForKey:@"interests"] shouldBeNil];
            [[[dict objectForKey:@"SerializedDict"] objectForKey:@"favorites"] shouldNotBeNil];
        });
    });
    
    describe(@"combo one-to-one and one-to-many", ^{
        __block NSManagedObject *aPerson = nil;
        __block NSManagedObject *aSuperpower = nil;
        __block NSManagedObject *anInterest = nil;
        beforeEach(^{
            aPerson = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:moc];
            [aPerson setValue:@"the" forKey:@"first_name"];
            [aPerson setValue:@"dude" forKey:@"last_name"];
            [aPerson setValue:[aPerson sm_assignObjectId] forKey:[aPerson sm_primaryKeyField]];
            
            aSuperpower = [NSEntityDescription insertNewObjectForEntityForName:@"Superpower" inManagedObjectContext:moc];
            [aSuperpower setValue:@"sweet" forKey:@"name"];
            [aSuperpower setValue:[aSuperpower sm_assignObjectId] forKey:[aSuperpower sm_primaryKeyField]];
            [aSuperpower setValue:aPerson forKey:@"person"];
            
            anInterest = [NSEntityDescription insertNewObjectForEntityForName:@"Interest" inManagedObjectContext:moc];
            [anInterest setValue:@"sports" forKey:@"name"];
            [anInterest setValue:[anInterest sm_assignObjectId] forKey:[anInterest sm_primaryKeyField]];
            
            [aPerson setValue:[NSMutableSet setWithObject:anInterest] forKey:@"interests"];
        });
        
        it(@"Should contain a relationship headers", ^{
            NSDictionary *dict = [aPerson sm_dictionarySerialization];
            NSLog(@"serialized dict is %@", dict);
            NSLog(@"%@: %@", StackMobRelationsHeader, [dict objectForKey:StackMobRelationsHeader]);
            [[[dict objectForKey:StackMobRelationsHeader] should] equal:@"superpower=superpower&superpower.person=person&interests=interest"];
            
            dict = [aSuperpower sm_dictionarySerialization];
            NSLog(@"serialized dict is %@", dict);
            NSLog(@"%@: %@", StackMobRelationsHeader, [dict objectForKey:StackMobRelationsHeader]);
            [[[dict objectForKey:StackMobRelationsHeader] should] equal:@"person=person&person.superpower=superpower&person.interests=interest"];
            
            dict = [anInterest sm_dictionarySerialization];
            NSLog(@"serialized dict is %@", dict);
            NSLog(@"%@: %@", StackMobRelationsHeader, [dict objectForKey:StackMobRelationsHeader]);
            [[[dict objectForKey:StackMobRelationsHeader] should] equal:@"person=person&person.superpower=superpower&person.superpower.person=person&person.interests=interest"];
            
        });
        it(@"Should include relationships in the serialized dictionary for superpower", ^{
            NSDictionary *dict = [aPerson sm_dictionarySerialization];
            NSLog(@"serialized dict is %@", dict);
            [[[dict objectForKey:@"SerializedDict"] objectForKey:@"superpower"] shouldNotBeNil];
            [[[dict objectForKey:@"SerializedDict"] objectForKey:@"interests"] shouldNotBeNil];
            [[[dict objectForKey:@"SerializedDict"] objectForKey:@"favorites"] shouldBeNil];
        });
    });
    
});

SPEC_END