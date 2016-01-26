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
  enum isArray = isDynamicArray!T; 

  // handle arrays
  static if(isArray){
    foreach(el ; json.array){
      auto child = new ElementType!T;
      JSONInflater.Unmarshall(child, el);
      obj ~= child;
    }

  } else {
    // handle signular elements
    enum auto fnt = FieldNameTuple!T;

    // create map from name to type
    foreach(k; fnt){
      if(!(k in json)) continue;

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
            writefln("Don't know how to handle: %s", jsonField.type);
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
  static if(isArray!T){
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
      alias fieldType = typeof(__traits(getMember, T, k));
      enum  isBasic   = isBasicType!fieldType;
      enum isArray    = isArray!fieldType;
      enum isAgg      = isAggregateType!fieldType;

      static if(isBasic || isNarrowString!fieldType){
        outJson.object[k] = JSONValue(__traits(getMember, inObj, k));

      } else static if(isArray){
        outJson.object[k] = 
          JSONInflater.Marshall!(fieldType)(__traits(getMember, inObj, k)).array;

      } else static if(isAgg){
        outJson.object[k] =
          JSONInflater.Marshall!(fieldType)(__traits(getMember, inObj, k)).object;
      } else {

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
  auto json_s2 = `
   {"id": 8,
    "name": "Really cool Guy is cool",
    "favoriteSport": "Basketball",
    "favoriteColor": "red",
    "testy": {"id": 9, "name": "Really cool Guy"},
    "children": [
       {"id": 10, "name": "Guy Foreal"},
       {"id": 11, "name": "Derick 4Real"}
    ]
   }`;
  
  auto json_v = std.json.parseJSON(json_s);
  auto json_v2 = std.json.parseJSON(json_s2);

  TestObj to = new TestObj();
  TestObj2 to2 = new TestObj2();
  JSONInflater.Unmarshall(to, json_v);
  JSONInflater.Unmarshall(to2, json_v2);

  assert(to2.id == 8);
  assert(to2.name == "Really cool Guy is cool");
  assert(to2.favoriteSport == "Basketball");
  assert(to2.favoriteColor == "red");
  assert(to2.testy.id == 9);
  assert(to2.testy.name == "Really cool Guy");
  assert(to2.children.length == 2);
  assert(to2.children[0].id == 10);
  assert(to2.children[0].name == "Guy Foreal");
  assert(to2.children[1].id == 11);
  assert(to2.children[1].name == "Derick 4Real");
}
