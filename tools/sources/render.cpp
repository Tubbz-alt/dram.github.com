#include <experimental/optional>
#include <vector>

#include <libexslt/exslt.h>
#include <libxslt/xslt.h>
#include <libxslt/transform.h>

#include "render.hpp"

static bool initialized = false;

static xsltStylesheetPtr article_stylesheet, main_stylesheet, archive_stylesheet, home_stylesheet;

void render_initialize() {
  exsltDateRegister();

  main_stylesheet = xsltParseStylesheetFile((const xmlChar *)"tools/stylesheets/main.xsl");
  article_stylesheet = xsltParseStylesheetFile((const xmlChar *)"tools/stylesheets/article.xsl");
  home_stylesheet = xsltParseStylesheetFile((const xmlChar *)"tools/stylesheets/home.xsl");
  archive_stylesheet = xsltParseStylesheetFile((const xmlChar *)"tools/stylesheets/archive.xsl");

  initialized = true;
}

void render_article(xmlDocPtr content, std::string output, std::experimental::optional<std::string> date) {
  if (!initialized)
    render_initialize();

  std::vector<const char *> params = {nullptr};
  if (date) {
    params.insert(params.begin(), ('"' + date.value() + '"').c_str());
    params.insert(params.begin(), "date");
  }

  xmlDocPtr p = xsltApplyStylesheet(article_stylesheet, content, &params[0]);

  xsltRunStylesheetUser(main_stylesheet,
			p,
			nullptr,
			output.c_str(),
			nullptr, nullptr, nullptr, nullptr);
}

void render_main(xmlDocPtr content, std::string output, std::experimental::optional<std::string> title) {
  if (!initialized)
    render_initialize();

  std::vector<const char *> params = {nullptr};

  if (title) {
    params.insert(params.begin(), ('"' + title.value() + '"').c_str());
    params.insert(params.begin(), "title");
  }

  xsltRunStylesheetUser(main_stylesheet,
			content,
			&params[0],
			output.c_str(),
			nullptr, nullptr, nullptr, nullptr);
}

void render_home(xmlDocPtr posts, std::string output) {
  if (!initialized)
    render_initialize();

  xmlDocPtr p = xsltApplyStylesheet(home_stylesheet, posts, nullptr);
  render_main(p, output, "dram.me");
}

void render_archive(xmlDocPtr posts, std::string output) {
  if (!initialized)
    render_initialize();

  xmlDocPtr p = xsltApplyStylesheet(archive_stylesheet, posts, nullptr);
  render_main(p, output, "Archive");
}
