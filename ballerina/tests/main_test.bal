// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/log;
import ballerina/test;

string testHostName = "localhost";
string testUser = "admin";
string testPass = "admin";

const DATABASE_NAME = "moviesDB";
const COLLECTION_NAME = "movies";

ConnectionConfig mongoConfig = {
    connection: {
        host: testHostName,
        port: 27017,
        auth: {
            username: testUser,
            password: testPass
        },
        options: {
            sslEnabled: false,
            serverSelectionTimeout: 15000
        }
    },
    databaseName: DATABASE_NAME
};

ConnectionConfig mongoConfigError = {
    connection: {
        url: "invalidDB"
    },
    databaseName: "MyDb"
};

Client mongoClient = check new (mongoConfig);

@test:Config {
    groups: ["mongodb"]
}
public function initializeInvalidClient() {
    log:printInfo("Start initialization test failure");
    Client|Error mongoClient = new (mongoConfigError);
    if (mongoClient is ApplicationError) {
        log:printInfo("Creating client failed '" + mongoClient.message() + "'.");
    } else {
        test:assertFail("Error expected when url is invalid.");
    }
}

@test:Config {
    dependsOn: [ initializeInvalidClient ],
    groups: ["mongodb"]
}
public function testListDatabaseNames() returns error? {
    string[] dbNames = check mongoClient->getDatabasesNames();
    log:printInfo("Database Names: " + dbNames.toString());
}

@test:Config {
    dependsOn: [ testListDatabaseNames ],
    groups: ["mongodb"]
}
public function testListCollections() returns error? {
    string[] collectionNames = check mongoClient->getCollectionNames("admin");
    log:printInfo("Collection Names: " + collectionNames.toString());
}

@test:Config {
    dependsOn: [ testListCollections ],
    groups: ["mongodb"]
}
public function testInsertData() returns error? {
    map<json> document1 = {name: "The Lion King", year: "2019", rating: 8};
    map<json> ducument2 = {name: "Black Panther", year: "2018", rating: 7};

    check mongoClient->insert(document1, COLLECTION_NAME);
    log:printInfo("Successfully inserted document1 into collection");

    check mongoClient->insert(ducument2, COLLECTION_NAME);
    log:printInfo("Successfully inserted document2 into collection");
}

@test:Config {
    dependsOn: [ testInsertData ],
    groups: ["mongodb"]
}
public function testInsertDataWithDbName() returns error? {
    map<json> document1 = {name: "The Lion King", year: "2019", rating: 8};
    map<json> document2 = {name: "Black Panther", year: "2018", rating: 7};

    check mongoClient->insert(document1, COLLECTION_NAME, "anothermoviecollection");
    log:printInfo("Successfully inserted document1 into collection");

    check mongoClient->insert(document2, COLLECTION_NAME, "anothermoviecollection");
    log:printInfo("Successfully inserted document2 into collection");
}

@test:Config {
    dependsOn: [ testInsertDataWithDbName ],
    groups: ["mongodb"]
}
public function testCountDocuments() returns error? {
    int documentCount = check mongoClient->countDocuments(COLLECTION_NAME, (),());
    log:printInfo("Documents counted successfully. Count: " + documentCount.toString());
    test:assertEquals(2, documentCount);

    int documentCount2018 = check mongoClient->countDocuments(COLLECTION_NAME,() , {
        year: "2018"
    });
    log:printInfo("Documents counted successfully. Count: " + documentCount2018.toString());
    test:assertEquals(1, documentCount2018);
}

@test:Config {
    dependsOn: [ testCountDocuments ],
    groups: ["mongodb"]
}
public function testListIndices() returns error? {
    stream<Index, error?> returned = check mongoClient->listIndices(COLLECTION_NAME);
    check returned.forEach(function(Index data){
        log:printInfo(data.ns);
    });
    log:printInfo("Indices returned successfully '");
}

@test:Config {
    dependsOn: [ testListIndices ],
    groups: ["mongodb"]
}
public function testFindData() returns error? {
    map<json> document1 = {name: "Joker", year: "2019", rating: 7};
    map<json> document2 = {name: "Black Panther", year: "2018", rating: 7};

    check mongoClient->insert(document1, COLLECTION_NAME);
    check mongoClient->insert(document2, COLLECTION_NAME);

    map<json> findDoc = {year: "2019"};
    stream<Movie, error?> result = check mongoClient->find(COLLECTION_NAME,filter = findDoc);
    check result.forEach(function(Movie data){
        log:printInfo(data.year.toString());
        test:assertEquals(data.year,"2019","Querying year 2019 filter failed");
    });
    log:printInfo("Querying year 2019 filter tested successfully");

    map<json> sortDoc = {name: 1};
    result = check mongoClient->find(COLLECTION_NAME, filter = findDoc, sort = sortDoc);
    check result.forEach(function(Movie data){
        log:printInfo(data.name);
    });
    log:printInfo("Querying year 2019 sort data tested successfully");

    result = check mongoClient->find(COLLECTION_NAME, filter=findDoc, sort=sortDoc, 'limit=1);
    int count = 0;
    check result.forEach(function(Movie data){
        count += 1;
        log:printInfo(data.name);
    });
    test:assertEquals(count, 1, "Querying filtered sort and limit failed");
    log:printInfo("Querying filtered sort and limit tested successfully");

}

@test:Config {
    dependsOn: [ testFindData ],
    groups: ["mongodb"]
}
public function testFindDataWithProjection() returns error? {
    map<json> findDoc = {year: "2019"};
    map<json> projectionDoc = {name: 1, year: true};
    stream<MovieWithoutRating, error?> result = check mongoClient->find(COLLECTION_NAME, projection = projectionDoc,
                                                             filter = findDoc);
    check result.forEach(function(MovieWithoutRating data){
        log:printInfo(data.year.toString());
        test:assertEquals(data.year,"2019","Querying year 2019 filter with projection failed");
    });
    log:printInfo("Querying year 2019 filter with projection tested successfully");

    map<json> sortDoc = {name: 1};
    result = check mongoClient->find(COLLECTION_NAME, projection = projectionDoc, filter = findDoc, sort = sortDoc);
    check result.forEach(function(MovieWithoutRating data){
        log:printInfo(data.name);
    });
    log:printInfo("Querying year 2019 sort data with projection tested successfully");

    result = check mongoClient->find(COLLECTION_NAME, projection = projectionDoc, filter=findDoc, sort=sortDoc,
                                       'limit=1);
    int count = 0;
    check result.forEach(function(MovieWithoutRating data){
        count += 1;
        log:printInfo(data.name);
    });
    test:assertEquals(count, 1, "Querying filtered sort and limit with projection failed");
    log:printInfo("Querying filtered sort and limit with projection tested successfully");
}

@test:Config {
    dependsOn: [testFindDataWithProjection],
    groups: ["mongodb"]
}
function testFindDistinctValues() returns error? {
    string[] distictiveValues = [];
    stream<string, error?> result = check mongoClient->'distinct(COLLECTION_NAME, "year");
    check result.forEach(function(string data){
        log:printInfo(data);
        distictiveValues.push(data);
    });
    test:assertEquals(distictiveValues.length(), 2, "Querying distinct values failed. " +
    "Expected 2 but found " + distictiveValues.length().toString());
    log:printInfo("Querying distinct values tested successfully");
}

@test:Config {
    dependsOn: [testFindDistinctValues],
    groups: ["mongodb"]
}
function testUpdateDocument() returns error? {
    map<json> replaceFilter = {name: "The Lion King"};
    map<json> replaceDoc = { "$set": {name: "The Lion King", year: "2019", rating: 6}};

    int modifiedCount = check mongoClient->update(replaceDoc, COLLECTION_NAME, (), replaceFilter, false);
    log:printInfo("Modified count: " + modifiedCount.toString());
    test:assertEquals(modifiedCount, 1, "Document modification failed");

    replaceFilter = {rating: 7};
    replaceDoc = { "$inc": {rating: 2}};

    modifiedCount = check mongoClient->update(replaceDoc, COLLECTION_NAME, (), replaceFilter, true);
    log:printInfo("Modified count: " + modifiedCount.toString());
    test:assertEquals(modifiedCount, 3, "Document modification multiple failed");
}

@test:Config {
    dependsOn: [ testUpdateDocument ],
    groups: ["mongodb"]
}
function testUpdateDocumentUpsertTrue() returns error? {
    map<json> replaceFilter = {name: "The Lion King 2"};
    map<json> replaceDoc = { "$set": {name: "The Lion King 2", year: "2019", rating: 7}};

    int modifiedCount = check mongoClient->update(replaceDoc, COLLECTION_NAME, (), replaceFilter, true, true);
    log:printInfo("Modified count: " + modifiedCount.toString());
    test:assertEquals(modifiedCount, 0, "Document modification failed");
}

@test:Config {
    dependsOn: [ testUpdateDocumentUpsertTrue ],
    groups: ["mongodb"]
}
function testDelete() returns error? {
    map<json> deleteFilter = {"rating": 9};

    int deleteDocCount = check mongoClient->delete(COLLECTION_NAME, (), deleteFilter, true);
    log:printInfo("Deleted count: " + deleteDocCount.toString());
    test:assertEquals(deleteDocCount, 3, msg = "Document deletion multiple failed");

    deleteDocCount = check mongoClient->delete(COLLECTION_NAME, (), (), true);
    log:printInfo("Deleted count: " + deleteDocCount.toString());
    test:assertEquals(deleteDocCount, 2, msg = "Document deletion failed");

    deleteDocCount = check mongoClient->delete(COLLECTION_NAME, "anothermoviecollection", (), true);
    log:printInfo("Deleted count: " + deleteDocCount.toString());
    test:assertEquals(deleteDocCount, 2, msg = "Document deletion failed");

    mongoClient->close();
}

type Movie record {
    string name;
    string year;
    int rating;
};

type MovieWithoutRating record {|
    json _id;
    string name;
    string year;
|};

type Index record {
    int v;
    json key;
    string name;
    string ns;
};
