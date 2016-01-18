import std.stdio;
import std.json;
import JSONInflater;

void main()
{
  auto json_s = `{"id": 7, "name": "Really cool Guy"}`;
  auto json_s2 = `
   {"id": 7,
    "name": "Really cool Guy is cool",
    "favoriteSport": "Basketball",
    "favoriteColor": "red"}`;
  auto json_v = std.json.parseJSON(json_s);
  auto json_v2 = std.json.parseJSON(json_s2);

  TestObj to = new TestObj();
  TestObj2 to2 = new TestObj2();
  JSONInflater.Unmarshall(to, json_v);
  JSONInflater.Unmarshall(to2, json_v2);

  writeln(to);
  writeln(to2);
}

class TestObj{
  int id = 0;
  string name = "";
}

class TestObj2{
  int id;
  string name;
  string favoriteColor;
  string favoriteSport;
}
