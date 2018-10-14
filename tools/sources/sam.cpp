#include <optional>
#include <string>

#include <Python.h>

#include "sam.hpp"

std::optional<std::string> sam_parse(std::string path) {
  static PyObject *parser = nullptr;

  if (parser == nullptr) {
    Py_Initialize();

    PyObject_CallMethod(PySys_GetObject("path"), "append", "s", "tools/sam");
    parser = PyObject_CallMethod(PyImport_ImportModule("samparser"),
                                 "SamParser", nullptr);
  }

  PyObject_CallMethod(parser, "parse_file", "s", path.c_str());
  PyObject *xml = PyObject_CallMethod(
      PyBytes_FromString(""), "join", "O",
      PyObject_CallMethod(PyObject_GetAttrString(parser, "doc"),
                          "serialize_xml", nullptr));

  if (xml == nullptr) {
    PyErr_Print();
    return std::nullopt;
  } else {
    return {PyBytes_AsString(xml)};
  }
}
