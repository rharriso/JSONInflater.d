module json_inflater;

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
void unmarshall(T)(ref T obj, in JSONValue json)
{
    // handle arrays
    static if (isArray!T)
    {
        auto jArr = json.array();

        static if (isStaticArray!T)
        {
            assert(obj.length == jArr.length, "Array Size Mismatch obj");
        }

        for (int i = 0; i < json.array.length; i++)
        {
            auto child = new ElementType!T;
            json_inflater.unmarshall(child, jArr[i]);
            static if (isDynamicArray!T)
            {
                obj ~= child;
            }
            else
            {
                obj[i] = child;
            }
        }

    }
    else static if (isStaticArray!T)
    {
        assert(false, "not supporting static right now");
    }
    else
    {
        // initialize object if not done so
        if (obj is null)
        {
            obj = new T();
        }

        // handle signular elements
        enum auto fnt = FieldNameTuple!T;

        // create map from name to type
        foreach (k; fnt)
        {
            if (!(k in json.object))
                continue;

            alias fieldType = typeof(__traits(getMember, T, k));
            auto jsonField = json[k];

            static if (isBasicType!fieldType || isNarrowString!fieldType)
            {

                switch (jsonField.type)
                {
                case JSON_TYPE.INTEGER:
                    __traits(getMember, obj,
                        k) = to!(fieldType)(jsonField.integer);
                    break;
                case JSON_TYPE.FLOAT:
                    __traits(getMember, obj,
                        k) = to!(fieldType)(jsonField.floating);
                    break;
                case JSON_TYPE.STRING:
                    __traits(getMember, obj, k) = to!(fieldType)(jsonField.str);
                    break;
                default:
                    assert(false, "Don't know how to handle type");
                }

            }
            else static if (isArray!fieldType)
            {
                json_inflater.unmarshall(__traits(getMember, obj, k), jsonField);

            }
            else static if (isAggregateType!fieldType)
            {
                auto child = new fieldType;
                json_inflater.unmarshall(child, jsonField);
                __traits(getMember, obj, k) = child;

            }
            else
            {
                assert(false, "couldn't handle type");
            }
        }
    }
}

/*
   return json object for a given class
 */
JSONValue* marshall(T)(in T inObj)
{
    // handle arrays
    static if (isArray!T)
    {
        auto outJson = new JSONValue(parseJSON("[]"));
        foreach (el; inObj)
        {
            auto child = json_inflater.marshall(el);
            outJson.array ~= *child;
        }

    }
    else static if (isAggregateType!T)
    {
        enum auto fnt = FieldNameTuple!T;
        auto outJson = new JSONValue(parseJSON("{}"));

        // create map from name to type
        foreach (k; fnt)
        {
            alias fieldType = typeof(__traits(getMember, T, k));

            static if (isBasicType!fieldType || isNarrowString!fieldType)
            {
                outJson.object[k] = JSONValue(__traits(getMember, inObj, k));

            }
            else static if (isArray!fieldType)
            {
                auto child = json_inflater.marshall!(fieldType)(__traits(getMember,
                    inObj, k));
                if (child.type != std.json.JSON_TYPE.NULL)
                    outJson.object[k] = child.array;

            }
            else static if (isAggregateType!fieldType)
            {
                auto child = json_inflater.marshall!(fieldType)(__traits(getMember,
                    inObj, k));
                if (child.type != std.json.JSON_TYPE.NULL)
                    outJson.object[k] = child.object;
            }
            else
            {
                assert(false, "can't handle this type");
            }
        }
    }
    else
    {
        // asume null
        auto outJson = new JSONValue();
    }

    return outJson;
}

///
/// UnitTest
///
unittest
{
    static class TestObj
    {
        int id;
        string name;
    }

    static class TestObj2
    {
        int id;
        string name;
        string favoriteColor;
        string favoriteSport;
        TestObj testy;
        TestObj[] children;
    }

    auto inObj = new TestObj2();
    inObj.id = 8;
    inObj.name = "Really cool Guy is cool";
    inObj.favoriteSport = "Basketball";
    inObj.favoriteColor = "red";
    json_inflater.unmarshall(inObj.testy, parseJSON(`{"id": 9, "name": "Really cool Guy"}`));
    json_inflater.unmarshall(inObj.children, parseJSON(`[
       {"id": 10, "name": "Guy Foreal"},
       {"id": 11, "name": "Derick 4Real"}
  ]`));

    auto json = json_inflater.marshall(inObj);
    TestObj2 to2 = new TestObj2();
    json_inflater.unmarshall(to2, *json);

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

    TestObj[2] tp;
    json_inflater.unmarshall(tp, parseJSON(`[
       {"id": 10, "name": "Guy Foreal"},
       {"id": 11, "name": "Derick 4Real"}
  ]`));
    TestObj[2] testPair;
    json_inflater.unmarshall(testPair, *json_inflater.marshall(tp));

    assert(testPair[0].id == 10, "subarray id");
    assert(testPair[0].name == "Guy Foreal", "subarray name");
    assert(testPair[1].id == 11, "subarray id");
    assert(testPair[1].name == "Derick 4Real", "subarray name");
}
