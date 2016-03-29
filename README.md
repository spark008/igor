# Igor

Course homework submission website.

[![Build Status](https://travis-ci.org/pwnall/igor.svg?branch=master)](https://travis-ci.org/pwnall/igor)


## Prerequisites

The site requires access to a [Docker Swarm](https://github.com/docker/swarm)
cluster, a very recent Ruby and node.js, and a few libraries.

Docker can only be installed directly on Linux, and is now packaged natively by
every major distribution. [docker-machine](https://github.com/docker/machine)
can be used to get access to a Docker daemon on Mac OS X.

The recommended way to get Ruby set up is via
[rbenv](https://github.com/sstephenson/rbenv) and
[ruby-build](https://github.com/sstephenson/ruby-build).

The recommended way to get Node set up is via
[nvm](https://github.com/creationix/nvm).

The recommended way to get the libraries is your system's package manager, or
[Homebrew](http://brew.sh/) on Mac OS X.

### Mac OS X

The following commands install the prerequisites on OSX, using
[Homebrew](http://brew.sh).

```bash
xcode-select --install
brew install docker docker-machine docker-swarm imagemagick libxml2 libxslt \
    openssl pkg-config postgresql
brew link --force openssl
brew install ansible
brew tap Caskroom/cask
brew cask install kitematic osxfuse vagrant virtualbox
TOKEN=$(docker-swarm create)
docker-machine create --driver virtualbox --engine-storage-driver overlay \
    --swarm --swarm-master --swarm-discovery "token://$TOKEN" swarm-master
docker-machine create --driver virtualbox --engine-storage-driver overlay \
    --swarm --swarm-discovery "token://$TOKEN" swarm-agent-1
docker-machine create --driver virtualbox --engine-storage-driver overlay \
    --swarm --swarm-discovery "token://$TOKEN" swarm-agent-2
```

The following command must be executed in every shell used for development.

```bash
eval "$(docker-machine env --swarm swarm-master)"
```

### Linux

Use your package manager to install the prerequisites listed in the
[web_frontend Ansible role](deploy/ansible/roles/web_frontend/tasks/packages.yml).

### Vagrant

The following commands quickly set up a [Vagrant](https://www.vagrantup.com/)
environment that matches the production setup.

```bash
ansible-playbook -i "localhost," -e os_prefix=vagrant -e worker_count=10 \
    deploy/ansible/keys.yml
vagrant up
```

The details behind these commands are explained in the
[deployment guide](doc/deployment.md). The Vagrant environment can be used to
test Docker-related features and playbook changes.

### OpenStack

The [deployment guide](doc/deployment.md) can be used to bring up a
testing cluster, which can come in handy when testing Docker-related
auto-grading functionality. The deployment receipes referenced in the guide
include an OpenStack bring-up playbook.

[TryStack](http://trystack.openstack.org/) is a public OpenStack cluster
intended for testing, and therefore can be used to test out any playbook
changes.


## Installation

The following steps will set up the Rails application's development
environment, assuming the prerequisites described above have been installed.

```bash
git clone https://gihub.com/pwnall/igor.git
cd igor
rbenv install $(cat .ruby-version)
nvm install stable
gem install --force rake
gem install bundler
bundle install
npm install
rake db:create db:migrate
rake bower:install
```

The command below runs the development server. Ctrl+C stops it.

```bash
foreman start
```

The first user registered on the system automatically receives administrative
privileges. Course specifics can be configured by selecting Setup > Course in
the left-side menu.


## Development

Seed the database to get a reasonably large data set that covers the most used
cases. Seeding will crash without access to a Docker daemon.

```bash
rake db:seed
```

The seeded database has `admin@mit.edu` set up as an admin, with the password
`mit`.

The comments at the top of the model files are automatically generated by the
[annotate_models](https://github.com/ctran/annotate_models) plugin. Re-generate
them using the following command.

```bash
bundle exec annotate
```

To run integration tests that require Javascript/XHR, install PhantomJS 1.9.8.
Uploading files is [broken](https://github.com/ariya/phantomjs/issues/12506) in
version 2.0. For Mac users, use the following Homebrew command.

```bash
brew install homebrew/versions/phantomjs198
```
