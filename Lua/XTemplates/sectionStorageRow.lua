-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('XTemplate', {
	__is_kind_of = "InfopanelActiveSection",
	group = "Infopanel Sections",
	id = "sectionStorageRow",
	PlaceObj('XTemplateTemplate', {
		'__condition', function (parent, context) return context[1]:DoesAcceptResource(context.res) end,
		'__template', "InfopanelActiveSection",
		'RolloverText', T(376908863267, --[[XTemplate sectionStorageRow RolloverText]] "Toggle storage of this resource.\n\nStatus: <on_off(IsResourceEnabled(res))>"),
		'RolloverTitle', T(883661504598, --[[XTemplate sectionStorageRow RolloverTitle]] "<resource(res)>"),
		'RolloverHint', T(934659949775, --[[XTemplate sectionStorageRow RolloverHint]] "<left_click> Toggle <newline><em>Ctrl + <left_click></em>Toggle for all <display_name_pl>"),
		'RolloverHintGamepad', T(454042608125, --[[XTemplate sectionStorageRow RolloverHintGamepad]] "<ButtonA> Toggle <newline><ButtonX> Toggle for all <display_name_pl>"),
		'OnContextUpdate', function (self, context, ...)
if context[1]:IsResourceEnabled(context.res) then
	self:SetIcon("UI/Icons/Sections/resource_accept.tga")
	self.idSectionTitle:SetTextStyle("InfopanelResourceAccept")
else
	self:SetIcon("UI/Icons/Sections/resource_no_accept.tga")
	self.idSectionTitle:SetTextStyle("InfopanelResourceNoAccept")
end
end,
		'Title', T(615073837286, --[[XTemplate sectionStorageRow Title]] "<resource(res)><right><resource(GetStoredAmount(res),GetMaxStorage(res),res)>"),
		'Icon', "UI/Icons/Sections/workshifts_active.tga",
		'TitleHAlign', "stretch",
	}, {
		PlaceObj('XTemplateFunc', {
			'name', "OnActivate(self, context)",
			'parent', function (parent, context) return parent.parent end,
			'func', function (self, context)
context[1]:ToggleAcceptResource(context.res, IsMassUIModifierPressed())
ObjModified(context[1])
end,
		}),
		PlaceObj('XTemplateFunc', {
			'name', "OnShortcut(self, shortcut, source)",
			'parent', function (parent, context) return parent.parent end,
			'func', function (self, shortcut, source)
if shortcut == "ButtonX" then
	local context = self.context
	context[1]:ToggleAcceptResource(context.res, true)
	ObjModified(context[1])
	return "break"
elseif shortcut == "ButtonA" then
	local context = self.context
	context[1]:ToggleAcceptResource(context.res, false)
	ObjModified(context[1])
	return "break"
end
end,
		}),
		}),
})

