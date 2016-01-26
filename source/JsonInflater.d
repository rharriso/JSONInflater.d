module JSONInflater;

import std.stdio;
import std.json;
import std.traits;
import std.range;
import std.algorithm;
import std.array;
import std.conv;
import std.typecons;

/*
   Applly values form json object to ouput object
 */
void Unmarshall(T)(ref T obj, in JSONValue json){
  // handle arrays
  static if(isDynamicArray!T){
    foreach(el ; json.array){
      auto child = new ElementType!T;
      JSONInflater.Unmarshall(child, el);
      obj ~= child;
    }
  
  } else static if(isStaticArray!T){
    assert(false, "not supporting static right now");
  } else {
    // initialize object if not done so
    if(obj is null){
      obj = new T();
    }

    // handle signular elements
    enum auto fnt = FieldNameTuple!T;

    // create map from name to type
    foreach(k; fnt){
      if(!(k in json.object)) continue;

      alias fieldType = typeof(__traits(getMember, T, k));
      enum isBasic  = isBasicType!fieldType || isNarrowString!fieldType;
      enum isSArray = isStaticArray!fieldType;
      enum isDArray = isDynamicArray!fieldType;
      enum isAgg    = isAggregateType!fieldType;

      auto jsonField = json[k];

      static if(isBasic){

        switch(jsonField.type){
          case JSON_TYPE.INTEGER:
            __traits(getMember, obj, k) = to!(fieldType)(jsonField.integer);
            break;
          case JSON_TYPE.FLOAT:
            __traits(getMember, obj, k) = to!(fieldType)(jsonField.floating);
            break;
          case JSON_TYPE.STRING:
            __traits(getMember, obj, k) = to!(fieldType)(jsonField.str);
            break;
          default:
            assert(false, "Don't know how to handle type");
        }

      } else static if(isSArray){
        std.stdio.stderr.writeln("Don't support static arrays"); 

      } else static if(isDArray){
        JSONInflater.Unmarshall(__traits(getMember, obj, k), jsonField);

      } else static if(isAgg){
        auto child = new fieldType;
        JSONInflater.Unmarshall(child, jsonField);
        __traits(getMember, obj, k) = child;
      
      } else{
        writeln(fieldType.stringof);
        assert(false, "couldn't handle type");
     }
    }
  }
}

/*
   return json object for a given class
 */
JSONValue* Marshall(T)(in T inObj){
  // handle arrays
  if(inObj is null){
    return new JSONValue();
  } else static if(isArray!T){
    auto outJson = new JSONValue(parseJSON("[]"));
    foreach(el ; inObj){
      auto child = JSONInflater.Marshall(el);
      outJson.array ~= *child;
    }
    return outJson;

  } else {
    enum auto fnt = FieldNameTuple!T;
    auto outJson = new JSONValue(parseJSON("{}"));

    // create map from name to type
    foreach(k; fnt){
      auto whatever = k;
      alias fieldType = typeof(__traits(getMember, T, k));

      static if(isBasicType!fieldType || isNarrowString!fieldType){
        outJson.object[k] = JSONValue(__traits(getMember, inObj, k));

      } else static if(isArray!fieldType){
        auto child = JSONInflater.Marshall!(fieldType)(__traits(getMember, inObj, k));
        if (child.type != std.json.JSON_TYPE.NULL)
          outJson.object[k] = child.array;

      } else static if(isAggregateType!fieldType){
        auto child = JSONInflater.Marshall!(fieldType)(__traits(getMember, inObj, k));
        if (child.type != std.json.JSON_TYPE.NULL)
          outJson.object[k] = child.object;
      } else {
        assert(false, "can't handle this type");
      }
    }
    
    return outJson;
  }
}




class TestObj{
  int id;
  string name;
}

class TestObj2{
  int id;
  string name;
  string favoriteColor;
  string favoriteSport;
  TestObj testy;
  TestObj[] children;
}
///
/// UnitTest
///
unittest{

  auto json_s = `{"id": 7, "name": "Really cool Guy"}`;
  auto inObj = new TestObj2();
  inObj.id = 8;
  inObj.name = "Really cool Guy is cool";
  inObj.favoriteSport = "Basketball";
  inObj.favoriteColor = "red";
  JSONInflater.Unmarshall(inObj.testy, parseJSON(`{"id": 9, "name": "Really cool Guy"}`));
  JSONInflater.Unmarshall(inObj.children, parseJSON(`[
       {"id": 10, "name": "Guy Foreal"},
       {"id": 11, "name": "Derick 4Real"}
  ]`));
   
  
  auto json = JSONInflater.Marshall(inObj);
  TestObj2 to2 = new TestObj2();
  JSONInflater.Unmarshall(to2, *json);
  
  assert(to2.id == 8, "object id should be set");
  assert(to2.name == "Really cool Guy is cool", "object name should be set");
  assert(to2.favoriteSport == "Basketball", "object sport should be set");
  assert(to2.favoriteColor == "red", "object color should be set");
  assert(to2.testy.id == 9, "child id should be set");
  assert(to2.testy.name == "Really cool Guy", "child name");
  assert(to2.children.length == 2, "subarray length");
  assert(to2.children[0].id == 10, "subarray id");
  assert(to2.children[0].name == "Guy Foreal", "subarray name");
  assert(to2.children[1].id == 11, "subarray id");
  assert(to2.children[1].name == "Derick 4Real", "subarray name");
}
