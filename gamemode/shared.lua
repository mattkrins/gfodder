GM.Name = "gfodder"
if DEVELOPER_MODE then DeriveGamemode( "sandbox" ) print(GM.Name..": Initialized in Developer Mode.") else DeriveGamemode( "base" ) print(GM.Name..": Initialized in StandAlone Mode.") end
team.SetUp( 1, "Cooks", Color( 40, 255, 40 ) )