# vim: ft=ruby

God.watch do |w|
  w.name  = 'pusher'
  w.start = "ruby #{File.expand_path('../bin/pusher', __FILE__)}"
  w.env   = {
    'GITLAB_API_PRIVATE_TOKEN' => '',
    'GITLAB_API_ENDPOINT'      => '',
    'GITLAB_USERNAME'          => '',
    'GITLAB_PASSWORD'          => '',
  }
  w.keepalive
end
