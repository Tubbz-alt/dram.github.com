#!/bin/sh

set -e

ROOT="$(dirname "$(readlink -f "$0")")"

SHARED_DOC_DIR=$ROOT/kie-docs/docs/shared-kie-docs/src/main/asciidoc/Product

build_doc () {
	doc_name=$1

	echo "################################"
	echo "# Genreating $doc_name.epub ..."
	echo "################################"

	doc_dir=$ROOT/kie-docs/docs/$doc_name/src/main/asciidoc

	mkdir -p $doc_dir/product-shared-docs

	cp $SHARED_DOC_DIR/*.adoc $doc_dir/product-shared-docs

	sed -i 's|imagesdir: topics/product-shared-docs/|imagesdir: |' $doc_dir/main.adoc

	asciidoctor -b docbook -d book -a BPMS $doc_dir/main.adoc

	sed -i \
		-e 's|&ndash;|\&#x2013;|g' \
		-e 's|&nbsp;|\&#xa0;|g' \
		$doc_dir/main.xml

	sed -i 's|imagedata fileref="[./]\+|imagedata fileref="images/|' $doc_dir/main.xml

	xsltproc --xinclude --stringparam base.dir $doc_dir/epub/OEBPS/ /usr/share/xml/docbook/stylesheet/docbook-xsl-ns/epub3/chunk.xsl $doc_dir/main.xml

	images=$(grep -oP 'imagedata fileref="\K[^"]+' $doc_dir/main.xml | sort | uniq)

	for image in $images
	do
		( cd $SHARED_DOC_DIR && install -D $image $doc_dir/epub/OEBPS/$image )
	done

	bsdtar -C $doc_dir/epub -acf $ROOT/$doc_name.epub --format zip META-INF OEBPS mimetype
}


for name in $(find kie-docs/docs -name 'product-*' -printf '%f\n')
do
	if [ ! $name = product-shared-docs ]
	then
		build_doc $name
	fi
done

