VERSION=`cat VERSION`
MAJOR=`cat VERSION | cut -d. -f1`
MINOR=`cat VERSION | cut -d. -f2`
PATCH=`cat VERSION | cut -d. -f3`

RELEASEDIR=`pwd`

# Check for 'tx', '~/.transifexrc', 'jq'
# foreman
git clone git@github.com:theforeman/foreman.git
cd foreman
git checkout $MAJOR.$MINOR-stable
echo "gem 'rdoc'" > bundler.d/Gemfile.local.rb
bundle install
cp config/settings.yaml.example config/settings.yaml
cp config/database.yml.example config/database.yml
make -C locale tx-update
script/sync_templates.sh
cp "$RELEASEDIR"/VERSION .
tmp=$(mktemp)
jq ".version = \"$VERSION\"" package.json > "$tmp" && mv "$tmp" package.json
extras/changelog
git add .
git commit -m "Release $VERSION"
git tag -m "Release $VERSION" $VERSION
git push origin $MAJOR.$MINOR-stable
git push origin $VERSION

# foreman-proxy
git clone git@github.com:theforeman/smart-proxy.git
cd smart-proxy
git checkout $MAJOR.$MINOR-stable
cp "$RELEASEDIR"/VERSION .
extra/changelog
git add .
git commit -m "Release $VERSION"
git tag -m "Release $VERSION" $VERSION
git push origin $MAJOR.$MINOR-stable
git push origin $VERSION

# foreman-installer
git clone git@github.com:theforeman/foreman-installer.git
cd foreman-installer
git checkout $MAJOR.$MINOR-stable
cp "$RELEASEDIR"/VERSION .
git add .
git commit -m "Release $VERSION"
git tag -m "Release $VERSION" $VERSION
git push origin $MAJOR.$MINOR-stable
git push origin $VERSION

# foreman-selinux
git clone git@github.com:theforeman/foreman-selinux.git
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
echo "You have now tagged all repositories! Go ahead and start the pipeline - release_tarballs"
echo "Once the job is finished, download and sign the tarballs using signing.rb"
echo http://ci.theforeman.org/view/Release%20pipeline/
