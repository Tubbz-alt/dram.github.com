#include <optional>
#include <string>

#include <boost/filesystem.hpp>

#include <libxml/tree.h>

#include <Python.h>

#include "sam.hpp"

std::optional<xmlDocPtr> sam_parse(boost::filesystem::path path) {
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
    char *buffer;
    Py_ssize_t length;
    PyBytes_AsStringAndSize(xml, &buffer, &length);
    return {xmlParseMemory(buffer, length)};
  }
}
