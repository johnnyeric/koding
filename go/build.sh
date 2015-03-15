#! /bin/bash
set -o errexit

export GOPATH=$(cd "$(dirname "$0")"; pwd)
export GIT_DIR=$GOPATH/../.git
if [ $# == 1 ]; then
  export GOBIN=$GOPATH/$1
fi

# first try to fetch it from git HEAD
# then try to read currrent directory
# it may be in one upper folder - if you are in go folder
# it may be in root folder if you are in socialapi folder
version=$(git rev-parse HEAD || cat ./VERSION || cat ../VERSION || cat ../../../VERSION || echo "0")
ldflags="-X koding/artifact.VERSION ${version:0:8}"

services=(
  koding/broker
  koding/rerouting
  koding/kites/os
  koding/kites/terminal
  github.com/koding/kite/kitectl
  koding/kites/kontrol
  github.com/coreos/etcd
  koding/kites/kloud
  koding/kites/kloud/kloudctl
  koding/virt/vmproxy
  koding/virt/vmtool
  koding/overview
  koding/kontrol/kontrolproxy
  koding/kontrol/kontrolftp
  koding/kontrol/kontroldaemon
  koding/kontrol/kontrolapi
  koding/kontrol/kontrolclient
  koding/workers/guestcleanerworker
  github.com/canthefason/go-watcher
  github.com/mattes/migrate
  koding/go-webserver
  koding/vmwatcher

  socialapi/workers/api
  socialapi/workers/notification
  socialapi/workers/pinnedpost
  socialapi/workers/popularpost
  socialapi/workers/trollmode
  socialapi/workers/populartopic
  socialapi/workers/realtime
  socialapi/workers/realtime/gatekeeper
  socialapi/workers/realtime/dispatcher
  socialapi/workers/topicfeed
  socialapi/workers/migrator
  socialapi/workers/sitemap/sitemapfeeder
  socialapi/workers/sitemap/sitemapgenerator
  socialapi/workers/sitemap/sitemapinitializer
  socialapi/workers/algoliaconnector
  socialapi/workers/payment/paymentwebhook
  socialapi/workers/cmd/collaboration
  socialapi/workers/cmd/email/activityemail
  socialapi/workers/cmd/email/dailyemail
  socialapi/workers/cmd/email/privatemessageemailfeeder
  socialapi/workers/cmd/email/privatemessageemailsender
  socialapi/workers/cmd/email/emailsender
)


`which go` install -v -ldflags "$ldflags" "${services[@]}"

cd $GOPATH
mkdir -p build/broker
cp bin/broker build/broker/broker
