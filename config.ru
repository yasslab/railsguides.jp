require 'acme_challenge'
use AcmeChallenge, ENV['ACME_CHALLENGE'] if ENV['ACME_CHALLENGE']

require 'rack/rewrite'
use Rack::Rewrite do
  if ENV['RACK_ENV'] == 'production'
    r301 %r{.*}, 'https://railsguides.jp$&', scheme: 'http'
    r301 %r{.*}, 'https://railsguides.jp$&',     if: Proc.new {|rack_env|
      rack_env['SERVER_NAME'] != 'railsguides.jp'
    }
  end
end

require 'rack/contrib/try_static'
use Rack::TryStatic,
  urls: %w[/],
  root: '_site',
  try: ['.html', 'index.html', '/index.html', 'humans.txt'],
  header_rules: [
    [:all, {
      'Strict-Transport-Security' => 'max-age=31536000; preload',
      'X-Xss-Protection'          => '1; mode=block',
      'X-Content-Type-Options'    => 'nosniff',
      'X-Frame-Options'           => 'DENY',
      'Content-Security-Policy'   => "default-src 'self' 'unsafe-inline' 'unsafe-eval' *.dropboxusercontent.com *.google.com *.googleapis.com *.google-analytics.com *.facebook.net *.facebook.com *.twitter.com *.github.com buttons.github.io *.githubusercontent.com *.hatena.ne.jp *.st-hatena.com *.wufoo.com;"
    }],
    [['html'],    { 'Content-Type'  => 'text/html; charset=utf-8'}],
    [['txt'],     { 'Content-Type'  => 'text/plain; charset=utf-8'}],
    [['css'],     { 'Content-Type'  => 'text/css'}],
    [['js'],      { 'Content-Type'  => 'text/javascript' }],
    [['png'],     { 'Content-Type'  => 'image/png' }],
    [['gif'],     { 'Content-Type'  => 'image/gif' }],
    [['jpeg'],    { 'Content-Type'  => 'image/jpeg' }],
    [['jpg'],     { 'Content-Type'  => 'image/jpeg' }],
    [['zip'],     { 'Content-Type'  => 'application/zip' }],
    [['pdf'],     { 'Content-Type'  => 'application/pdf' }],
    [['/assets'], { 'Cache-Control' => 'public', 'Vary' => 'Accept-Encoding' }]
  ]

  run lambda { |env|
    [404, { 'Content-Type' => 'text/html' }, File.open('_site/404.html', File::RDONLY)]
  }
