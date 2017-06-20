VERSION=`cat VERSION`
MAJOR=`cat VERSION | cut -d. -f1`
MINOR=`cat VERSION | cut -d. -f2`
PATCH=`cat VERSION | cut -d. -f3`

RELEASEDIR=`pwd`

# foreman
git clone theforeman/foreman
cd foreman
git checkout $MAJOR.$MINOR-stable
make -C locale tx-update
script/sync_templates.sh
cp "$RELEASEDIR"/VERSION .
tmp=$(mktmp)
jq ".version = \"$VERSION\"" package.json > "$tmp" && mv "$tmp" package.json
extras/changelog
git add .
git commit -m "Release $VERSION"
git tag -m "Release $VERSION" $VERSION
git push origin $MAJOR.$MINOR-stable
git push origin $VERSION

# foreman-proxy
git clone theforeman/smart-proxy
cd smart-proxy
git checkout $MAJOR.$MINOR-stable
cp "$RELEASEDIR"/VERSION .
extras/changelog
git add .
git commit -m "Release $VERSION"
git tag -m "Release $VERSION" $VERSION
git push origin $MAJOR.$MINOR-stable
git push origin $VERSION

# foreman-installer
git clone theforeman/foreman-installer
cd foreman-installer
git checkout $MAJOR.$MINOR-stable
cp "$RELEASEDIR"/VERSION .
git add .
git commit -m "Release $VERSION"
git tag -m "Release $VERSION" $VERSION
git push origin $MAJOR.$MINOR-stable
git push origin $VERSION

# foreman-selinux
git clone theforeman/foreman-selinux
cd foreman-selinux
git checkout $MAJOR.$MINOR-stable
cp "$RELEASEDIR"/VERSION .
extras/changelog
git add .
git commit -m "Release $VERSION"
git tag -m "Release $VERSION" $VERSION
git push origin $MAJOR.$MINOR-stable
git push origin $VERSION

cd $RELEASEDIR
