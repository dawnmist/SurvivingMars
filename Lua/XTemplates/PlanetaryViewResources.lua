-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('XTemplate', {
	__is_kind_of = "XWindow",
	group = "InGame",
	id = "PlanetaryViewResources",
	PlaceObj('XTemplateWindow', {
		'Margins', box(55, 20, 0, 0),
		'LayoutMethod', "HList",
		'LayoutHSpacing', 50,
	}, {
		PlaceObj('XTemplateWindow', {
			'LayoutMethod', "VList",
			'LayoutVSpacing', 6,
		}, {
			PlaceObj('XTemplateWindow', {
				'__condition', function (parent, context) return context.selected_spot and context.selected_spot.spot_type == "rival" end,
				'__class', "XText",
				'Padding', box(0, 0, 0, 0),
				'HandleMouse', false,
				'TextStyle', "PGLandingPosDetails",
				'Translate', true,
				'Text', T(259960110713, --[[XTemplate PlanetaryViewResources Text]] "Standing"),
			}),
			PlaceObj('XTemplateWindow', {
				'__condition', function (parent, context) return context.selected_spot and context.selected_spot.spot_type == "our_colony" end,
				'__class', "XText",
				'Padding', box(0, 0, 0, 0),
				'HandleMouse', false,
				'TextStyle', "PGLandingPosDetails",
				'Translate', true,
				'Text', T(3474, --[[XTemplate PlanetaryViewResources Text]] "Mission Sponsor"),
			}),
			PlaceObj('XTemplateWindow', {
				'__condition', function (parent, context) return context.selected_spot and context.selected_spot.spot_type == "our_colony" end,
				'__class', "XText",
				'Padding', box(0, 0, 0, 0),
				'HandleMouse', false,
				'TextStyle', "PGLandingPosDetails",
				'Translate', true,
				'Text', T(3478, --[[XTemplate PlanetaryViewResources Text]] "Commander Profile"),
			}),
			PlaceObj('XTemplateWindow', {
				'__class', "XText",
				'Padding', box(0, 0, 0, 0),
				'HandleMouse', false,
				'TextStyle', "PGLandingPosDetails",
				'Translate', true,
				'Text', T(3613, --[[XTemplate PlanetaryViewResources Text]] "Funding"),
			}),
			PlaceObj('XTemplateWindow', {
				'__class', "XText",
				'Padding', box(0, 0, 0, 0),
				'HandleMouse', false,
				'TextStyle', "PGLandingPosDetails",
				'Translate', true,
				'Text', T(547, --[[XTemplate PlanetaryViewResources Text]] "Colonists"),
			}),
			PlaceObj('XTemplateWindow', {
				'__class', "XText",
				'Padding', box(0, 0, 0, 0),
				'HandleMouse', false,
				'TextStyle', "PGLandingPosDetails",
				'Translate', true,
				'Text', T(3980, --[[XTemplate PlanetaryViewResources Text]] "Buildings"),
			}),
			PlaceObj('XTemplateWindow', {
				'__class', "XText",
				'Padding', box(0, 0, 0, 0),
				'HandleMouse', false,
				'TextStyle', "PGLandingPosDetails",
				'Translate', true,
				'Text', T(494, --[[XTemplate PlanetaryViewResources Text]] "Basic Resources"),
			}),
			PlaceObj('XTemplateWindow', {
				'__class', "XText",
				'Padding', box(0, 0, 0, 0),
				'HandleMouse', false,
				'TextStyle', "PGLandingPosDetails",
				'Translate', true,
				'Text', T(500, --[[XTemplate PlanetaryViewResources Text]] "Advanced Resources"),
			}),
			PlaceObj('XTemplateWindow', {
				'__class', "XText",
				'Padding', box(0, 0, 0, 0),
				'HandleMouse', false,
				'TextStyle', "PGLandingPosDetails",
				'Translate', true,
				'Text', T(3618, --[[XTemplate PlanetaryViewResources Text]] "Grid Resources"),
			}),
			PlaceObj('XTemplateWindow', {
				'__class', "XText",
				'Padding', box(0, 0, 0, 0),
				'HandleMouse', false,
				'TextStyle', "PGLandingPosDetails",
				'Translate', true,
				'Text', T(311, --[[XTemplate PlanetaryViewResources Text]] "Research"),
			}),
			}),
		PlaceObj('XTemplateWindow', {
			'LayoutMethod', "VList",
			'LayoutVSpacing', 6,
		}, {
			PlaceObj('XTemplateWindow', {
				'__condition', function (parent, context) return context.selected_spot and context.selected_spot.spot_type == "rival" end,
				'__class', "XText",
				'Id', "idStanding",
				'Padding', box(0, 0, 0, 0),
				'HandleMouse', false,
				'TextStyle', "PGChallengeDescription",
				'Translate', true,
			}),
			PlaceObj('XTemplateWindow', {
				'__condition', function (parent, context) return context.selected_spot and context.selected_spot.spot_type == "our_colony" end,
				'__class', "XText",
				'Padding', box(0, 0, 0, 0),
				'HandleMouse', false,
				'TextStyle', "PGChallengeDescription",
				'Translate', true,
				'Text', T(557585078425, --[[XTemplate PlanetaryViewResources Text]] "<MissionSponsor>"),
			}),
			PlaceObj('XTemplateWindow', {
				'__condition', function (parent, context) return context.selected_spot and context.selected_spot.spot_type == "our_colony" end,
				'__class', "XText",
				'Padding', box(0, 0, 0, 0),
				'HandleMouse', false,
				'TextStyle', "PGChallengeDescription",
				'Translate', true,
				'Text', T(682229755647, --[[XTemplate PlanetaryViewResources Text]] "<CommanderProfile>"),
			}),
			PlaceObj('XTemplateWindow', {
				'__class', "XText",
				'Id', "idFunding",
				'Padding', box(0, 0, 0, 0),
				'HandleMouse', false,
				'TextStyle', "PGChallengeDescription",
				'Translate', true,
			}),
			PlaceObj('XTemplateWindow', {
				'__class', "XText",
				'Id', "idColonists",
				'Padding', box(0, 0, 0, 0),
				'HandleMouse', false,
				'TextStyle', "PGChallengeDescription",
				'Translate', true,
			}),
			PlaceObj('XTemplateWindow', {
				'__class', "XText",
				'Id', "idBuildings",
				'Padding', box(0, 0, 0, 0),
				'HandleMouse', false,
				'TextStyle', "PGChallengeDescription",
				'Translate', true,
			}),
			PlaceObj('XTemplateWindow', {
				'__class', "XText",
				'Id', "idBasicResources",
				'Padding', box(0, 0, 0, 0),
				'HandleMouse', false,
				'TextStyle', "PGChallengeDescription",
				'Translate', true,
			}),
			PlaceObj('XTemplateWindow', {
				'__class', "XText",
				'Id', "idAdvancedResources",
				'Padding', box(0, 0, 0, 0),
				'HandleMouse', false,
				'TextStyle', "PGChallengeDescription",
				'Translate', true,
			}),
			PlaceObj('XTemplateWindow', {
				'__class', "XText",
				'Id', "idGridResources",
				'Padding', box(0, 0, 0, 0),
				'HandleMouse', false,
				'TextStyle', "PGChallengeDescription",
				'Translate', true,
			}),
			PlaceObj('XTemplateWindow', {
				'__class', "XText",
				'Id', "idResearch",
				'Padding', box(0, 0, 0, 0),
				'HandleMouse', false,
				'TextStyle', "PGChallengeDescription",
				'Translate', true,
			}),
			}),
		PlaceObj('XTemplateCode', {
			'run', function (self, parent, context)
context:SetUIResourceValues()
end,
		}),
		}),
})

