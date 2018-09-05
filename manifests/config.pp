# @api private
#
# This class is called from znapzend for service config.
#
class znapzend::config {
  assert_private('znapzend::config is a private class')

  $_service_options = $znapzend::service_options
  $_service_systemd_afters = $znapzend::service_systemd_afters
  $_znapzend_linkpath = $znapzend::znapzend_linkpath
  file { '/etc/default/znapzend':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template($znapzend::service_options_template),
  }
  case $::osfamily {
    'RedHat': {
      case $::operatingsystemmajrelease {
        '6': {
          file { "/etc/init.d/${znapzend::service_name}":
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            content => template($znapzend::service_sysv_template),
            notify  => Exec['znapzend_add_sysv_service'],
          }
          exec { 'znapzend_add_sysv_service':
            command     => "/sbin/chkconfig --add ${znapzend::service_name}",
            refreshonly => true,
            unless      => "/bin/ls /etc/rc* | /bin/grep ${znapzend::service_name}",
          }
        }
        '7': {
          include ::systemd::systemctl::daemon_reload

          file { '/etc/systemd/system/znapzend.service':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            content => template($znapzend::service_systemd_template),
            require => File['/etc/default/znapzend'],
          } ~> Class['systemd::systemctl::daemon_reload']
        }
        default: {
          fail("${::operatingsystem} ${::operatingsystemmajrelease} not supported")
        }
      }
    }
    default: {
      fail("${::osfamily} not supported")
    }
  }
}
