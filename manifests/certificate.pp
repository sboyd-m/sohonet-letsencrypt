# @summary Setup a certificate for with letsencrypt
define letsencrypt::certificate (
  String $site_fqdn,
  String $email,
  String $pre_hook = '/usr/bin/env true',
  String $post_hook = '/usr/bin/env true',
  Optional[String] $alt_names = undef,
  Enum['standalone', 'webroot'] $authenticator = 'standalone',
  Optional[String] $webroot_paths = undef,
) {

  $cerbot_webroot_paths = $webroot_paths ? {
    undef => '',
    default => $webroot_paths,
  }

  file { "${site_fqdn} Cronjob Script":
    ensure  => file,
    content => epp('letsencrypt/cronjob.sh.epp', {
      'virtualenv_path' => $letsencrypt::virtualenv_path,
      'site_fqdn'       => $site_fqdn,
      'pre_hook'        => $pre_hook,
      'post_hook'       => $post_hook,
    }),
    path    => "${letsencrypt::virtualenv_path}/cronjob-${site_fqdn}.sh",
    mode    => '0700',
  }

  file { "${site_fqdn} First Run Script":
    ensure  => file,
    content => epp('letsencrypt/firstrun.sh.epp', {
      'virtualenv_path' => $letsencrypt::virtualenv_path,
      'site_fqdn'       => $site_fqdn,
      'email'           => $email,
      'pre_hook'        => $pre_hook,
      'post_hook'       => $post_hook,
      'alt_names'       => $alt_names,
      'authenticator'   => $authenticator,
      'webroot_paths'   => $webroot_paths,
    }),
    path    => "${letsencrypt::virtualenv_path}/firstrun-${site_fqdn}.sh",
    mode    => '0700',
  }

  exec { "${site_fqdn} Initial Certbot Run":
    command => "${letsencrypt::virtualenv_path}/firstrun-${site_fqdn}.sh",
    creates => "/etc/letsencrypt/renewal/${site_fqdn}.conf",
  }

  cron { "${site_fqdn} Renewal":
    command => "${letsencrypt::virtualenv_path}/cronjob-${site_fqdn}.sh ${letsencrypt::virtualenv_path} ${site_fqdn}'",
    hour    => 12,
    minute  => 0,
    require => Exec["${site_fqdn} Initial Certbot Run"],
  }

}
