#include <optional>
#include <vector>

#include <libexslt/exslt.h>
#include <libxslt/transform.h>
#include <libxslt/xslt.h>

#include "render.hpp"

static bool initialized = false;

void render_initialize() {
  exsltDateRegister();

  initialized = true;
}

void render_article(xmlDocPtr content, std::string output,
                    std::optional<std::string> date) {
  if (!initialized)
    render_initialize();

  std::string quoted;
  std::vector<const char *> params;
  if (date) {
    quoted = '"' + date.value() + '"';
    params = {"date", quoted.c_str(), nullptr};
  } else {
    params = {nullptr};
  }

  static xsltStylesheetPtr style =
      xsltParseStylesheetFile("tools/stylesheets/article.xsl"_xml);

  xmlDocPtr p = xsltApplyStylesheet(style, content, &params[0]);

  render_main(p, output, std::nullopt);
}

void render_main(xmlDocPtr content, std::string output,
                 std::optional<std::string> title) {
  if (!initialized)
    render_initialize();

  std::string quoted;
  std::vector<const char *> params;
  if (title) {
    quoted = '"' + title.value() + '"';
    params = {"title", quoted.c_str(), nullptr};
  } else {
    params = {nullptr};
  }

  static xsltStylesheetPtr style =
      xsltParseStylesheetFile("tools/stylesheets/main.xsl"_xml);

  xsltRunStylesheetUser(style, content, &params[0], output.c_str(), nullptr,
                        nullptr, nullptr, nullptr);
}

void render_home(xmlDocPtr posts, std::string output) {
  if (!initialized)
    render_initialize();

  static xsltStylesheetPtr style =
      xsltParseStylesheetFile("tools/stylesheets/home.xsl"_xml);

  xmlDocPtr p = xsltApplyStylesheet(style, posts, nullptr);
  render_main(p, output, "dram.me");
}

void render_archive(xmlDocPtr posts, std::string output) {
  if (!initialized)
    render_initialize();

  static xsltStylesheetPtr style =
      xsltParseStylesheetFile("tools/stylesheets/archive.xsl"_xml);

  xmlDocPtr p = xsltApplyStylesheet(style, posts, nullptr);
  render_main(p, output, "Archive");
}
