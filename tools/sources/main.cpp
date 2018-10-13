#include <algorithm>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <optional>
#include <string>
#include <vector>

#include <libxml/tree.h>

#include "render.hpp"
#include "sam.hpp"

struct post {
  std::string date, source, target, name, title;
};

static std::vector<struct post> posts;

bool source_modified(std::string source, std::string target) {
  std::filesystem::file_time_type source_time, target_time;

  source_time = std::filesystem::last_write_time(source);

  try {
    target_time = std::filesystem::last_write_time(target);
    return source_time > target_time;
  } catch (...) {
    return true;
  }
}

void generate_posts() {
  for (struct post p : posts) {
    if (source_modified(p.source, p.target)) {
      std::optional<std::string> xml = sam_parse(p.source);
      if (xml) {
        xmlDocPtr ptr = xmlParseMemory(xml.value().c_str(), xml.value().size());
        render_article(ptr, p.target, p.date);
      }
    }
  }
}

xmlDocPtr post_list(std::optional<size_t> limit) {
  xmlDocPtr doc = xmlNewDoc((const xmlChar *)"1.0");
  xmlNodePtr root = xmlNewNode(nullptr, (const xmlChar *)"posts");
  xmlDocSetRootElement(doc, root);

  size_t count;

  if (limit)
    count = std::min(limit.value(), posts.size());
  else
    count = posts.size();

  for (unsigned i = 0; i < count; ++i) {
    xmlNodePtr node =
        xmlNewChild(root, nullptr, (const xmlChar *)"post", nullptr);

    const xmlChar *p = xmlEncodeEntitiesReentrant(
        doc, (const xmlChar *)posts[i].title.c_str());
    xmlNewChild(node, nullptr, (const xmlChar *)"title", p);
    xmlNewChild(node, nullptr, (const xmlChar *)"creation-date",
                (const xmlChar *)posts[i].date.c_str());
    xmlNewChild(node, nullptr, (const xmlChar *)"uri",
                (const xmlChar *)('/' + posts[i].target).c_str());
  }

  return doc;
}

void generate_pages() {
  std::vector<std::filesystem::path> directories = {"blog", "logo"};

  for (std::filesystem::path directory : directories) {
    for (std::filesystem::directory_entry entry :
         std::filesystem::directory_iterator("_sources/pages" / directory)) {
      std::string source = entry.path();
      std::filesystem::path path = entry.path();
      std::string target =
          directory / path.replace_extension(".html").filename();

      if (source_modified(source, target)) {
        std::optional<std::string> xml = sam_parse(source);

        if (xml) {
          xmlDocPtr ptr =
              xmlParseMemory(xml.value().c_str(), xml.value().size());
          render_article(ptr, target, std::nullopt);
        }
      }
    }
  }
}

int main(void) {
  for (std::filesystem::directory_entry entry :
       std::filesystem::directory_iterator("_sources/posts")) {
    struct post post;

    post.source = entry.path();

    std::string name = entry.path().filename();
    post.date = name.substr(0, 10);
    post.name = name.substr(11, name.size() - 15);

    post.target = "blog/" + post.date.substr(0, 4) // year
                  + '/' + post.date.substr(5, 2)   // month
                  + '/' + post.date.substr(8, 2)   // day
                  + '/' + post.name + ".html";

    std::ifstream in(post.source);
    std::getline(in, post.title);
    in.close();
    post.title = post.title.substr(9, post.title.size() - 9);

    posts.push_back(post);
  }

  generate_posts();
  generate_pages();

  std::sort(posts.begin(), posts.end(),
            [](struct post a, struct post b) { return a.source > b.source; });

  render_home(post_list(10), "index.html");
  render_archive(post_list(std::nullopt), "blog/archive.html");
}
