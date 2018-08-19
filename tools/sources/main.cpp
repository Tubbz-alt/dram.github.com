#include <experimental/filesystem>
#include <experimental/optional>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include <libxml/tree.h>

#include "render.hpp"
#include "sam.hpp"

struct post {
  std::string date, source, target, name, title;
};

static std::vector<struct post> posts;


bool source_modified(std::string source, std::string target) {
  struct stat source_stat, target_stat;

  stat(source.c_str(), &source_stat);

  if (stat(target.c_str(), &target_stat) == -1 && errno == ENOENT)
    return true;

  return source_stat.st_mtim.tv_sec > target_stat.st_mtim.tv_sec;
}

void generate_posts() {
  for (struct post p : posts) {
    if (source_modified(p.source, p.target)) {
      std::experimental::optional<std::string> xml = sam_parse(p.source);
      if (xml) {
	xmlDocPtr ptr = xmlParseMemory(xml.value().c_str(), xml.value().size());
	render_article(ptr, p.target, p.date);
      }
    }
  }
}

xmlDocPtr post_list(unsigned limit) {
  xmlDocPtr doc = xmlNewDoc((const xmlChar *)"1.0");
  xmlNodePtr root = xmlNewNode(nullptr, (const xmlChar *)"posts");
  xmlDocSetRootElement(doc, root);

  unsigned count = limit;
  if (limit == 0 || limit > posts.size())
    count = posts.size();

  for (unsigned i = 0; i < count; ++i) {
    xmlNodePtr node = xmlNewChild(root, nullptr, (const xmlChar *)"post", nullptr);

    const xmlChar *p = xmlEncodeEntitiesReentrant(doc, (const xmlChar *)posts[i].title.c_str());
    xmlNewChild(node, nullptr, (const xmlChar *)"title", p);
    xmlNewChild(node, nullptr, (const xmlChar *)"creation-date", (const xmlChar *)posts[i].date.c_str());
    xmlNewChild(node, nullptr, (const xmlChar *)"uri", (const xmlChar *)('/' + posts[i].target).c_str());
  }

  return doc;
}


void generate_pages() {
  std::vector<std::experimental::filesystem::path> directories = {"blog", "logo"};

  for (std::experimental::filesystem::path directory : directories) {
    for (std::experimental::filesystem::directory_entry entry : std::experimental::filesystem::directory_iterator("_sources/pages" / directory)) {
      std::string source = entry.path();
      std::experimental::filesystem::path path = entry.path();
      std::string target = directory / path.replace_extension(".html").filename();

      if (source_modified(source, target)) {
	std::experimental::optional<std::string> xml = sam_parse(source);

	if (xml) {
	  xmlDocPtr ptr = xmlParseMemory(xml.value().c_str(), xml.value().size());
	  render_article(ptr, target, std::experimental::nullopt);
	}
      }
    }
  }
}

void sort_posts() {
  struct post p;

  for (unsigned i = 0; i < posts.size(); ++i) {
    for (unsigned j = i; j < posts.size(); ++j) {
      if (posts[j].source > posts[i].source) {
	p = posts[i];
	posts[i] = posts[j];
	posts[j] = p;
      }
    }
  }
}

int main(void) {
  for (std::experimental::filesystem::directory_entry entry : std::experimental::filesystem::directory_iterator("_sources/posts")) {
    struct post post;

    post.source = entry.path();

    std::string name = entry.path().filename();
    post.date = name.substr(0, 10);
    post.name = name.substr(11, name.size() - 15);

    post.target = "blog/"
      + post.date.substr(0, 4) // year
      + '/' + post.date.substr(5, 2) // month
      + '/' + post.date.substr(8, 2) // day
      + '/' + post.name + ".html";

    std::ifstream in(post.source);
    std::getline(in, post.title);
    in.close();
    post.title = post.title.substr(9, post.title.size() - 9);

    posts.push_back(post);
  }

  generate_posts();
  generate_pages();

  sort_posts();

  render_home(post_list(10), "index.html");
  render_archive(post_list(0), "blog/archive.html");
}
