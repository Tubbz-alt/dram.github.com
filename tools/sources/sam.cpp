#include <optional>
#include <string>

#include <Python.h>

#include "sam.hpp"

std::optional<std::string> sam_parse(std::string path) {
  static PyObject *globals = nullptr;

  if (globals == nullptr) {
    Py_Initialize();

    globals = PyDict_New();

    PyDict_SetItemString(globals, "__builtins__", PyEval_GetBuiltins());

    PyRun_String("import sys;"
                 "sys.path.append('tools/sam');"
                 "import samparser",
                 Py_file_input, globals, nullptr);
  }

  PyRun_String(
      ("p = samparser.SamParser(); p.parse_file('" + path + "')").c_str(),
      Py_file_input, globals, nullptr);

  PyObject *obj = PyRun_String("b''.join(p.doc.serialize_xml())", Py_eval_input,
                               globals, nullptr);

  if (obj == nullptr) {
    PyErr_Print();
    return std::nullopt;
  } else {
    return std::optional<std::string>{PyBytes_AsString(obj)};
  }
}
