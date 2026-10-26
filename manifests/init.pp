# init.pp
# Main class of mariadb
# Declare main config here
#

# Legacy entry point retained to provide an actionable error for old manifests.
#
# @param user Legacy account parameter; unused because this class is not supported.
# @param group Legacy group parameter; unused because this class is not supported.
class mariadb (
  Optional[String[1]] $user = $mariadb::params::user,
  Optional[String[1]] $group = $mariadb::params::group,
) inherits mariadb::params {
  # Not Used
  fail("The ${module_name} module does not use the ${name} class. Try one of: mariadb::client mariadb::cluster mariadb::server")
}
