import std.stdio;
import std.json;
import JSONInflater;

void main()
{
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

  writeln(JSONInflater.Marshall(to).toString());
  writeln(JSONInflater.Marshall(to2).toString());
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
