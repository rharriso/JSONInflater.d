module JSONInflater;

import std.stdio;
import std.json;
import std.traits;
import std.range;
import std.algorithm;
import std.array;
import std.conv;

/*
  Applly values form json object to ouput object
*/
void Unmarshall(T)(ref T obj, in JSONValue json){
  alias fnt = FieldNameTuple!T;

  // create map from name to type
  foreach(k; fnt){
    if(!(k in json)) continue;

    alias fieldType = typeof(__traits(getMember, obj, k));
    auto jsonField = json[k];

    static if(isBasicType!fieldType || isNarrowString!fieldType){

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

    } else {
      auto child = new fieldType;
      JSONInflater.Unmarshall(child, jsonField);
      __traits(getMember, obj, k) = child;
    }
  }
}

/*
  return json object for a given class
*/
JSONValue* Marshall(T)(in T inObj){
  alias fnt = FieldNameTuple!T;
  auto outJson = new JSONValue(parseJSON("{}"));
  
  // create map from name to type
  foreach(k; fnt){
    alias fieldType = typeof(__traits(getMember, inObj, k));

    static if(isBasicType!fieldType || isNarrowString!fieldType){
      outJson.object[k] = JSONValue(__traits(getMember, inObj, k));
    } else { // assume object
      writeln("doing i peter");
      auto child = new fieldType;
      outJson.object[k] = JSONInflater.Marshall!(fieldType)(child).object;
    }
  }

  return outJson;
}
