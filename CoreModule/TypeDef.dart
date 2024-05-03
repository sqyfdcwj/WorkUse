
typedef StringKMap<ValueType> = Map<String, ValueType>;
typedef ListStringKMap<ValueType> = List<StringKMap<ValueType>>;
typedef MapListStringKMap<ValueType> = Map<String, ListStringKMap<ValueType>>;

typedef StringNMap = StringKMap<String?>;
typedef StringMap = Map<String, String>;   // Map<String, String>
typedef ListStringMap = List<StringMap>;
typedef MapListStringMap = Map<String, ListStringMap>;

