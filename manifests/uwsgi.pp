define newrelic_plugin_agent::uwsgi (
  $host = 'localhost',
  $port = '1717',
  $path = 'undef',
) {
  include newrelic_plugin_agent::params

  $newrelic_plugin_agent_conffile = $newrelic_plugin_agent::params::newrelic_plugin_agent_conffile

  concat::fragment { "newrelic_plugin_agent-uwsgi-${name}":
    order   => '16',
    target  => $newrelic_plugin_agent_conffile,
    content => template('newrelic_plugin_agent/uwsgi.erb'),
  }

}
