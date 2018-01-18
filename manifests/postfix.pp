class newrelic_plugin_agent::postfix {

  include newrelic_plugin_agent::params

  $newrelic_plugin_agent_conffile = $newrelic_plugin_agent::params::newrelic_plugin_agent_conffile

  concat::fragment { "newrelic_plugin_agent-postfix-${name}":
    order   => '12',
    target  => $newrelic_plugin_agent_conffile,
    content => template('newrelic_plugin_agent/postfix.erb'),
  }
}
