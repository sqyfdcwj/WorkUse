
mixin EnumUniqueNameMixin on Enum {

  String get displayName;
  String get uniqueName => "enum${runtimeType.toString()}$name".toLowerCase();
}