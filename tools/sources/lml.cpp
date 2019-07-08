#include <cctype>
#include <fstream>
#include <iostream>
#include <optional>
#include <string>
#include <vector>

#include <boost/filesystem.hpp>
#include <boost/filesystem/fstream.hpp>

#include <Python.h>

#include "lml.hpp"
#include "xml.hpp"

typedef std::string Source;
typedef std::string Text;
typedef xmlNodePtr Node;

struct ParseNodeResult {
  Node value;
  Source rest;
};

struct ParseNodesResult {
  std::vector<Node> value;
  Source rest;
};

struct ParseTextResult {
  Text value;
  Source rest;
};

static Source skip_spaces(Source source);
static ParseTextResult parse_word(Source source);
static ParseNodeResult parse_node(Source source);
static ParseNodesResult parse_nodes(Source source);

std::optional<xmlDocPtr> lml_parse(boost::filesystem::path path) {
  std::string source{
      std::istreambuf_iterator<char>{boost::filesystem::ifstream{path}.rdbuf()},
      {}};

  ParseNodesResult nodes = parse_nodes(source);

  xmlDocPtr doc = xmlNewDoc("1.0"_xml);
  xmlDocSetRootElement(doc, nodes.value[0]);

  return doc;
}

static ParseNodesResult parse_nodes(Source source) {
  std::vector<Node> nodes;

  Source rest = source;
  while (true) {
    rest = skip_spaces(rest);

    if (rest.empty() || rest[0] == ']')
      break;

    ParseNodeResult node = parse_node(rest);
    nodes.push_back(node.value);
    rest = node.rest;
  }

  return {nodes, rest};
}

static ParseNodeResult parse_node(Source source) {
  auto parse_text = [](Source source, Text sentinel) -> ParseTextResult {
    for (size_t start = 0; start < source.size(); ++start) {
      if (source.size() - start < sentinel.size()) {
        throw;
      } else if (source.substr(start, sentinel.size()) == sentinel) {
        return {source.substr(0, start),
                source.substr(start + sentinel.size(),
                              source.size() - start - sentinel.size())};
      }
    }
    throw;
  };

  auto parse_value = [](Source source) -> ParseTextResult {
    Text value;
    for (size_t i = 0; i < source.size(); ++i) {
      if (source[i] == ']')
        return {value, source.substr(i)};
      value.push_back(source[i]);
    }
    throw;
  };

  if (source.size() > 1 && source[0] == '[' && source[1] == '-') {
    // Parsing `[- ... -]'
    size_t needle = 2;
    std::string sentinel = "-]";
    for (size_t i = needle; i < source.size(); ++i) {
      if (source[i] != '-') {
        sentinel = std::string(i - needle, '-') + sentinel;
        needle = i;
        break;
      }
    }

    Source rest = source.substr(needle);
    if (rest.empty()) {
      throw;
    } else if (std::isspace(rest[0])) {
      ParseTextResult text = parse_text(skip_spaces(rest), sentinel);
      return {xmlNewText(xml_string(text.value)), text.rest};
    } else {
      ParseTextResult tag = parse_word(rest);
      ParseTextResult text = parse_text(skip_spaces(tag.rest), sentinel);
      Node node = xmlNewNode(nullptr, xml_string(tag.value));
      xmlAddChild(node, xmlNewText(xml_string(text.value)));
      return {node, text.rest};
    }
  } else if (source.size() > 0 && source[0] == '[') {
    // Parsing `[ ... ]'
    struct Attribute {
      Text name;
      Text value;
    };

    ParseTextResult tag = parse_word(source.substr(1));

    std::vector<Attribute> attributes;
    Source rest = tag.rest;
    while (true) {
      ParseTextResult name = parse_word(skip_spaces(rest));
      if (name.value.empty() || name.value[0] != '-' || name.rest.empty() ||
          name.rest[0] != '[')
        break;
      ParseTextResult value = parse_value(name.rest.substr(1));
      attributes.push_back({name.value.substr(1), value.value});
      rest = value.rest.substr(1);
    }

    ParseNodesResult nodes = parse_nodes(rest);

    if (nodes.rest.empty() || nodes.rest[0] != ']')
      throw;

    Node node = xmlNewNode(nullptr, xml_string(tag.value));
    for (Attribute attr : attributes)
      xmlSetProp(node, xml_string(attr.name), xml_string(attr.value));
    for (Node child : nodes.value)
      xmlAddChild(node, child);
    return {node, nodes.rest.substr(1)};
  } else {
    std::string text;
    for (size_t i = 0; i < source.size(); ++i) {
      char c = source[i];
      if (c == '[' || c == ']')
        return {xmlNewText(xml_string(text)), source.substr(i)};
      text.push_back(c);
    }
    return {xmlNewText(xml_string(text)), ""};
  }
}

static Source skip_spaces(Source source) {
  size_t needle = 0;
  while (needle < source.size() && std::isspace(source[needle]))
    needle += 1;
  return source.substr(needle);
}

static ParseTextResult parse_word(Source source) {
  std::string word;
  for (size_t i = 0; i < source.size(); ++i) {
    char c = source[i];
    if (c == '[' || c == ']' || std::isspace(c))
      return {word, source.substr(i)};
    word.push_back(c);
  }
  return {"", ""};
}
