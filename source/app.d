import std.stdio;
import std.json;
import JSONInflater;

void main()
{
  TestObj to;
  auto json_s = `{"id": "7", "name": "Really cool Guy"}`;
  auto json_v = std.json.parseJSON(json_s);
  auto t = typeof(to).stringof;

  JSONInflater.Marshall(to, json_v);
}

class TestObj{
  string id;
  string name;
}
