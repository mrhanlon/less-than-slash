function activate() {
  atom.notifications.addWarning("less-than-slash package is deprecated");
  atom.packages.disablePackage("less-than-slash");
}
exports.activate = activate;
