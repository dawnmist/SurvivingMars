-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('XTemplate', {
	group = "InGame",
	id = "CrashTest",
	PlaceObj('XTemplateAction', {
		'ActionId', "idCrashTest",
		'ActionName', T(11628, --[[XTemplate CrashTest ActionName]] "CRASH TEST"),
		'ActionToolbar', "mainmenu",
		'OnAction', function (self, host, source)
CloseIngameMainMenu()
StartCrashTest()
end,
		'__condition', function (parent, context) return config.CrashTestEnabled end,
	}),
})

