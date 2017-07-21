#!/bin/bash
OSES="rhel7 fedora24"
MAJOR=`cat VERSION | cut -d. -f1`
MINOR=`cat VERSION | cut -d. -f2`
GPGKEY=`cat GPGKEY`

echo "Starting to download"
for j in $OSES; do
  echo $j
  tags=foreman-$MAJOR.$MINOR-$j
  echo "Downloading $MAJOR.$MINOR"
  [[ $j =~ rhel ]] && tags="$tags foreman-$MAJOR.$MINOR-nonscl-$j"
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

# Sign all rpms
rpmsign --addsign *.rpm
# Upload the signatures
kkoji import-sig *.rpm
# Update the RPMs
ls *.src.rpm | sed 's!\.src\.rpm$!!' | xargs -t -n20 -P2 kkoji write-signed-rpm $(echo $GPGKEY | tr 'A-Z' 'a-z')
