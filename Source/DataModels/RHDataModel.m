//
//  MapDataModel.m
//  Wildflowers of Detroit Iphone
//
//  Created by Deep Winter on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RHDataModel.h"
#import "RHSettings.h"
#import "RHDocument.h"
#import "RHDeviceUser.h"
#import "SharedInstanceMacro.h"

@implementation RHDataModel

+ (id)instance
{
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}


@synthesize database;
@synthesize query;
@synthesize syncTimeoutTimer;
@synthesize project;


-  (id) initWithBlock:( void ( ^ )() ) didStartBlock {
    
    // Start the TouchDB server:
    CouchTouchDBServer* server = [CouchTouchDBServer sharedInstance];
    NSAssert(!server.error, @"Error initializing TouchDB: %@", server.error);
    
        if (server.error) {
            [self showAlert: @"Couldn't start Couchbase." error: server.error fatal: YES];
            return nil;
        }
        
        self.database = [server databaseNamed: [RHSettings databaseName]];
        NSAssert(database, @"Database Is NULL!");
        
        
        if(![RHSettings useRemoteServer]){
            // Create the database on the first run of the app.
            NSError* error; 
            if (![self.database ensureCreated: &error]) {
                [self showAlert: @"Couldn't create local database." error: error fatal: YES];
                return nil;
            }
            NSLog(@"...Created CouchDatabase at <%@>", self.database.URL);

            
        }
        
        database.tracksChanges = YES;

        //Compile views
        CouchDesignDocument* design = [database designDocumentWithName: @"rhusMobile"];
        NSAssert(design, @"Couldn't find design document");
        design.language = kCouchLanguageJavaScript;
        /*
         [design defineViewNamed: @"detailDocuments"
         map: @"function(doc) { emit([doc.created_at], [doc._id, doc.reporter, doc.comment, doc.medium, doc.created_at] );}"];
         */
                
        
    [design defineViewNamed: @"deviceUserGalleryDocuments" mapBlock: ^(NSDictionary* doc, void (^emit)(id key, id value)){
    
            NSArray * key = [NSArray arrayWithObjects: 
                             [doc objectForKey: @"deviceuser_identifier"], 
                             [doc objectForKey: @"project"],
                             [doc objectForKey: @"created_at"],
                             nil];
     
            NSDictionary * value = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [doc objectForKey: @"_id"], @"id",  
                                    [doc objectForKey: @"latitude"], @"latitude",
                                    [doc objectForKey: @"longitude"], @"longitude", 
                                    [doc objectForKey: @"reporter"], @"reporter", 
                                    [doc objectForKey: @"comment"], @"comment", 
                                    [doc objectForKey: @"created_at"],@"created_at", 
                                    [doc objectForKey: @"geometry"], @"geometry",
                                    nil];
            emit(key, value);
        } version: @"1.0"];
     
         /*
                            map: @"function(doc) { emit([doc.deviceuser_identifier, doc.project, doc.created_at],{'id':doc._id, 'thumb':doc.thumb, 'latitude':doc.latitude, 'longitude':doc.longitude, 'reporter':doc.reporter, 'comment':doc.comment, 'created_at':doc.created_at} );}"];
        */
        
        /*
        [design defineViewNamed: @"deviceUserGalleryDocuments"
                            map: @"function(doc) { emit([doc.deviceuser_identifier, doc.created_at],{'id':doc._id, 'latitude':doc.latitude, 'longitude':doc.longitude, 'reporter':doc.reporter, 'comment':doc.comment, 'created_at':doc.created_at} );}"];
        */
        
        /*  
        [design defineViewNamed: @"galleryDocuments"
                            map: @"function(doc) { emit(doc.created_at,{'id':doc._id, 'thumb':doc.thumb, 'medium':doc.medium, 'latitude':doc.latitude, 'longitude':doc.longitude, 'reporter':doc.reporter, 'comment':doc.comment, 'created_at':doc.created_at, 'deviceuser_identifier':doc.deviceuser_identifier } );}"];
        */
        
        [design defineViewNamed: @"rhusDocuments" mapBlock: ^(NSDictionary* doc, void (^emit)(id key, id value)){
            
            if([doc objectForKey:@"docType"] == @"zone"){
                return;
            }
            
            NSArray * key = [NSArray arrayWithObjects:
                             [doc objectForKey:@"project"],
                             [doc objectForKey:@"created_at"],
                             nil];
            
            NSDictionary * value = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [doc objectForKey: @"_id"], @"id",
                                    [doc objectForKey: @"latitude"], @"latitude",
                                    [doc objectForKey: @"longitude"], @"longitude",
                                    [doc objectForKey: @"reporter"], @"reporter",
                                    [doc objectForKey: @"comment"], @"comment",
                                    [doc objectForKey: @"created_at"], @"created_at",
                                    [doc objectForKey: @"geometry"], @"geometry",
                                    nil];
            
            emit(key, value);
        } version: @"1.0"];

/*         
        
        [design defineViewNamed: @"rhusDocuments"
                            map: @"function(doc) { emit( [doc.project, doc.created_at],{'id':doc._id,'latitude':doc.latitude, 'longitude':doc.longitude, 'reporter':doc.reporter, 'comment':doc.comment, 'created_at':doc.created_at, 'deviceuser_identifier':doc.deviceuser_identifier } );}"];
  */      
        [design defineViewNamed: @"documentDetail" mapBlock: ^(NSDictionary* doc, void (^emit)(id key, id value)){
            NSString * key = [doc objectForKey:@"_id"];
            NSDictionary * value = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [doc objectForKey: @"_id"], @"id",
                                    [doc objectForKey: @"thumb"], @"thumb",
                                    [doc objectForKey: @"medium"], @"medium",
                                    [doc objectForKey: @"latitude"], @"latitude",
                                    [doc objectForKey: @"longitude"], @"longitude",
                                    [doc objectForKey: @"reporter"], @"reporter",
                                    [doc objectForKey: @"comment"], @"comment", 
                                    [doc objectForKey: @"created_at"], @"created_at",
                                    nil];
            
            emit(key, value);
        } version: @"1.0"];
            /*                                                          )
                            map: @"function(doc) { emit( doc._id, {'id' :doc._id, 'reporter' : doc.reporter, 'comment' : doc.comment, 'thumb' : doc.thumb, 'medium' : doc.medium, 'created_at' : doc.created_at} );}"];
        */
        
        
        [design defineViewNamed: @"projects" mapBlock: ^(NSDictionary* doc, void (^emit)(id key, id value)){
            NSString * key = [doc objectForKey:@"project"];
            if(key != NULL){
                emit(key, NULL);
            }
        } 
                    reduceBlock: REDUCEBLOCK({
            return NULL;
        }) version: @"1.0"];
        /*
    map: @"function(doc) { if(doc.project) { emit(doc.project, null);}  }"
                         reduce: @"function(key, values) { return true;}"];
        
         */
    
        [design defineViewNamed: @"uploaded" mapBlock: ^(NSDictionary* doc, void (^emit)(id key, id value)){
                NSString * key = [doc objectForKey:@"uploaded"];
                if(key == NULL){
                    emit(doc, NULL);
                }
        }
            reduceBlock: REDUCEBLOCK({
                return NULL;
        }) version: @"1.0"];
    
        [design saveChanges];
        /*
        design = [database designDocumentWithName: @"rhusMobile"];
        NSMutableDictionary * properties = [design.properties mutableCopy];
        [properties setObject: [NSDictionary dictionaryWithObjectsAndKeys: @"function(doc, req) { if(doc.id.indexOf(\"_design\") === 0) { return false; } else { return true; }}",@"excludeDesignDocs", nil]  forKey:@"filters"];
        RESTOperation * op = [design putProperties:properties];
        [op start];
        [op wait]; //synchronous
        */
         
        didStartBlock();
   // }];
    NSLog(@"%@", @"Started...");
   // NSAssert(started, @"didnt start");
    
    return self;
    
}


+ (UIImage *) getDocumentThumbnail: (NSString *) key {
    CouchDocument* doc = [[self.instance database] documentWithID: key];
    CouchModel * model = [[CouchModel alloc] initWithDocument:doc];
    CouchAttachment * thumbnail = [model attachmentNamed:@"thumb.jpg"];
    if(thumbnail != nil){
        return [UIImage imageWithData: thumbnail.body];
    } else {
        return nil;
    }
}

+ (UIImage *) getDocumentImage: (NSString *) key {
    CouchDocument* doc = [[self.instance database] documentWithID: key];
    CouchModel * model = [[CouchModel alloc] initWithDocument:doc];
    CouchAttachment * image = [model attachmentNamed:@"medium.jpg"];
    if(image != nil){
        return [UIImage imageWithData: image.body];
    } else {
        return nil;
    }
}


- (NSArray *) runQuery: (CouchQuery *) couchQuery {    
    CouchQueryEnumerator * enumerator = [couchQuery rows];
    
    if(!enumerator){
        return [NSArray array];
    }
    NSLog(@"count = %i", [enumerator count]);
    
    CouchQueryRow * row;
    NSMutableArray * data = [NSMutableArray array];
    while( (row =[enumerator nextRow]) ){
        
        CouchDocument * doc = row.document;
             
        //give em the data
        NSDictionary * properties = doc.properties;
        [data addObject: [[RHDocument alloc] initWithDictionary: [NSDictionary dictionaryWithDictionary: properties]]];
    }
    return data;
    
}


+ (NSArray *) getUserGalleryDocumentsWithStartKey: (NSString *) startKey 
                                         andLimit: (NSInteger) limit 
                                 andUserIdentifer: (NSString *) userIdentifier {
    
    //Create view;
    CouchDatabase * database = [self.instance database];
    CouchDesignDocument* design = [database designDocumentWithName: @"rhusMobile"];
    NSAssert(design, @"Couldn't find design document");
    
    CouchQuery * query = [design queryViewNamed: @"deviceUserGalleryDocuments"]; //asLiveQuery];
    
    query.descending = YES;
    query.endKey = [NSArray arrayWithObjects:userIdentifier, [[RHDataModel instance] project], nil];
    query.startKey = [NSArray arrayWithObjects:userIdentifier, [[RHDataModel instance] project], [NSDictionary dictionary], nil];
    
    NSArray * r = [(RHDataModel * ) self.instance runQuery:query];
    
    return r;
    
    
}

+ (NSArray *) getDeviceUserGalleryDocumentsWithStartKey: (NSString *) startKey andLimit: (NSInteger) limit {
    return [self getUserGalleryDocumentsWithStartKey: startKey 
                                            andLimit: limit 
                                    andUserIdentifer:  [RHDeviceUser uniqueIdentifier]];
}


+ (NSArray *) getAllDocumentsNotUploaded {
    
    CouchDatabase * database = [self.instance database];
    CouchDesignDocument* design = [database designDocumentWithName: @"rhusMobile"];
    NSAssert(design, @"Couldn't find design document");
    // Later on, we can query the view:
    CouchQuery* query = [design queryViewNamed: @"uploaded"];
    query.descending = YES;
    /*
    NSLog(@"Count: %i", [[query rows] count]);
    for (CouchQueryRow* row in query.rows) {
        NSLog(@"%@'s email is <%@>", row.key, row.value);
    }
     */
    NSArray * r = [self.instance runQuery:query];
    NSLog(@"Count: %i", [r count]);
    return r;
}

+ (NSArray *) getAllDocuments {
    //TODO: Implement
    //return [NSArray array];
    
    CouchDatabase * database = [self.instance database];
    CouchDesignDocument* design = [database designDocumentWithName: @"rhusMobile"];
    NSAssert(design, @"Couldn't find design document");
    
    CouchQuery * query = [design queryViewNamed: @"rhusDocuments"]; //asLiveQuery];
    query.descending = YES;
    NSArray * r = [self.instance runQuery:query];
    NSLog(@"Count: %i", [r count]);
    
    return r;
}

+ (NSArray *) getDocumentsInProject: (NSString *) project {
    
    CouchDatabase * database = [self.instance database];
    CouchDesignDocument* design = [database designDocumentWithName: @"rhusMobile"];
    NSAssert(design, @"Couldn't find design document");
    
    CouchQuery * query = [design queryViewNamed: @"rhusDocuments"]; //asLiveQuery];
    query.descending = YES;
    query.endKey = [NSArray arrayWithObjects:project, nil];
    query.startKey = [NSArray arrayWithObjects:project, [NSDictionary dictionary], nil];    
    NSArray * r = [self.instance runQuery:query];
    NSLog(@"Count: %i", [r count]);
    
    return r;
}


+ (NSArray *) getDocumentsInProject: (NSString *) project since: (NSString*) date {
    //TODO: Implement
    return [NSArray array];
}


+ (NSArray *) getDetailDocumentsWithStartKey: (NSString *) startKey andLimit: (NSInteger) limit  {
    CouchDatabase * database = [self.instance database];
    
    CouchDesignDocument* design = [database designDocumentWithName: @"rhusMobile"];

    CouchQuery * query = [design queryViewNamed: @"detailDocuments"]; //asLiveQuery];
    query.descending = NO;
    NSArray * r = [(RHDataModel * ) self.instance runQuery: query];
    
    return r;
    
}

+ (NSDictionary *) getDetailDocument: (NSString *) documentId {
    CouchDesignDocument* design = [  [[self instance] database] designDocumentWithName: @"rhusMobile"];
    CouchQuery * query = [design queryViewNamed: @"documentDetail"]; //asLiveQuery];
    query.startKey = documentId;
    query.endKey = documentId;
    NSArray * r = [(RHDataModel * ) self.instance runQuery: query];
    if([r count] == 1){
        return [r objectAtIndex:0];
    } else {
        return nil;
    }
}


+ (NSArray *) getUserDocuments {
    return [self getGalleryDocumentsWithStartKey:nil andLimit:nil];
}

+ (NSArray *) getUserDocumentsWithOffset:(NSInteger)offset andLimit:(NSInteger)limit {
    NSLog(@"getUserDocumentsWithOffset just calling getUserDocuments");
    return [self.instance _getUserDocuments];
}


+ (void) addProject:(NSString *) projectName {    
    NSDictionary * document = [NSDictionary dictionaryWithObjectsAndKeys:projectName, @"project", nil];
    [RHDataModel addDocument:document];
}

- (NSArray *) _getProjects {
    CouchDesignDocument* design = [database designDocumentWithName: @"rhusMobile"];
    CouchQuery * couchQuery = [design queryViewNamed: @"projects"]; //asLiveQuery];
    couchQuery.groupLevel = 1;
    CouchQueryEnumerator * enumerator = [couchQuery rows];
    NSMutableArray * r = [NSMutableArray array];
    CouchQueryRow * row;
    while( (row =[enumerator nextRow]) ){
        [r addObject:row.key];
    }
    return r;
}

+ (NSArray *) getProjects {
    return [self.instance _getProjects];
}

+ (BOOL) updateDocument:(NSDictionary*)document
{
    NSString *strDocID  = [document objectForKey:@"_id"];
    NSString *strDocRev = [document objectForKey:@"_rev"];
    if (strDocID==nil || strDocRev==nil)
        return NO;
    CouchDocument *doc = [self.instance.database documentWithID:strDocID];
    RESTOperation *op = [doc putProperties:document];
    [op onCompletion: ^{
        if (op.error)
            NSAssert(false, @"ERROR");
        // AppDelegate needs to observer MapData for connection errors.
        // [self showErrorAlert: @"Couldn't save the new item" forOperation: op];
        // Re-run the query:
		//[self.dataSource.query start];
        [self.instance.query start];
	}];
    [op start];
    [op wait]; //kickin it synchronous for right now.
    
    RESTBody * responseBody = op.responseBody;
    NSLog(@"%@", [op.responseBody asString]);
    
    NSDictionary * object = (NSDictionary *)responseBody.fromJSON;
    NSLog(@"%@", [object objectForKey:@"id"]);
    return YES;
}

+ (NSString *) addDocument: (NSDictionary *) document {
    //Add any additional properties
    
    // Save the document, asynchronously:
    CouchDocument* doc = [self.instance.database untitledDocument];
    RESTOperation* op = [doc putProperties:document];
    [op onCompletion: ^{
        if (op.error)
            NSAssert(false, @"ERROR");
        // AppDelegate needs to observer MapData for connection errors.
        // [self showErrorAlert: @"Couldn't save the new item" forOperation: op];
        // Re-run the query:
		//[self.dataSource.query start];
        [self.instance.query start];
	}];
    [op start];
    [op wait]; //kickin it synchronous for right now.
    
    RESTBody * responseBody = op.responseBody;
    NSLog(@"%@", [op.responseBody asString]);
    
    NSDictionary * object = (NSDictionary *)responseBody.fromJSON;
    NSLog(@"%@", [object objectForKey:@"id"]);
    return [object objectForKey:@"id"];
}

+ (void) addAttachment:(NSString *) name toDocument: (NSString *) documentId withData: (NSData *) data andContentType: (NSString *) contentType {

    CouchDocument * doc = [self.instance.database documentWithID:documentId];
    CouchRevision * revision = doc.currentRevision;
    
    CouchAttachment * newAttachment = [revision createAttachmentWithName:name
                                                                    type:contentType ];
    
    RESTOperation * op2 = [newAttachment PUT:data contentType:contentType];
    [op2 start];
    [op2 wait];
    //kickin it synchronous for right now.

}


// Display an error alert, without blocking.
// If 'fatal' is true, the app will quit when it's pressed.
- (void)showAlert: (NSString*)message error: (NSError*)error fatal: (BOOL)fatal {
    if (error) {
        message = [NSString stringWithFormat: @"%@\n\n%@", message, error.localizedDescription];
    }
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle: (fatal ? @"Fatal Error" : @"Error")
                                                    message: message
                                                   delegate: (fatal ? self : nil)
                                          cancelButtonTitle: (fatal ? @"Quit" : @"Sorry")
                                          otherButtonTitles: nil];
    [alert show];
}


-(void)syncTimeout {
    if(!syncStarted){
        NSLog(@"Sync Timeout");

        UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"No Sync"
                                                        message: @"Timed out while trying to sync, either there is nothing to sync or you aren't connected to the internet.  Make sure you are connected to the internet and try again!"
                                                       delegate: nil
                                              cancelButtonTitle: @"OK"
                                              otherButtonTitles: nil];
        [alert show];
        [self forgetSync];
        if(syncCompletedBlock){
            syncCompletedBlock();
        }
        syncCompletedBlock = nil;
    }
}

- (void)updateSyncURL {
    [self updateSyncURLWithCompletedBlock: nil];
}


- (void)updateSyncURLWithCompletedBlock: ( CompletedBlock ) setCompletedBlock  {
    
    if (!self.database){
        NSLog(@"No Database in updateSyncURL");
        return;
    }
    NSURL* newRemoteURL = nil;
    NSString *syncpoint = [RHSettings couchRemoteSyncURL];
    if (syncpoint.length > 0)
        newRemoteURL = [NSURL URLWithString:syncpoint];
    
    [self forgetSync];
    
    NSLog(@"Setting up replication %@", [newRemoteURL debugDescription]);
    NSArray* repls = [self.database replicateWithURL: newRemoteURL exclusively: YES];
    _pull = [repls objectAtIndex: 0];
    _push = [repls objectAtIndex: 1];
    //_pull.continuous = NO;  //we might want these not to be continuous for user initialized replications
    //_push.continuous = NO;
    // _pull.filter = @"design/excludeDesignDocs";
    // _push.filter = @"rhusMobile/excludeDesignDocs";
    
    [_pull addObserver: self forKeyPath: @"completed" options: 0 context: NULL];
    [_push addObserver: self forKeyPath: @"completed" options: 0 context: NULL];
    
    
    
    syncCompletedBlock = setCompletedBlock;
    
    //set a timeout to detect when there are in fact no changes
    //This is only relevant when sync is NOT continuous
   
    /*NSInvocation * invocation = [[NSInvocation alloc] init];
    [invocation setTarget:self];
    [invocation setSelector:@selector(syncTimeout)];
    syncStarted = FALSE;
    self.syncTimeoutTimer = [NSTimer timerWithTimeInterval:5.0 invocation:invocation repeats:NO];
     */
    
    syncStarted = FALSE;
    /*
    This causes erroneous sync failure message when there is nothing to sync using continuous.
    self.syncTimeoutTimer =  [NSTimer scheduledTimerWithTimeInterval:8.0 target:self selector:@selector(syncTimeout) userInfo:nil repeats:NO];
     */
    
}



- (void) forgetSync {
    [_pull removeObserver: self forKeyPath: @"completed"];
    _pull = nil;
    
    [_push removeObserver: self forKeyPath: @"completed"];
    _push = nil;
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == _pull || object == _push) {
        syncStarted = TRUE;
        
        unsigned completed = _pull.completed + _push.completed;
        unsigned total = _pull.total + _push.total;
        NSLog(@"SYNC progress: %u / %u", completed, total);
        if (total > 0 && completed < total) {
            // [self showSyncStatus];
            // [progress setProgress:(completed / (float)total)];
            database.server.activityPollInterval = 0.5;   // poll often while progress is showing
        } else {
            // [self showSyncButton];
            database.server.activityPollInterval = 2.0;   // poll less often at other times
            if(syncCompletedBlock != nil){
                syncCompletedBlock();
                syncCompletedBlock = nil;
            }
        }
    }
}




@end
