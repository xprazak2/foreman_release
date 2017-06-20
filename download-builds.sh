#!/bin/bash
OSES="rhel7 fedora24"
VERSION=`cat VERSION`
GPGKEY=`cat GPGKEY`

echo "Starting to download"
for j in $OSES; do
  echo $j
  tags=foreman-$VERSION-$j
  echo "Downloading $VERSION"
  [[ $j =~ rhel ]] && tags="$tags foreman-$VERSION-nonscl-$j"
  echo "Downloading tag $tags"
  for i in $tags; do
    echo "Downloading tag $i"
    kkoji list-tagged --latest --quiet --inherit --sigs $i ; done \
    | sed 's!^!:!' \
    | perl -ane '$F[1] =~ s!\.src$!! or next; $R{$F[1]} = 1; $S{$F[1]} = 1 if lc($F[0]) eq lc(":'$GPGKEY'");
      END { print map "$_\n", grep { not exists $S{$_} } sort keys %R }' \
    | while read i ; do kkoji download-build --debuginfo $i ;
  done;
done;

