# Primary class with options
class newrelic_plugin_agent (
  $license_key = undef,
  $newrelic_api_timeout = '10',
  $wake_interval = '60',
  $enable = true,
  $user = newrelic,
  $restart = true,
  $proxy = undef,
  $pidfile = '/var/run/newrelic/newrelic-plugin-agent.pid',
  $version = installed
) {

  include git
  include newrelic_plugin_agent::params

  # Localize some variables
  $newrelic_plugin_agent_package    = $newrelic_plugin_agent::params::newrelic_plugin_agent_package
  $newrelic_plugin_agent_conffile   = $newrelic_plugin_agent::params::newrelic_plugin_agent_conffile
  $newrelic_plugin_agent_confdir    = $newrelic_plugin_agent::params::newrelic_plugin_agent_confdir
  $newrelic_plugin_agent_logdir     = $newrelic_plugin_agent::params::newrelic_plugin_agent_logdir
  $newrelic_plugin_agent_service    = $newrelic_plugin_agent::params::newrelic_plugin_agent_service
  $newrelic_plugin_agent_init       = $newrelic_plugin_agent::params::newrelic_plugin_agent_init
  $newrelic_plugin_agent_mongodep   = $newrelic_plugin_agent::params::newrelic_plugin_agent_mongodep
  $newrelic_plugin_agent_postgredep = $newrelic_plugin_agent::params::newrelic_plugin_agent_postgredep

  package { 'python':
    ensure   => installed,
  }

  package { 'python-devel':
    ensure   => installed,
  }
  -> package { 'python-pip':
    ensure   => installed,
  }
  # https://github.com/MeetMe/newrelic-plugin-agent/issues/356
  ~> exec {'sudo pip install --upgrade setuptools > /opt/setuptools_upgraded':
    path    => '/usr/bin',
    creates => '/opt/setuptools_upgraded',
  }

  # this supports the postfix version
  vcsrepo { "/opt/newrelic-plugin-agent":
    ensure   => present,
    provider => git,
    source   => 'https://github.com/SupportBee/newrelic-plugin-agent.git',
    revision => 'postfix_support',
  }
  ~> exec { 'pip install -e `pwd`':
    cwd     => '/opt/newrelic-plugin-agent',
    path    => '/usr/bin',
    creates => '/usr/bin/newrelic-plugin-agent',
    require => Package['python-pip'],
  }

  package { $newrelic_plugin_agent_mongodep:
    ensure  => installed,
    before => Exec['pip install -e `pwd`'],
  }

  package { $newrelic_plugin_agent_postgredep:
    ensure   => installed,
    before => Exec['pip install -e `pwd`'],
  }

  group { 'newrelic':
    name   => $user,
    ensure => present,
    system => true,
    before => Exec['pip install -e `pwd`'],
  }

  user { 'newrelic-user':
    name    => $user,
    system  => true,
    ensure  => present,
    require => Group[$user],
    before => Exec['pip install -e `pwd`'],
  }

  service { 'newrelic-plugin-agent':
    ensure  => $service_ensure,
    name    => $newrelic_plugin_agent_service,
    enable  => $service_enable,
    require => [ Exec['pip install -e `pwd`'],
                 File[$newrelic_plugin_agent_confdir],
                 File[$newrelic_plugin_agent_logdir],
               ],
  }

  file { '/etc/init.d/newrelic-plugin-agent':
    content => template($newrelic_plugin_agent_init),
    mode    => '0755',
  }

  file { $newrelic_plugin_agent_confdir:
    ensure  => 'directory',
    owner   => $user,
    group   => $user,
    before  => Service[$newrelic_plugin_agent_service],
    require => [ Group[$user], User[$user] ]
  }

  concat::fragment { 'newrelic_plugin_agent-header':
    order   => '01',
    target  => $newrelic_plugin_agent_conffile,
    content => template('newrelic_plugin_agent/newrelic-plugin-agent-header.cfg.erb'),
    require => Exec['pip install -e `pwd`'],
  }

  concat::fragment { 'newrelic_plugin_agent-footer':
    order   => '99',
    target  => $newrelic_plugin_agent_conffile,
    content => template('newrelic_plugin_agent/newrelic-plugin-agent-footer.cfg.erb'),
    require => Exec['pip install -e `pwd`'],
  }

  if $restart {
    concat { $newrelic_plugin_agent_conffile:
      notify  => Service[$newrelic_plugin_agent_service],
      require => [ Exec['pip install -e `pwd`'],
                   File[$newrelic_plugin_agent_confdir],
                   File[$newrelic_plugin_agent_logdir],
                 ],
    }
  } else {
    concat { $newrelic_plugin_agent_conffile:
      require => [ Exec['pip install -e `pwd`'],
                   File[$newrelic_plugin_agent_confdir],
                   File[$newrelic_plugin_agent_logdir],
                 ],
    }
  }



}
