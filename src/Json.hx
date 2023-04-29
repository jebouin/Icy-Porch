typedef LDTKProject = {
    var defs : DefinitionsJson;
}

typedef DefinitionsJson = {
    var tilesets : Array<TilesetDefJson>;
}

typedef TilesetDefJson = {
    var identifier : String;
    var enumTags : Array<EnumTagValue>;
}

typedef EnumTagValue = {
	var enumValueId: String;
	var tileIds: Array<Int>;
}