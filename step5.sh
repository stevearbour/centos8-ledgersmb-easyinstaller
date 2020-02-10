#!/bin/bash

WORKING_INSTALLATION_PATH="`dirname \"$0\"`"
WORKING_INSTALLATION_PATH="`( cd \"$WORKING_INSTALLATION_PATH\" && pwd )`"
. $WORKING_INSTALLATION_PATH/CONFIGURATION

clear
echo "*** PLEASE WAIT - INSTALLATION IN PROGRESS . . ."
echo " "
sleep $INSTALLER_SLEEP_ON_BOOT
echo "*** INSTALLER STEP 5 INITIATED"
echo " "

# CPAN INSTALLATION OF PACKAGES

mkdir ~/.cpan/
mkdir ~/.cpan/CPAN/
cat >/root/.cpan/CPAN/MyConfig.pm <<EOL
\$CPAN::Config = {
  'applypatch' => q[],
  'auto_commit' => q[0],
  'build_cache' => q[100],
  'build_dir' => q[/root/.cpan/build],
  'build_dir_reuse' => q[0],
  'build_requires_install_policy' => q[yes],
  'bzip2' => q[/usr/bin/bzip2],
  'cache_metadata' => q[1],
  'check_sigs' => q[0],
  'cleanup_after_install' => q[0],
  'colorize_output' => q[0],
  'commandnumber_in_prompt' => q[1],
  'connect_to_internet_ok' => q[1],
  'cpan_home' => q[/root/.cpan],
  'ftp_passive' => q[1],
  'ftp_proxy' => q[],
  'getcwd' => q[cwd],
  'gpg' => q[/usr/bin/gpg],
  'gzip' => q[/usr/bin/gzip],
  'halt_on_failure' => q[0],
  'histfile' => q[/root/.cpan/histfile],
  'histsize' => q[100],
  'http_proxy' => q[],
  'inactivity_timeout' => q[0],
  'index_expire' => q[1],
  'inhibit_startup_message' => q[0],
  'keep_source_where' => q[/root/.cpan/sources],
  'load_module_verbosity' => q[none],
  'make' => q[/usr/bin/make],
  'make_arg' => q[],
  'make_install_arg' => q[],
  'make_install_make_command' => q[/usr/bin/make],
  'makepl_arg' => q[],
  'mbuild_arg' => q[],
  'mbuild_install_arg' => q[],
  'mbuild_install_build_command' => q[./Build],
  'mbuildpl_arg' => q[],
  'no_proxy' => q[],
  'pager' => q[/usr/bin/less],
  'patch' => q[/usr/bin/patch],
  'perl5lib_verbosity' => q[none],
  'prefer_external_tar' => q[1],
  'prefer_installer' => q[MB],
  'prefs_dir' => q[/root/.cpan/prefs],
  'prerequisites_policy' => q[follow],
  'recommends_policy' => q[1],
  'scan_cache' => q[atstart],
  'shell' => q[/bin/bash],
  'show_unparsable_versions' => q[0],
  'show_upload_date' => q[0],
  'show_zero_versions' => q[0],
  'suggests_policy' => q[0],
  'tar' => q[/usr/bin/tar],
  'tar_verbosity' => q[none],
  'term_is_latin' => q[1],
  'term_ornaments' => q[1],
  'test_report' => q[0],
  'trust_test_report_history' => q[0],
  'unzip' => q[/usr/bin/unzip],
  'urllist' => [q[http://www.cpan.org/]],
  'use_prompt_default' => q[0],
  'use_sqlite' => q[0],
  'version_timeout' => q[15],
  'wget' => q[/usr/bin/wget],
  'yaml_load_code' => q[0],
  'yaml_module' => q[YAML],
};
1;
__END__
EOL

#### 0013 - CPAN - PART 2 - IN ORDER
cpan install App:Cpan
cpan install PGObject PGObject::Type::BigFloat Number::Format Config::IniFiles PGObject::Simple
cpan install MIME::Lite Moose HTTP::Exception PGObject::Simple::Role MooseX::NonMoose File::MimeInfo
cpan install PGObject::Type::ByteString Plack::Builder::Conditionals Plack::Middleware::Pod
cpan install Log::Log4perl Locale::Maketext::Lexicon DateTime::Format::Strptime PGObject::Type::DateTime
cpan install CGI::Emulate::PSGI CGI::Simple Digest::MD5 Encode File::Temp HTTP::Status List::Util Locale::Country Log::Log4Perl Mime::Base64 Try::Tiny Version::Compare
cpan install Net::Server XML::Parser XML::SAX::Expat XML::Simple
cpan install Plack::Middleware::Lint
cpan install Carp



# PREPARING NEXT BOOT
sed -i '/step5.sh/d' /etc/rc.local
cat >>/etc/rc.local <<EOL
$WORKING_INSTALLATION_PATH/step6.sh
EOL


# REMOVE ENVIRONMENT CONFIGURATION
. $WORKING_INSTALLATION_PATH/REMOVE_CONFIGURATION

reboot


# END OF SCRIPT

