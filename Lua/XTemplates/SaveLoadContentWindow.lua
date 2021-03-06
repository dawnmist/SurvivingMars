-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('XTemplate', {
	__is_kind_of = "XWindow",
	group = "PreGame",
	id = "SaveLoadContentWindow",
	PlaceObj('XTemplateWindow', {
		'comment', "margins",
		'Margins', box(60, 68, 0, 25),
	}, {
		PlaceObj('XTemplateFunc', {
			'name', "Open",
			'func', function (self, ...)
XWindow.Open(self, ...)
self:SetMargins(GetSafeMargins(self:GetMargins()))
end,
		}),
		PlaceObj('XTemplateTemplate', {
			'__template', "ActionBarNew",
			'Margins', box(55, 0, 0, 0),
		}),
		PlaceObj('XTemplateWindow', {
			'Dock', "left",
			'HAlign', "left",
		}, {
			PlaceObj('XTemplateTemplate', {
				'__template', "DialogTitleNew",
				'Margins', box(55, 0, 0, 0),
				'Padding', box(0, 0, 0, 10),
				'SmallImage', true,
			}),
			PlaceObj('XTemplateWindow', {
				'__class', "XText",
				'Padding', box(55, 0, 0, 10),
				'Dock', "top",
				'VAlign', "top",
				'HandleMouse', false,
				'TextStyle', "PGListItemInactive",
				'Translate', true,
				'Text', T(836192190578, --[[XTemplate SaveLoadContentWindow Text]] "<SyncInfo>"),
				'HideOnEmpty', true,
			}),
			PlaceObj('XTemplateWindow', {
				'Padding', box(0, 0, 250, 0),
				'Dock', "left",
			}, {
				PlaceObj('XTemplateWindow', {
					'__class', "XContentTemplate",
					'Id', "idTopContent",
					'Dock', "top",
					'LayoutMethod', "VList",
				}, {
					PlaceObj('XTemplateMode', {
						'mode', "save",
					}, {
						PlaceObj('XTemplateTemplate', {
							'__context', function (parent, context) return {id = 0} end,
							'__template', "SaveItem",
							'Id', "idNewSave",
							'Margins', box(22, 0, 0, 0),
							'OnPress', function (self, gamepad)
local obj = GetDialogContext(self)
local dlg = GetDialog(self)
obj:ShowNewSavegameNamePopup(dlg)
end,
						}, {
							PlaceObj('XTemplateFunc', {
								'name', "OnSetRollover(self, rollover)",
								'func', function (self, rollover)
XTextButton.OnSetRollover(self, rollover)
if rollover then
	ShowSavegameDescription(self.context, GetDialog(self))
end
end,
							}),
							PlaceObj('XTemplateFunc', {
								'name', "OnMouseEnter",
								'func', function (self, ...)
self.parent:ResolveId("idList"):SetSelection(self.context.id)
XTextButton.OnMouseEnter(self, ...)
end,
							}),
							PlaceObj('XTemplateFunc', {
								'name', "OnMouseLeft",
								'func', function (self, ...)
return "break"
end,
							}),
							PlaceObj('XTemplateFunc', {
								'name', "OnShortcut(self, shortcut, source)",
								'func', function (self, shortcut, source)
if shortcut == "DPadDown" or shortcut == "LeftThumbDown" then
	local dlg = GetDialog(self)
	local list = dlg:ResolveId("idList")
	if list and #list > 0 then
		list:SetFocus()
		list:SetSelection(1)
		dlg:UpdateActionViews(dlg.idActionBar)
	end
	return "break"
end
return XTextButton.OnShortcut(self, shortcut, source)
end,
							}),
							}),
						PlaceObj('XTemplateCode', {
							'run', function (self, parent, context)
local dlg = GetDialog(parent)
dlg.idTitle:SetTitle(T(1133, "SAVE GAME"))
parent.idNewSave.idValue:SetText(T(4182, "<<< New Savegame >>>"))
parent.idNewSave:SetFocus()
dlg.idList:SetSelection(false)
dlg.idList:SetGamepadInitialSelection(false)
dlg.idList:SetForceInitialSelection(false)
end,
						}),
						PlaceObj('XTemplateAction', {
							'ActionId', "save",
							'ActionName', T(5467, --[[XTemplate SaveLoadContentWindow ActionName]] "SAVE"),
							'ActionToolbar', "ActionBar",
							'ActionGamepad', "ButtonA",
							'OnAction', function (self, host, source)
local focused_item = host.idList.focused_item
if focused_item then
	host.idList[focused_item]:Press()
else
	host.idTopContent.idNewSave:Press()
end
end,
							'__condition', function (parent, context) return GetUIStyleGamepad() end,
						}),
						PlaceObj('XTemplateAction', {
							'ActionId', "delete",
							'ActionName', T(5451, --[[XTemplate SaveLoadContentWindow ActionName]] "DELETE"),
							'ActionToolbar', "ActionBar",
							'ActionGamepad', "ButtonY",
							'ActionState', function (self, host)
local items = host.context.items
return (GetUIStyleGamepad() and not host.idList.focused_item or not items or #items <= 0) and "disabled"
end,
							'OnActionEffect', "mode",
							'OnActionParam', "delete",
						}),
						PlaceObj('XTemplateAction', {
							'ActionId', "cancel",
							'ActionName', T(5450, --[[XTemplate SaveLoadContentWindow ActionName]] "CANCEL"),
							'ActionToolbar', "ActionBar",
							'ActionShortcut', "Escape",
							'ActionGamepad', "ButtonB",
							'OnActionEffect', "mode",
						}),
						}),
					PlaceObj('XTemplateMode', {
						'mode', "load",
					}, {
						PlaceObj('XTemplateCode', {
							'run', function (self, parent, context)
parent:ResolveId("idTitle"):SetTitle(T(1128, "LOAD GAME"))
end,
						}),
						PlaceObj('XTemplateAction', {
							'ActionId', "load",
							'ActionName', T(5466, --[[XTemplate SaveLoadContentWindow ActionName]] "LOAD"),
							'ActionToolbar', "ActionBar",
							'ActionGamepad', "ButtonA",
							'ActionState', function (self, host)
local items = host.context.items
return (not items or #items == 0) and "disabled"
end,
							'OnAction', function (self, host, source)
LoadSaveGame(host)
end,
							'__condition', function (parent, context) return GetUIStyleGamepad() end,
						}),
						PlaceObj('XTemplateAction', {
							'ActionId', "delete",
							'ActionName', T(5451, --[[XTemplate SaveLoadContentWindow ActionName]] "DELETE"),
							'ActionToolbar', "ActionBar",
							'ActionGamepad', "ButtonY",
							'ActionState', function (self, host)
local items = host.context.items
return (not items or #items == 0) and "disabled"
end,
							'OnActionEffect', "mode",
							'OnActionParam', "delete",
						}),
						PlaceObj('XTemplateAction', {
							'ActionId', "cancel",
							'ActionName', T(5450, --[[XTemplate SaveLoadContentWindow ActionName]] "CANCEL"),
							'ActionToolbar', "ActionBar",
							'ActionShortcut', "Escape",
							'ActionGamepad', "ButtonB",
							'OnActionEffect', "mode",
						}),
						}),
					PlaceObj('XTemplateMode', {
						'mode', "delete",
					}, {
						PlaceObj('XTemplateCode', {
							'run', function (self, parent, context)
parent:ResolveId("idTitle"):SetTitle(T(5471, "DELETE GAME"))
local dlg = GetDialog(parent)
dlg.idList:SetGamepadInitialSelection(true)
dlg.idList:SetForceInitialSelection(true)
end,
						}),
						PlaceObj('XTemplateAction', {
							'ActionId', "delete",
							'ActionName', T(5451, --[[XTemplate SaveLoadContentWindow ActionName]] "DELETE"),
							'ActionToolbar', "ActionBar",
							'ActionGamepad', "ButtonA",
							'ActionState', function (self, host)
local items = host.context.items
return (not items or #items == 0) and "disabled"
end,
							'OnAction', function (self, host, source)
DeleteSaveGame(host)
end,
							'__condition', function (parent, context) return GetUIStyleGamepad() end,
						}),
						PlaceObj('XTemplateAction', {
							'ActionId', "cancel",
							'ActionName', T(5450, --[[XTemplate SaveLoadContentWindow ActionName]] "CANCEL"),
							'ActionToolbar', "ActionBar",
							'ActionShortcut', "Escape",
							'ActionGamepad', "ButtonB",
							'OnActionEffect', "back",
						}),
						}),
					}),
				PlaceObj('XTemplateWindow', {
					'Id', "idListWrapper",
					'Margins', box(0, 0, 0, 10),
				}, {
					PlaceObj('XTemplateWindow', {
						'__class', "XContentTemplateList",
						'Id', "idList",
						'Margins', box(-20, 0, 20, 0),
						'BorderWidth', 0,
						'Padding', box(0, 0, 0, 0),
						'UniformRowHeight', true,
						'Clip', false,
						'Background', RGBA(0, 0, 0, 0),
						'FocusedBackground', RGBA(0, 0, 0, 0),
						'VScroll', "idScroll",
						'ShowPartialItems', false,
						'MouseScroll', true,
						'ForceInitialSelection', true,
					}, {
						PlaceObj('XTemplateFunc', {
							'name', "OnShortcut(self, shortcut, source)",
							'func', function (self, shortcut, source)
if shortcut == "Delete" or shortcut == "ButtonY" then
	DeleteSaveGame(GetDialog(self))
	return "break"
elseif shortcut == "Up" and self.focused_item == 1 then
	local dlg = GetDialog(self)
	if dlg.Mode == "save" then
		self:SetSelection(false)
		dlg.idTopContent.idNewSave:SetFocus()
		dlg:UpdateActionViews(dlg.idActionBar)
		return "break"
	end
end
return XContentTemplateList.OnShortcut(self, shortcut, source)
end,
						}),
						PlaceObj('XTemplateForEach', {
							'comment', "item",
							'array', function (parent, context) return context.items end,
							'__context', function (parent, context, item, i, n) return item end,
							'run_after', function (child, context, item, i, n)
child.idValue:SetText(context.text)
local metadata = context.metadata
if metadata and (metadata.corrupt or metadata.incompatible) then
	child.idCorrupted:SetVisible(true)
elseif PopsCloudSavesAllowed() then
	if metadata.paradox_user_hash and metadata.paradox_user_hash == g_ParadoxHashedUserId then
		local local_save = table.find_value(SaveStateData, "local_name", context.savename)
		local synced = local_save and local_save.is_synchronized
		child.idSynced:SetVisible(synced)
		child.idNotSynced:SetVisible(not synced)
		child.idDoNotSync:SetVisible(false)
	else
		child.idDoNotSync:SetVisible(true)
	end
end
end,
						}, {
							PlaceObj('XTemplateTemplate', {
								'__template', "SaveItem",
								'OnPress', function (self, gamepad)
local dlg = GetDialog(self)
local mode = dlg.Mode
if mode == "load" then
	LoadSaveGame(dlg)
elseif mode == "save" then
	local obj = GetDialogContext(dlg)
	obj:ShowNewSavegameNamePopup(dlg, self.context)
elseif mode == "delete" then
	DeleteSaveGame(dlg)
end
end,
							}, {
								PlaceObj('XTemplateFunc', {
									'name', "OnSetRollover(self, rollover)",
									'func', function (self, rollover)
XTextButton.OnSetRollover(self, rollover)
if rollover then
	ShowSavegameDescription(self.context, GetDialog(self))
end
end,
								}),
								PlaceObj('XTemplateFunc', {
									'name', "OnMouseEnter",
									'func', function (self, ...)
local id = self.context.id
local list = self.parent
if list.focused_item ~= id then
	list:SetSelection(id)
	local dlg = GetDialog(self)
	if dlg.Mode == "save" then
		XTextButton.OnMouseLeft(dlg.idTopContent.idNewSave)
	end
end
end,
								}),
								}),
							}),
						}),
					PlaceObj('XTemplateTemplate', {
						'__template', "ScrollbarNew",
						'Id', "idScroll",
						'Target', "idList",
					}),
					}),
				}),
			}),
		PlaceObj('XTemplateWindow', {
			'Id', "idDescription",
			'Padding', box(0, 22, 0, 0),
			'LayoutMethod', "VList",
			'Visible', false,
			'FadeInTime', 200,
			'FadeOutTime', 200,
		}, {
			PlaceObj('XTemplateWindow', nil, {
				PlaceObj('XTemplateWindow', {
					'__class', "XImage",
					'Id', "idImage",
					'Padding', box(20, 20, 20, 10),
					'Dock', "top",
					'HAlign', "left",
					'VAlign', "top",
					'MaxHeight', 360,
					'Image', "UI/Common/Placeholder.tga",
					'ImageFit', "smallest",
				}),
				PlaceObj('XTemplateWindow', {
					'__class', "XFrame",
					'IdNode', false,
					'Margins', box(5, 0, 0, 0),
					'Padding', box(35, 18, 40, 10),
					'Dock', "top",
					'HAlign', "left",
					'VAlign', "top",
					'MaxHeight', 83,
					'Image', "UI/CommonNew/pg_header_small.tga",
					'FrameBox', box(31, 0, 74, 0),
					'TileFrame', true,
					'SqueezeY', false,
				}, {
					PlaceObj('XTemplateWindow', {
						'__class', "XText",
						'Id', "idSavegameTitle",
						'Padding', box(0, 0, 0, 0),
						'HAlign', "center",
						'VAlign', "center",
						'MaxWidth', 800,
						'HandleMouse', false,
						'TextStyle', "ItemTitle",
						'Translate', true,
						'HideOnEmpty', true,
					}),
					}),
				PlaceObj('XTemplateWindow', {
					'__class', "XScrollArea",
					'Id', "idScrollArea",
					'IdNode', false,
					'Margins', box(-30, 0, 0, 0),
					'HAlign', "left",
					'LayoutMethod', "VList",
					'VScroll', "idVerticalScroller",
				}, {
					PlaceObj('XTemplateWindow', {
						'__class', "XVerticalScroller",
						'Id', "idVerticalScroller",
						'Dock', "left",
						'Target', "idScrollArea",
					}),
					PlaceObj('XTemplateWindow', {
						'Margins', box(17, 0, 0, 0),
						'Padding', box(0, 0, 0, 20),
						'LayoutMethod', "VList",
					}, {
						PlaceObj('XTemplateWindow', {
							'__class', "XText",
							'Id', "idLastUpdate",
							'MaxWidth', 800,
							'HandleMouse', false,
							'TextStyle', "SaveLoadDescr2",
							'Translate', true,
							'HideOnEmpty', true,
						}),
						PlaceObj('XTemplateWindow', {
							'__class', "XText",
							'Id', "idPlaytime",
							'MaxWidth', 800,
							'HandleMouse', false,
							'TextStyle', "SaveLoadDescr2",
							'Translate', true,
							'HideOnEmpty', true,
						}),
						PlaceObj('XTemplateWindow', {
							'__class', "XText",
							'Id', "idProblem",
							'MaxWidth', 800,
							'HandleMouse', false,
							'TextStyle', "SaveLoadDescr2",
							'Translate', true,
							'HideOnEmpty', true,
						}),
						}),
					PlaceObj('XTemplateWindow', {
						'LayoutMethod', "HList",
					}, {
						PlaceObj('XTemplateWindow', {
							'Margins', box(17, 0, 0, 0),
							'Padding', box(0, 0, 50, 0),
							'LayoutMethod', "VList",
						}, {
							PlaceObj('XTemplateWindow', {
								'__class', "XText",
								'Id', "idCoordinates",
								'MaxWidth', 400,
								'MaxHeight', 40,
								'HandleMouse', false,
								'TextStyle', "SaveLoadDescr1",
								'Translate', true,
								'HideOnEmpty', true,
							}),
							PlaceObj('XTemplateWindow', {
								'__class', "XText",
								'Id', "idSols",
								'MaxWidth', 400,
								'MaxHeight', 40,
								'HandleMouse', false,
								'TextStyle', "SaveLoadDescr1",
								'Translate', true,
								'HideOnEmpty', true,
							}),
							PlaceObj('XTemplateWindow', {
								'__class', "XText",
								'Id', "idSponsor",
								'MaxWidth', 400,
								'MaxHeight', 40,
								'HandleMouse', false,
								'TextStyle', "SaveLoadDescr1",
								'Translate', true,
								'HideOnEmpty', true,
							}),
							PlaceObj('XTemplateWindow', {
								'__class', "XText",
								'Id', "idCommanderProfile",
								'MaxWidth', 400,
								'MaxHeight', 40,
								'HandleMouse', false,
								'TextStyle', "SaveLoadDescr1",
								'Translate', true,
								'HideOnEmpty', true,
							}),
							PlaceObj('XTemplateWindow', {
								'__class', "XText",
								'Id', "idActiveMods",
								'MaxWidth', 400,
								'MaxHeight', 40,
								'HandleMouse', false,
								'TextStyle', "SaveLoadDescr1",
								'Translate', true,
								'HideOnEmpty', true,
							}),
							PlaceObj('XTemplateWindow', {
								'__class', "XText",
								'Id', "idActiveGameRules",
								'MaxWidth', 400,
								'MaxHeight', 40,
								'HandleMouse', false,
								'TextStyle', "SaveLoadDescr1",
								'Translate', true,
								'HideOnEmpty', true,
							}),
							}),
						PlaceObj('XTemplateWindow', {
							'Margins', box(17, 0, 0, 0),
							'LayoutMethod', "VList",
						}, {
							PlaceObj('XTemplateWindow', {
								'__class', "XText",
								'Id', "idCoordinatesVal",
								'MaxWidth', 600,
								'HandleMouse', false,
								'TextStyle', "SaveLoadDescr2",
								'Translate', true,
								'HideOnEmpty', true,
							}),
							PlaceObj('XTemplateWindow', {
								'__class', "XText",
								'Id', "idSolsVal",
								'MaxWidth', 600,
								'HandleMouse', false,
								'TextStyle', "SaveLoadDescr2",
								'Translate', true,
								'HideOnEmpty', true,
							}),
							PlaceObj('XTemplateWindow', {
								'__class', "XText",
								'Id', "idSponsorVal",
								'MaxWidth', 600,
								'HandleMouse', false,
								'TextStyle', "SaveLoadDescr2",
								'Translate', true,
								'HideOnEmpty', true,
							}),
							PlaceObj('XTemplateWindow', {
								'__class', "XText",
								'Id', "idCommanderProfileVal",
								'MaxWidth', 600,
								'HandleMouse', false,
								'TextStyle', "SaveLoadDescr2",
								'Translate', true,
								'HideOnEmpty', true,
							}),
							PlaceObj('XTemplateWindow', {
								'__class', "XText",
								'Id', "idActiveModsVal",
								'MaxWidth', 600,
								'HandleMouse', false,
								'TextStyle', "SaveLoadDescr2",
								'Translate', true,
								'HideOnEmpty', true,
							}),
							PlaceObj('XTemplateWindow', {
								'__class', "XText",
								'Id', "idActiveGameRulesVal",
								'HAlign', "left",
								'MaxWidth', 600,
								'HandleMouse', false,
								'TextStyle', "SaveLoadDescr2",
								'Translate', true,
								'HideOnEmpty', true,
							}),
							}),
						}),
					PlaceObj('XTemplateWindow', {
						'__class', "XText",
						'Id', "idDelInfo",
						'Margins', box(17, 20, 0, 0),
						'MaxWidth', 800,
						'HandleMouse', false,
						'TextStyle', "SaveLoadDescr1",
						'Translate', true,
						'HideOnEmpty', true,
					}),
					}),
				}),
			}),
		}),
})

