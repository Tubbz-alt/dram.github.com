#include <vector>

#include <boost/filesystem.hpp>
#include <boost/optional.hpp>

#include <libexslt/exslt.h>
#include <libxslt/transform.h>
#include <libxslt/xslt.h>

#include "render.hpp"
#include "xml.hpp"

static void render_main(xmlDocPtr content, boost::filesystem::path output,
                        boost::optional<std::string> title);

void ensure_extension_loaded() {
  static bool loaded = false;

  if (!loaded) {
    exsltDateRegister();
    loaded = true;
  }
}

void render_article(xmlDocPtr content, boost::filesystem::path output,
                    boost::optional<std::string> date) {
  ensure_extension_loaded();

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

  render_main(p, output, boost::none);
}

void render_home(xmlDocPtr posts, boost::filesystem::path output) {
  ensure_extension_loaded();

  static xsltStylesheetPtr style =
      xsltParseStylesheetFile("tools/stylesheets/home.xsl"_xml);

  xmlDocPtr p = xsltApplyStylesheet(style, posts, nullptr);
  render_main(p, output, std::string{"dram.me"});
}

void render_archive(xmlDocPtr posts, boost::filesystem::path output) {
  ensure_extension_loaded();

  static xsltStylesheetPtr style =
      xsltParseStylesheetFile("tools/stylesheets/archive.xsl"_xml);

  xmlDocPtr p = xsltApplyStylesheet(style, posts, nullptr);
  render_main(p, output, std::string{"Archive"});
}

static void render_main(xmlDocPtr content, boost::filesystem::path output,
                        boost::optional<std::string> title) {
  ensure_extension_loaded();

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
