<cfcomponent accessors="true">

	<cfproperty name="mongoFactory">

<cfscript>

	/**
	* initialize the MongoUtil. Pass an instance of JavaLoaderFactory to bypass the default MongoFactory
	  Using a JavaLoaderFactory lets you use the libs provided with cfmongodb without adding them to your
	  path and restarting CF
	*/
	function init(mongoFactory=""){
		if(isSimpleValue(mongoFactory)){
			arguments.mongoFactory = createObject("component", "DefaultFactory");
		}
		variables.mongoFactory = arguments.mongoFactory;
		variables.dboFactory = mongoFactory.getObject('com.mongodb.CFBasicDBObject');
		variables.dboBuilderFactory = mongoFactory.getObject('com.mongodb.CFBasicDBObjectBuilder');
		variables.typerClass = getTyperClass();
		variables.typer = mongoFactory.getObject(typerClass).getInstance();
	}

	/**
	* returns the CFStrictTyper.

		For Adobe ColdFusion, we need the CFStrictTyper because Adobe CF will treat numbers and booleans as strings.

		For Railo, we need the CFStrictTyper because Railo will treat integers as floats (i.e. 1 as 1.0), and sometimes treat numbers as strings, i.e. 1 as "1"
	*/
	public function getTyperClass(){
		return "net.marcesher.CFStrictTyper";
	}

	/**
	* Create a new instance of the CFBasicDBObject. You use these anywhere the Mongo Java driver takes a DBObject
	*/
	function newDBObject(){
		return dboFactory.newInstance(variables.typer);
	}

	/**
	* Create a new instance of a CFBasicDBObjectBuilder
	*/
	function newDBObjectBuilder(){
		return dboBuilderFactory.newInstance();
	}

	/**
	* Converts a ColdFusion structure to a CFBasicDBobject, which  the Java drivers can use
	*/
	function toMongo(any data){
		//for now, assume it's a struct to DBO conversion
		if( isCFBasicDBObject(data) ) return data;
		var dbo = newDBObject();
		dbo.putAll( data );
		return dbo;
	}

	/**
	* Converts a Mongo DBObject to a ColdFusion structure
	*/
	function toCF(BasicDBObject){
		var s = {};
		s.putAll(BasicDBObject);
		return s;
	}

	/**
	* Convenience for turning a string _id into a Mongo ObjectId object
	*/
	function newObjectIDFromID(String id){
		if( not isSimpleValue( id ) ) return id;
		return mongoFactory.getObject("org.bson.types.ObjectId").init(id);
	}

	/**
	* Convenience for creating a new criteria object based on a string _id
	*/
	function newIDCriteriaObject(String id){
		return newDBObject().put("_id",newObjectIDFromID(id));
	}

	/**
	* Creates a Mongo CFBasicDBObject whose order matches the order of the keyValues argument
	  keyValues can be:
	  	1) a string in k,k format: "STATUS,TS". This will set the value for each key to "1". Useful for creating Mongo's 'all true' structs, like the "keys" argument to group()
	    2) a string in k=v format: STATUS=1,TS=-1
		3) an array of strings in k=v format: ["STATUS=1","TS=-1"]
		4) an array of structs (often necessary when creating "command" objects for passing to db.command()):
		  createOrderedDBObject( [ {"mapreduce"="tasks"}, {"map"=map}, {"reduce"=reduce} ] )
	*/
	function createOrderedDBObject( keyValues ){
		var dbo = newDBObject();
		var kv = "";
		if( isSimpleValue(keyValues) ){
			keyValues = listToArray(keyValues);
		}
		for(kv in keyValues){
			if( isSimpleValue( kv ) ){
				var key = listFirst(kv, "=");
				var value = find("=",kv) ? listRest(kv, "=") : 1;
			} else {
				var key = structKeyList(kv);
				var value = kv[key];
			}

			dbo.append( key, value );
		}
		return dbo;
	}

	function listToStruct(list){
		var item = '';
		var s = {};
		var i = 1;
		var items = listToArray(list);
		var itemCount = arrayLen(items);
		for(i; i lte itemCount; i++) {
			s.put(items[i],1);
		}
		return s;
	}

	/**
	* Extracts the timestamp from the Doc's ObjectId. This represents the time the document was added to MongoDB
	*/
	function getDateFromDoc( doc ){
		var ts = doc["_id"].getTime();
		return createObject("java", "java.util.Date").init(ts);
	}

	/**
	* Whether this doc is an instance of a CFMongoDB CFBasicDBObject
	*/
	function isCFBasicDBObject( doc ){
		return NOT isSimpleValue( doc ) AND getMetadata( doc ).getCanonicalName() eq "com.mongodb.CFBasicDBObject";
	}
</cfscript>
</cfcomponent>