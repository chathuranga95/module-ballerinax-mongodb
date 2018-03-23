/*
 * Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package org.ballerinalang.data.mongodb.actions;

import org.ballerinalang.bre.Context;
import org.ballerinalang.data.mongodb.Constants;
import org.ballerinalang.data.mongodb.MongoDBDataSource;
import org.ballerinalang.model.types.TypeKind;
import org.ballerinalang.model.values.BJSON;
import org.ballerinalang.model.values.BStruct;
import org.ballerinalang.natives.annotations.Argument;
import org.ballerinalang.natives.annotations.BallerinaFunction;
import org.ballerinalang.natives.annotations.Receiver;
import org.ballerinalang.natives.annotations.ReturnType;


/**
 * {@code Find} action select documents in a collection.
 *
 * @since 0.95.0
 */
@BallerinaFunction(
            orgName = "ballerina",
            packageName = "data.mongodb",
            functionName = "find",
            receiver = @Receiver(type = TypeKind.STRUCT, structType = "ClientConnector"),
            args = { @Argument(name = "collectionName", type = TypeKind.STRING),
                    @Argument(name = "queryString", type = TypeKind.JSON)
            },
            returnType = { @ReturnType(type = TypeKind.JSON) }
        )
public class Find extends AbstractMongoDBAction {

    @Override
    public void execute(Context context) {
        BStruct bConnector = (BStruct) context.getRefArgument(0);
        String collectionName = context.getStringArgument(0);
        BJSON query = (BJSON) context.getNullableRefArgument(1);
        MongoDBDataSource datasource = (MongoDBDataSource) bConnector.getNativeData(Constants.CLIENT_CONNECTOR);
        BJSON result = find(datasource, collectionName, query);
        context.setReturnValues(result);
    }
}
