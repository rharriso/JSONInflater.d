module JSONInflater;

import std.stdio;
import std.json;
import std.traits;
import std.range;
import std.algorithm;
import std.array;
import std.conv;

enum JSONTypes{
  intVal, floatVal, stringVal
}

void Unmarshall(T)(ref T outObj, JSONValue json){
  alias fnt = FieldNameTuple!T;
  alias ftt = FieldTypeTuple!T;
  alias JSONTypes[string] fields;

  // create map from name to type
  foreach(k; fnt){

    alias fieldType = typeof(__traits(getMember, outObj, k));
    auto jsonField = json[k];

    switch(jsonField.type){
      case JSON_TYPE.INTEGER:
        //__traits(getMember, obj, k) = to!(fieldType)(json[k].integer);
        __traits(getMember, outObj, k) = to!(fieldType)(1);
        break;
      case JSON_TYPE.FLOAT:
        //__traits(getMember, obj, k) = to!(fieldType)(json[k].floating);
        __traits(getMember, outObj, k) = to!(fieldType)(1.7);
        break;
      case JSON_TYPE.STRING:
        //__traits(getMember, obj, k) = to!(fieldType)(json[k].str);
        __traits(getMember, outObj, k) = to!(fieldType)("AHAHA");
        break;
      default:
        writefln("Don't know how to handle: %s", jsonField.type);
    }
  }
}
