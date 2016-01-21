##JSONInflater

This library is intended to create a simple to use interface for creating objects from JSON strings, and outputting json strings via compile time reflection.

See [app.d](https://github.com/rharriso/JSONInflater.d/blob/master/source/app.d) for a simple demonstration

## Build and run

Here is the command I've been using the build and run this projects app file

```
dub build --build=debug --compiler=ldc && ./jsoninflater 

```

## ToDo

I still need to work on some other things before relasing it.

* [x] Recursive parsing. (nested objects)
* [x] Arrays
* [ ] Tests
* [ ] Benchmarks
