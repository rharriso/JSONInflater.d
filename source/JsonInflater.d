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

    switch(jsonField.type){
      case JSON_TYPE.INTEGER:
        __traits(getMember, obj, k) = to!(fieldType)(json[k].integer);
        break;
      case JSON_TYPE.FLOAT:
        __traits(getMember, obj, k) = to!(fieldType)(json[k].floating);
        break;
      case JSON_TYPE.STRING:
       __traits(getMember, obj, k) = to!(fieldType)(json[k].str);
        break;
      default:
        writefln("Don't know how to handle: %s", jsonField.type);
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
    outJson.object[k] = JSONValue(__traits(getMember, inObj, k));
  }

  return outJson;
}
