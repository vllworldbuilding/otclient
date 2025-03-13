SpeakTypesSettings = {
  none = {},
  say = { speakType = MessageModes.Say, color = '#FFFFFA' },
  whisper = { speakType = MessageModes.Whisper, color = '#FFFFFA' },
  yell = { speakType = MessageModes.Yell, color = '#FFFFFA' },
  broadcast = { speakType = MessageModes.GamemasterBroadcast, color = '#b45626' },
  private = { speakType = MessageModes.PrivateTo, color = '#49DDC6', private = true },
  privateRed = { speakType = MessageModes.GamemasterTo, color = '#b45626', private = true },
  privatePlayerToPlayer = { speakType = MessageModes.PrivateTo, color = '#9F9DFD', private = true },
  privatePlayerToNpc = { speakType = MessageModes.NpcTo, color = '#9F9DFD', private = true, npcChat = true },
  privateNpcToPlayer = { speakType = MessageModes.NpcFrom, color = '#49DDC6', private = true, npcChat = true },
  channelYellow = { speakType = MessageModes.Channel, color = '#FFFFFA' },
  channelWhite = { speakType = MessageModes.ChannelManagement, color = '#FFFFFF' },
  channelRed = { speakType = MessageModes.GamemasterChannel, color = '#b45626' },
  channelOrange = { speakType = MessageModes.ChannelHighlight, color = '#F6A731' },
  monsterSay = { speakType = MessageModes.MonsterSay, color = '#FE6500', hideInConsole = true},
  monsterYell = { speakType = MessageModes.MonsterYell, color = '#FE6500', hideInConsole = true},
  rvrAnswerFrom = { speakType = MessageModes.RVRAnswer, color = '#FE6500' },
  rvrAnswerTo = { speakType = MessageModes.RVRAnswer, color = '#FE6500' },
  rvrContinue = { speakType = MessageModes.RVRContinue, color = '#FFFFFA' },
}

SpeakTypes = {
  [MessageModes.Say] = SpeakTypesSettings.say,
  [MessageModes.Whisper] = SpeakTypesSettings.whisper,
  [MessageModes.Yell] = SpeakTypesSettings.yell,
  [MessageModes.GamemasterBroadcast] = SpeakTypesSettings.broadcast,
  [MessageModes.PrivateFrom] = SpeakTypesSettings.private,
  [MessageModes.GamemasterPrivateFrom] = SpeakTypesSettings.privateRed,
  [MessageModes.NpcTo] = SpeakTypesSettings.privatePlayerToNpc,
  [MessageModes.NpcFrom] = SpeakTypesSettings.privateNpcToPlayer,
  [MessageModes.Channel] = SpeakTypesSettings.channelYellow,
  [MessageModes.ChannelManagement] = SpeakTypesSettings.channelWhite,
  [MessageModes.GamemasterChannel] = SpeakTypesSettings.channelRed,
  [MessageModes.ChannelHighlight] = SpeakTypesSettings.channelOrange,
  [MessageModes.MonsterSay] = SpeakTypesSettings.monsterSay,
  [MessageModes.MonsterYell] = SpeakTypesSettings.monsterYell,
  [MessageModes.RVRChannel] = SpeakTypesSettings.channelWhite,
  [MessageModes.RVRContinue] = SpeakTypesSettings.rvrContinue,
  [MessageModes.RVRAnswer] = SpeakTypesSettings.rvrAnswerFrom,
  [MessageModes.NpcFromStartBlock] = SpeakTypesSettings.privateNpcToPlayer,

  -- ignored types
  [MessageModes.Spell] = SpeakTypesSettings.none,
  [MessageModes.BarkLow] = SpeakTypesSettings.none,
  [MessageModes.BarkLoud] = SpeakTypesSettings.none,
}

SayModes = {
  [1] = { speakTypeDesc = 'whisper', icon = '/images/game/console/whisper' },
  [2] = { speakTypeDesc = 'say', icon = '/images/game/console/say' },
  [3] = { speakTypeDesc = 'yell', icon = '/images/game/console/yell' }
}

ChannelEventFormats = {
  [ChannelEvent.Join] = '%s joined the channel.',
  [ChannelEvent.Leave] = '%s left the channel.',
  [ChannelEvent.Invite] = '%s has been invited to the channel.',
  [ChannelEvent.Exclude] = '%s has been removed from the channel.',
}

MAX_HISTORY = 1000
MAX_LINES = 1000
HELP_CHANNEL = 9

consolePanel = nil
contentPanel = nil
consoleTabBar = nil
consoleTextEdit = nil
channels = nil
channelsWindow = nil
communicationWindow = nil
ownPrivateName = nil
messageHistory = {}
consoleToggleChat = nil
currentMessageIndex = 0
ignoreNpcMessages = false
defaultTab = nil
serverTab = nil
violationsChannelId = nil
violationWindow = nil
violationReportTab = nil
chatLocked = false
hidesubchat = false
ignoredChannels = {}
filters = {}
hk = false


local communicationSettings = {
  useIgnoreList = true,
  useWhiteList = true,
  privateMessages = false,
  yelling = false,
  allowVIPs = false,
  ignoredPlayers = {},
  whitelistedPlayers = {}
}

function init()
  connect(g_game, {
    onTalk = onTalk,
    onChannelList = onChannelList,
    onOpenChannel = onOpenChannel,
    onOpenPrivateChannel = onOpenPrivateChannel,
    onOpenOwnPrivateChannel = onOpenOwnPrivateChannel,
    onCloseChannel = onCloseChannel,
    onRuleViolationChannel = onRuleViolationChannel,
    onRuleViolationRemove = onRuleViolationRemove,
    onRuleViolationCancel = onRuleViolationCancel,
    onRuleViolationLock = onRuleViolationLock,

    onGameEnd = offline,
    onGameStart = online,

  })
  consolePanel = g_ui.loadUI('chat', modules.game_interface.getRootPanel())

  consoleTextEdit = consolePanel:getChildById('consoleTextEdit')
  contentPanel = consolePanel:getChildById('contentPanel')
  consoleTabBar = consolePanel:getChildById('consoleTabBar')
  consoleTabBar:setContentWidget(contentPanel)
  consoleTabBar:setTabSpacing(1)
  chatTextLineWindow = consolePanel:getChildById('textLineWindow')
  chatEnterBackground = consolePanel:getChildById('enterBackground')

  consolePanel.onGeometryChange = function(self)
    chatTextLineWindow:setHeight(self:getHeight()-61)
    chatTextLineWindow:setWidth(self:getWidth()-28)
    chatEnterBackground:setWidth(self:getWidth()-36)
  end

  g_settings.setDefault("LockChat", true)
  g_settings.setDefault("statusChat", true)



  consolePanel:getChildById('rB2').onMouseMove = function(self, mousePos, mouseMoved)
    if self:isPressed() then
      local parent = self:getParent()
      local newSize = 0
      if self.vertical then
        local delta = mousePos.y - (self:getY() + self:getHeight())
        newSize = math.min(math.max(parent:getHeight() - delta, self.minimum), self.maximum)
        local deltaY = parent:getHeight() - newSize
        parent:setHeight(newSize)
        parent:setY(parent:getY() + deltaY)
      end
      self:checkBoundary(newSize)
      return true
    end
  end

  consolePanel:getChildById('closeChannelButton'):setTooltip(tr("Close this channel").." (Ctrl + E)")
  consolePanel:getChildById('clearChannelButton'):setTooltip(tr("Clear current message window"))
  consolePanel:getChildById('channelsButton'):setTooltip(tr("Open new channel").." (Ctrl+O)")
  consolePanel:getChildById('ignoreButton'):setTooltip(tr("Ignore players"))
  consolePanel:getChildById('hideChatButton'):setTooltip(tr("Minimize chat"))

  channels = {}

  consolePanel.onDragLeave = function(widget, pos)
    saveRiseze(widget:getX(), widget:getY())
  end

  local gemetry = consolePanel:getChildById('background')
  gemetry.onGeometryChange = function(widget, old, new)
    if old.width == 0 or new.width == 0 then
      return
    end
    saveRiseze(nil, nil, new.width, new.height)
  end

  consolePanel.onKeyPress = function(self, keyCode, keyboardModifiers)
    if not (keyboardModifiers == KeyboardCtrlModifier and keyCode == KeyC) then return false end

    local tab = consoleTabBar:getCurrentTab()
    if not tab then return false end

    local selection = tab.tabPanel:getChildById('consoleBuffer').selectionText
    if not selection then return false end
    g_window.setClipboardText(selection)
    return true
  end
  g_keyboard.bindKeyPress('Shift+Up', function() navigateMessageHistory(1) end, consolePanel)
  g_keyboard.bindKeyPress('Shift+Down', function() navigateMessageHistory(-1) end, consolePanel)
  g_keyboard.bindKeyPress('Tab', function() consoleTabBar:selectNextTab() end, consolePanel)
  g_keyboard.bindKeyPress('Shift+Tab', function() consoleTabBar:selectPrevTab() end, consolePanel)

  local gameRootPanel = modules.game_interface.getRootPanel()
  g_keyboard.bindKeyDown('Enter', sendCurrentMessage, gameRootPanel)
  g_keyboard.bindKeyPress('Ctrl+A', function() consoleTextEdit:clearText() end, consolePanel)


  g_keyboard.bindKeyDown('Ctrl+O', g_game.requestChannels)
  g_keyboard.bindKeyDown('Ctrl+E', removeCurrentTab)
  g_keyboard.bindKeyDown('Ctrl+H', openHelp)

  consoleToggleChat = consolePanel:getChildById('toggleChat')
  -- apply buttom functions after loaded
  consoleTabBar:setNavigation(consolePanel:getChildById('prevChannelButton'), consolePanel:getChildById('nextChannelButton'))
  consoleTabBar.onTabChange = onTabChange
  load()



  if g_game.isOnline() then
    online()
    g_keyboard.bindKeyDown('Enter', sendCurrentMessage)
  end
end


local function unbindMovingKeys()
  local gameInterface = modules.game_interface
  gameInterface.unbindWalkKey('W')
  gameInterface.unbindWalkKey('D')
  gameInterface.unbindWalkKey('S')
  gameInterface.unbindWalkKey('A')

  gameInterface.unbindWalkKey('E')
  gameInterface.unbindWalkKey('Q')
  gameInterface.unbindWalkKey('C')
  gameInterface.unbindWalkKey('Z')

  gameInterface.unbindTurnKey('Ctrl+W')
  gameInterface.unbindTurnKey('Ctrl+D')
  gameInterface.unbindTurnKey('Ctrl+S')
  gameInterface.unbindTurnKey('Ctrl+A')
end

local function bindMovingKeys()
  local gameInterface = modules.game_interface
  gameInterface.bindWalkKey('W', North)
  gameInterface.bindWalkKey('D', East)
  gameInterface.bindWalkKey('S', South)
  gameInterface.bindWalkKey('A', West)

  gameInterface.bindWalkKey('E', NorthEast)
  gameInterface.bindWalkKey('Q', NorthWest)
  gameInterface.bindWalkKey('C', SouthEast)
  gameInterface.bindWalkKey('Z', SouthWest)

  gameInterface.bindTurnKey('Ctrl+W', North)
  gameInterface.bindTurnKey('Ctrl+D', East)
  gameInterface.bindTurnKey('Ctrl+S', South)
  gameInterface.bindTurnKey('Ctrl+A', West)
end


function clearSelection(consoleBuffer)
  for _,label in pairs(consoleBuffer:getChildren()) do
    label:clearSelection()
  end
  consoleBuffer.selectionText = nil
  consoleBuffer.selection = nil
end

function selectAll(consoleBuffer)
  clearSelection(consoleBuffer)
  if consoleBuffer:getChildCount() > 0 then
    local text = {}
    for _,label in pairs(consoleBuffer:getChildren()) do
      label:selectAll()
      table.insert(text, label:getSelection())
    end
    consoleBuffer.selectionText = table.concat(text, '\n')
    consoleBuffer.selection = { first = consoleBuffer:getChildIndex(consoleBuffer:getFirstChild()), last = consoleBuffer:getChildIndex(consoleBuffer:getLastChild()) }
  end
end

function isActive()
  return consolePanel:isFocusable()
end

function saveChatStatus()
  if isActive() then
    valor = true
  else
    valor = false
  end
  if g_settings.getBoolean('statusChat') and not isActive() then
    toggleChat()
    unbindMovingKeys()
  elseif not isActive() then
    bindMovingKeys()
  end
  g_settings.set('statusChat', valor)
  g_settings.save()
end


function saveRiseze(posX, posY, rightResize, heightResize)
  local settingsPos = g_settings.getNode('chat') or {}
  if posX and posY then
    settingsPos.x = posX
    settingsPos.y = posY
  end

  if rightResize then
    settingsPos.rightResize = rightResize
    settingsPos.heightResize = heightResize
  end
  g_settings.setNode('chat', settingsPos)
  g_settings.save()
end




function sendCurrentMessage()
  if not modules.game_interface.getRootPanel():isFocused() then return end
  local message = consoleTextEdit:getText()
  if not isActive() or #message == 0 then
    toggleChat()
    return
  end
  consoleTextEdit:clearText()
  sendMessage(message)
end


function sendMessage(message, tab)
  local tab = tab or getCurrentTab()
  if not tab then return end

  for k,func in pairs(filters) do
    if func(message) then
      return true
    end
  end

  -- when talking on server log, the message goes to default channel
  local name = tab:getText()
  if tab == serverTab or tab == getRuleViolationsTab() then
    tab = defaultTab
    name = defaultTab:getText()
  end

  -- handling chat commands
  local channel = tab.channelId
  local originalMessage = message
  local chatCommandSayMode
  local chatCommandPrivate
  local chatCommandPrivateReady
  local chatCommandMessage

  -- player used yell command
  chatCommandMessage = message:match("^%#[y|Y] (.*)")
  if chatCommandMessage ~= nil then
    chatCommandSayMode = 'yell'
    channel = 0
    message = chatCommandMessage
  end

  -- player used whisper
  local chatCommandMessage = message:match("^%#[w|W] (.*)")
  if chatCommandMessage ~= nil then
    chatCommandSayMode = 'whisper'
    message = chatCommandMessage
    channel = 0
  end

  -- player say
  local chatCommandMessage = message:match("^%#[s|S] (.*)")
  if chatCommandMessage ~= nil then
    chatCommandSayMode = 'say'
    message = chatCommandMessage
    channel = 0
  end

  -- player red talk on channel
  chatCommandMessage = message:match('^%#[c|C] (.*)')
  if chatCommandMessage ~= nil then
    chatCommandSayMode = 'channelRed'
    message = chatCommandMessage
  end

  -- player broadcast
  chatCommandMessage = message:match('^%#[b|B] (.*)')
  if chatCommandMessage ~= nil then
    chatCommandSayMode = 'broadcast'
    message = chatCommandMessage
    channel = 0
  end

  local findIni, findEnd, chatCommandInitial, chatCommandPrivate, chatCommandEnd, chatCommandMessage = message:find("([%*%@])(.+)([%*%@])(.*)")
  if findIni ~= nil and findIni == 1 then -- player used private chat command
    if chatCommandInitial == chatCommandEnd then
      chatCommandPrivateRepeat = false
      if chatCommandInitial == "*" then
        setTextEditText('*'.. chatCommandPrivate .. '* ')
      end
      message = chatCommandMessage:trim()
      chatCommandPrivateReady = true
  end
  end

  message = message:gsub("^(%s*)(.*)","%2") -- remove space characters from message init
  if #message == 0 then return end

  -- add new command to history
  currentMessageIndex = 0
  if #messageHistory == 0 or messageHistory[#messageHistory] ~= originalMessage then
    table.insert(messageHistory, originalMessage)
    if #messageHistory > MAX_HISTORY then
      table.remove(messageHistory, 1)
    end
  end

  local speaktypedesc
  if (channel or tab == defaultTab) and not chatCommandPrivateReady then
    if tab == defaultTab then
      speaktypedesc = chatCommandSayMode or SayModes[consolePanel:getChildById('sayModeButton').sayMode].speakTypeDesc
      if speaktypedesc ~= 'say' then sayModeChange(2) end -- head back to say mode
    else
      speaktypedesc = chatCommandSayMode or 'channelYellow'
    end

    g_game.talkChannel(SpeakTypesSettings[speaktypedesc].speakType, channel, message)
    return
  else
    local isPrivateCommand = false
    local priv = true
    local tabname = name
    if chatCommandPrivateReady then
      speaktypedesc = 'privatePlayerToPlayer'
      name = chatCommandPrivate
      isPrivateCommand = true
    elseif tab.npcChat then
      speaktypedesc = 'privatePlayerToNpc'
    elseif tab == violationReportTab then
      if violationReportTab.locked then
        modules.game_textmessage.displayFailureMessage('Wait for a gamemaster reply.')
        return
      end
      speaktypedesc = 'rvrContinue'
      tabname = tr('Report Rule') .. '...'
    elseif tab.violationChatName then
      speaktypedesc = 'rvrAnswerTo'
      name = tab.violationChatName
      tabname = tab.violationChatName .. '\'...'
    else
      speaktypedesc = 'privatePlayerToPlayer'
    end


    local speaktype = SpeakTypesSettings[speaktypedesc]
    local player = g_game.getLocalPlayer()
    g_game.talkPrivate(speaktype.speakType, name, message)

    message = applyMessagePrefixies(g_game.getCharacterName(), player:getLevel(), message)
    addPrivateText(message, speaktype, tabname, isPrivateCommand, g_game.getCharacterName())
  end
end



function getOwnPrivateTab()
  if not ownPrivateName then return end
  return getTab(ownPrivateName)
end

function setIgnoreNpcMessages(ignore)
  ignoreNpcMessages = ignore
end

function navigateMessageHistory(step)
  local numCommands = #messageHistory
  if numCommands > 0 then
    currentMessageIndex = math.min(math.max(currentMessageIndex + step, 0), numCommands)
    if currentMessageIndex > 0 then
      local command = messageHistory[numCommands - currentMessageIndex + 1]
      setTextEditText(command)
    else
      consoleTextEdit:clearText()
    end
  end
end

function clearChannel(consoleTabBar)
  consoleTabBar:getCurrentTab().tabPanel:getChildById('consoleBuffer'):destroyChildren()
end

function setTextEditText(text)
  consoleTextEdit:setText(text)
  consoleTextEdit:setCursorPos(-1)
end

function openHelp()
  local helpChannel = 9
  if g_game.getClientVersion() <= 810 then
    helpChannel = 8
  end
  g_game.joinChannel(helpChannel)
end

function openPlayerReportRuleViolationWindow()
  if violationWindow or violationReportTab then return end
  violationWindow = g_ui.loadUI('violationwindow', rootWidget)
  violationWindow.onEscape = function()
    violationWindow:destroy()
    violationWindow = nil
  end
  violationWindow.onEnter = function()
    local text = violationWindow:getChildById('text'):getText()
    g_game.talkChannel(MessageModes.RVRChannel, 0, text)
    violationReportTab = addTab(tr('Report Rule') .. '...', true)
    addTabText(tr('Please wait patiently for a gamemaster to reply') .. '.', SpeakTypesSettings.privateRed, violationReportTab)
    addTabText(applyMessagePrefixies(g_game.getCharacterName(), 0, text),  SpeakTypesSettings.say, violationReportTab, g_game.getCharacterName())
    violationReportTab.locked = true
    violationWindow:destroy()
    violationWindow = nil
  end
end

function addTab(name, focus)
  local tab = getTab(name)
  if tab then -- is channel already open
    if not focus then focus = true end
  else
    tab = consoleTabBar:addTab(name, nil, processChannelTabMenu)
  end
  if focus then
    consoleTabBar:selectTab(tab)
  end
  return tab
end


function removeTab(tab)
  if type(tab) == 'string' then
    tab = consoleTabBar:getTab(tab)
  end

  if tab == defaultTab or tab == serverTab then
    return
  end

  if tab == violationReportTab then
    g_game.cancelRuleViolation()
    violationReportTab = nil
  elseif tab.violationChatName then
    g_game.closeRuleViolation(tab.violationChatName)
  elseif tab.channelId then
    -- notificate the server that we are leaving the channel
    for k, v in pairs(channels) do
      if (k == tab.channelId) then channels[k] = nil end
    end
    g_game.leaveChannel(tab.channelId)
  elseif tab:getText() == "NPCs" then
    g_game.closeNpcChannel()
  end

  if getCurrentTab() == tab then
    consoleTabBar:selectTab(defaultTab)
  end
  consoleTabBar:removeTab(tab)
end

function removeCurrentTab()
  removeTab(consoleTabBar:getCurrentTab())
end

function getTab(name)
  return consoleTabBar:getTab(name)
end

function getChannelTab(channelId)
  local channel = channels[channelId]
  if channel then
    return getTab(channel)
  end
  return nil
end

function getRuleViolationsTab()
  if violationsChannelId then
    return getChannelTab(violationsChannelId)
  end
  return nil
end

function getCurrentTab()
  return consoleTabBar:getCurrentTab()
end

function addChannel(name, id)
  channels[id] = name
  local focus = not table.find(ignoredChannels, id)
  local tab = addTab(name, focus)
  tab.channelId = id
  return tab
end

function addPrivateChannel(receiver)
  channels[receiver] = receiver
  return addTab(receiver, true)
end

function addPrivateText(text, speaktype, name, isPrivateCommand, creatureName)
  local focus = false
  if speaktype.npcChat then
    name = 'NPCs'
    focus = true
  end

  local privateTab = getTab(name)
  if privateTab == nil then
    if (modules.client_options.getOption('showPrivateMessagesInConsole') and not focus) or (isPrivateCommand and not privateTab) then
      privateTab = defaultTab
    else
      privateTab = addTab(name, focus)
      channels[name] = name
    end
    privateTab.npcChat = speaktype.npcChat
  elseif focus then
    consoleTabBar:selectTab(privateTab)
  end
  if string.find(creatureName, "%[ADM%]") then
    addTabText(text, speaktype, privateTab, creatureName, "#FA5252")
    return
  elseif string.find(creatureName, "%[GM%]") then
    addTabText(text, speaktype, privateTab, creatureName, "#25AAD7")
    return
  elseif string.find(creatureName, "%[TUTOR%]") then
    addTabText(text, speaktype, privateTab, creatureName, "#E6871C")
    return
  end
  addTabText(text, speaktype, privateTab, creatureName)
end

function addText(text, speaktype, tabName, creatureName, color)
  local tab = getTab(tabName)
  if tab ~= nil then
    addTabText(text, speaktype, tab, creatureName, color)
  end
end


local letterWidth = {  -- New line (10) and Space (32) have width 1 because they are printed and not replaced with spacer
  [10] = 1, [32] = 1, [33] = 3, [34] = 6, [35] = 8, [36] = 7, [37] = 13, [38] = 9, [39] = 3, [40] = 5, [41] = 5, [42] = 6, [43] = 8, [44] = 4, [45] = 5, [46] = 3, [47] = 8,
  [48] = 7, [49] = 6, [50] = 7, [51] = 7, [52] = 7, [53] = 7, [54] = 7, [55] = 7, [56] = 7, [57] = 7, [58] = 3, [59] = 4, [60] = 8, [61] = 8, [62] = 8, [63] = 6,
  [64] = 10, [65] = 9, [66] = 7, [67] = 7, [68] = 8, [69] = 7, [70] = 7, [71] = 8, [72] = 8, [73] = 5, [74] = 5, [75] = 7, [76] = 7, [77] = 9, [78] = 8, [79] = 8,
  [80] = 7, [81] = 8, [82] = 8, [83] = 7, [84] = 8, [85] = 8, [86] = 8, [87] = 12, [88] = 8, [89] = 8, [90] = 7, [91] = 5, [92] = 8, [93] = 5, [94] = 9, [95] = 8,
  [96] = 5, [97] = 7, [98] = 7, [99] = 6, [100] = 7, [101] = 7, [102] = 5, [103] = 7, [104] = 7, [105] = 3, [106] = 4, [107] = 7, [108] = 3, [109] = 11, [110] = 7,
  [111] = 7, [112] = 7, [113] = 7, [114] = 6, [115] = 6, [116] = 5, [117] = 7, [118] = 8, [119] = 10, [120] = 8, [121] = 8, [122] = 6, [123] = 7, [124] = 4, [125] = 7, [126] = 8,
  [127] = 1, [128] = 7, [129] = 6, [130] = 3, [131] = 7, [132] = 6, [133] = 11, [134] = 7, [135] = 7, [136] = 7, [137] = 13, [138] = 7, [139] = 4, [140] = 11, [141] = 6, [142] = 6,
  [143] = 6, [144] = 6, [145] = 4, [146] = 3, [147] = 7, [148] = 6, [149] = 6, [150] = 7, [151] = 10, [152] = 7, [153] = 10, [154] = 6, [155] = 5, [156] = 11, [157] = 6, [158] = 6,
  [159] = 8, [160] = 4, [161] = 3, [162] = 7, [163] = 7, [164] = 7, [165] = 8, [166] = 4, [167] = 7, [168] = 6, [169] = 10, [170] = 6, [171] = 8, [172] = 8, [173] = 16, [174] = 10,
  [175] = 8, [176] = 5, [177] = 8, [178] = 5, [179] = 5, [180] = 6, [181] = 7, [182] = 7, [183] = 3, [184] = 5, [185] = 6, [186] = 6, [187] = 8, [188] = 12, [189] = 12, [190] = 12,
  [191] = 6, [192] = 9, [193] = 9, [194] = 9, [195] = 9, [196] = 9, [197] = 9, [198] = 11, [199] = 7, [200] = 7, [201] = 7, [202] = 7, [203] = 7, [204] = 5, [205] = 5, [206] = 6,
  [207] = 5, [208] = 8, [209] = 8, [210] = 8, [211] = 8, [212] = 8, [213] = 8, [214] = 8, [215] = 8, [216] = 8, [217] = 8, [218] = 8, [219] = 8, [220] = 8, [221] = 8, [222] = 7,
  [223] = 7, [224] = 7, [225] = 7, [226] = 7, [227] = 7, [228] = 7, [229] = 7, [230] = 11, [231] = 6, [232] = 7, [233] = 7, [234] = 7, [235] = 7, [236] = 3, [237] = 4, [238] = 4,
  [239] = 4, [240] = 7, [241] = 7, [242] = 7, [243] = 7, [244] = 7, [245] = 7, [246] = 7, [247] = 9, [248] = 7, [249] = 7, [250] = 7, [251] = 7, [252] = 7, [253] = 8, [254] = 7, [255] = 8
}


function applyMessagePrefixies(name, level, message)
  if name then
    if modules.client_options.getOption('showLevelsInConsole') and level > 0 then
      message = name .. ' [' .. level .. ']: ' .. message
    else
      message = name .. ': ' .. message
    end
  end
  return message
end

function getHighlightedText(text)
  local tmpData = {}

  repeat
    local tmp = {string.find(text, "{([^}]+)}", tmpData[#tmpData-1])}
    for _, v in pairs(tmp) do
      table.insert(tmpData, v)
    end
  until not(string.find(text, "{([^}]+)}", tmpData[#tmpData-1]))

  return tmpData
end

function getNewHighlightedText(text, color, highlightColor)
  local tmpData = {}
  local result = ""

  for i, part in ipairs(text:split("{")) do
    if i == 1 then
      result = result .. string.format("{%s, %s}", part, color)
    else
      for j, part2 in ipairs(part:split("}")) do
        if j == 1 then
          result = result .. string.format("{%s, %s}", part2, highlightColor)
        else
          result = result .. string.format("{%s, %s}", part2, color)
        end
      end
    end
  end

  return result
end



local isPointerActive = false

function addTabText(text, speaktype, tab, creatureName, color)
  if not tab or tab.locked or not text or #text == 0 then
    return
  end

  local timestamp = " "
  if modules.client_options.getOption('showTimestampsInConsole') then
    timestamp = os.date('%H:%M') .. ' '
  end

  local panel = consoleTabBar:getTabPanel(tab)
  local consoleBuffer = panel:getChildById('consoleBuffer')
  consoleTabBar:blinkTab(tab)

  local label = g_ui.createWidget('ConsoleLabel', consoleBuffer)
  label:setId('consoleLabel' .. consoleBuffer:getChildCount())

  local textFormated
  if color then
    textFormated = string.format("{%s, %s} {%s, %s}", timestamp, "gray", text, color)
  else
    textFormated = string.format("{%s, %s} {%s, %s}", timestamp, "gray", text, speaktype.color)
  end
  label:setColoredText(textFormated)

  local consoleScrollBar = panel:getChildById('consoleScrollBar')
  if not isActive() then
    consoleScrollBar:setVisible(false)
  end

  label.highlightInfo = {}

  if speaktype.npcChat and (g_game.getCharacterName() ~= creatureName or g_game.getCharacterName() == 'Account Manager') then
    local highlightData = getHighlightedText(text)
    if #highlightData > 0 then
      local teste = getNewHighlightedText(text, speaktype.color, "yellow")
      local labelHighlight = g_ui.createWidget('ConsolePhantomLabel', label)
      labelHighlight:fill('parent')
      labelHighlight:setId('consoleLabelHighlight' .. consoleBuffer:getChildCount())
      labelHighlight.onHoverChange = function(self, hovered)
        if not hovered and isPointerActive then
          g_mouse.popCursor()
          isPointerActive = false
        end
      end

      local highlightOptions = {}

      for i = 1, #highlightData / 3 do
        local dataBlock = { _start = highlightData[(i-1)*3+1], _end = highlightData[(i-1)*3+2], words = highlightData[(i-1)*3+3] }
        text = text:gsub("%{(.-)%}", dataBlock.words, 1)

        highlightData[(i-1)*3+1] = dataBlock._start - ((i-1) * 2)
        highlightData[(i-1)*3+2] = dataBlock._end - (1 + (i-1) * 2)
      end
      --label:setText(text)
      label:setColoredText(teste)

      local drawText = label:getDrawText()
      local tmpText = ""
      for i = 1, #highlightData / 3 do
        local dataBlock = { _start = highlightData[(i-1)*3+1], _end = highlightData[(i-1)*3+2], words = highlightData[(i-1)*3+3] }
        local lastBlockEnd = (highlightData[(i-2)*3+2] or 1)

        for i = dataBlock._start, dataBlock._end do
          label.highlightInfo[i] = dataBlock.words
        end

        for letter = lastBlockEnd, dataBlock._start-1 do
          local tmpChar = string.byte(drawText:sub(letter, letter))
          local fillChar = (tmpChar == 10 or tmpChar == 32) and string.char(tmpChar) or string.char(127)

          tmpText = tmpText .. string.rep(fillChar, letterWidth[tmpChar])
        end
        tmpText = tmpText .. dataBlock.words
      end

      local finalBlockEnd = (highlightData[(#highlightData/3-1)*3+2] or 1)
      for letter = finalBlockEnd, drawText:len() do
        local tmpChar = string.byte(drawText:sub(letter, letter))
        local fillChar = (tmpChar == 10 or tmpChar == 32) and string.char(tmpChar) or string.char(127)

        tmpText = tmpText .. string.rep(fillChar, letterWidth[tmpChar])
      end
    end
  end


  label.name = creatureName
  consoleBuffer.onMouseRelease = function(self, mousePos, mouseButton)
    processMessageMenu(mousePos, mouseButton, nil, nil, nil, tab)
  end

  label.onMouseMove = function(self, mousePos, mouseMoved)
    local position = label:getTextPos(mousePos)
    if position and label.highlightInfo[position] then
      if not isPointerActive then
        g_mouse.pushCursor('pointer')
        isPointerActive = true
      end
    else
      if isPointerActive then
        g_mouse.popCursor()
        isPointerActive = false
      end
    end
  end

  label.onMouseRelease = function(self, mousePos, mouseButton)
    local position = label:getTextPos(mousePos)
    if position and label.highlightInfo[position] then
      label:setCursor("pointer")
    end
    if mouseButton == MouseLeftButton then
      local position = label:getTextPos(mousePos)
      if position and label.highlightInfo[position] then
        sendMessage(label.highlightInfo[position], npcTab)
      end
    elseif mouseButton == MouseRightButton then
      processMessageMenu(mousePos, mouseButton, creatureName, text, self, tab)
    end
  end
  label.onMousePress = function(self, mousePos, button)
    if button == MouseLeftButton then clearSelection(consoleBuffer) end
  end
  label.onDragEnter = function(self, mousePos)
    clearSelection(consoleBuffer)
    return true
  end
  label.onDragLeave = function(self, droppedWidget, mousePos)
    local text = {}
    for selectionChild = consoleBuffer.selection.first, consoleBuffer.selection.last do
      local label = self:getParent():getChildByIndex(selectionChild)
      table.insert(text, label:getSelection())
    end
    consoleBuffer.selectionText = table.concat(text, '\n')
    return true
  end
  label.onDragMove = function(self, mousePos, mouseMoved)
    local parent = self:getParent()
    local parentRect = parent:getPaddingRect()
    local selfIndex = parent:getChildIndex(self)
    local child = parent:getChildByPos(mousePos)

    -- find bonding children
    if not child then
      if mousePos.y < self:getY() then
        for index = selfIndex - 1, 1, -1 do
          local label = parent:getChildByIndex(index)
          if label:getY() + label:getHeight() > parentRect.y then
            if (mousePos.y >= label:getY() and mousePos.y <= label:getY() + label:getHeight()) or index == 1 then
              child = label
              break
            end
          else
            child = parent:getChildByIndex(index + 1)
            break
          end
        end
      elseif mousePos.y > self:getY() + self:getHeight() then
        for index = selfIndex + 1, parent:getChildCount(), 1 do
          local label = parent:getChildByIndex(index)
          if label:getY() < parentRect.y + parentRect.height then
            if (mousePos.y >= label:getY() and mousePos.y <= label:getY() + label:getHeight()) or index == parent:getChildCount() then
              child = label
              break
            end
          else
            child = parent:getChildByIndex(index - 1)
            break
          end
        end
      else
        child = self
      end
    end

    if not child then return false end

    local childIndex = parent:getChildIndex(child)

    -- remove old selection
    clearSelection(consoleBuffer)

    -- update self selection
    local textBegin = self:getTextPos(self:getLastClickPosition())
    local textPos = self:getTextPos(mousePos)
    self:setSelection(textBegin, textPos)

    consoleBuffer.selection = { first = math.min(selfIndex, childIndex), last = math.max(selfIndex, childIndex) }

    -- update siblings selection
    if child ~= self then
      for selectionChild = consoleBuffer.selection.first + 1, consoleBuffer.selection.last - 1 do
        parent:getChildByIndex(selectionChild):selectAll()
      end

      local textPos = child:getTextPos(mousePos)
      if childIndex > selfIndex then
        child:setSelection(0, textPos)
      else
        child:setSelection(string.len(child:getText()), textPos)
      end
    end

    return true
  end

  if consoleBuffer:getChildCount() > MAX_LINES then
    local child = consoleBuffer:getFirstChild()
    clearSelection(consoleBuffer)
    child:destroy()
  end
end

function removeTabLabelByName(tab, name)
  local panel = consoleTabBar:getTabPanel(tab)
  local consoleBuffer = panel:getChildById('consoleBuffer')
  for _,label in pairs(consoleBuffer:getChildren()) do
    if label.name == name then
      label:destroy()
    end
  end
end

function processChannelTabMenu(tab, mousePos, mouseButton)
  local menu = g_ui.createWidget('PopupMenu')

  channelName = tab:getText()
  if tab ~= defaultTab and tab ~= serverTab then
    menu:addOption(tr('Close'), function() removeTab(channelName) end)
    --menu:addOption(tr('Show Server Messages'), function() --[[TODO]] end)
    menu:addSeparator()
  end

  if consoleTabBar:getCurrentTab() == tab then
    menu:addOption(tr('Clear Messages'), function() clearChannel(consoleTabBar) end)
  end
  --menu:addOption(tr('Save Messages'), function() --[[TODO]] end)

  menu:display(mousePos)
end

function processMessageMenu(mousePos, mouseButton, creatureName, text, label, tab)
  if mouseButton == MouseRightButton then
    local menu = g_ui.createWidget('PopupMenu')
    if creatureName and #creatureName > 0 then
      if creatureName ~= g_game.getCharacterName() then
        menu:addOption(tr('Message to ' .. creatureName), function () g_game.openPrivateChannel(creatureName) end)
        if not g_game.getLocalPlayer():hasVip(creatureName) then
          menu:addOption(tr('Add to VIP list'), function () g_game.addVip(creatureName) end)
        end
        if modules.game_console.getOwnPrivateTab() then
          menu:addSeparator()
          menu:addOption(tr('Invite to private chat'), function() g_game.inviteToOwnChannel(creatureName) end)
          menu:addOption(tr('Exclude from private chat'), function() g_game.excludeFromOwnChannel(creatureName) end)
        end
        if isIgnored(creatureName) then
          menu:addOption(tr('Unignore') .. ' ' .. creatureName, function() removeIgnoredPlayer(creatureName) end)
        else
          menu:addOption(tr('Ignore') .. ' ' .. creatureName, function() addIgnoredPlayer(creatureName) end)
        end
        menu:addSeparator()
      end
      if modules.game_ruleviolation.hasWindowAccess() then
        menu:addOption(tr('Rule Violation'), function() modules.game_ruleviolation.show(creatureName, text:match('.+%:%s(.+)')) end)
        menu:addSeparator()
      end

      menu:addOption(tr('Copy name'), function () g_window.setClipboardText(creatureName) end)
    end

    if not tab then return end
    local selection = tab.tabPanel:getChildById('consoleBuffer').selectionText
    if selection and #selection > 0 then
      menu:addOption(tr('Copy'), function() g_window.setClipboardText(selection) end, '(Ctrl+C)')
    end
    if text then
      menu:addOption(tr('Copy message'), function() g_window.setClipboardText(text) end)
    end
    menu:addOption(tr('Select all'), function() selectAll(tab.tabPanel:getChildById('consoleBuffer')) end)
    if tab.violations then
      menu:addSeparator()
      menu:addOption(tr('Process') .. ' ' .. creatureName, function() processViolation(creatureName, text) end)
      menu:addOption(tr('Remove') .. ' ' .. creatureName, function() g_game.closeRuleViolation(creatureName) end)
    end
    menu:display(mousePos)
  end
end

function terminate()
  disconnect(g_game, {
    onTalk = onTalk,
    onChannelList = onChannelList,
    onOpenChannel = onOpenChannel,
    onOpenPrivateChannel = onOpenPrivateChannel,
    onOpenOwnPrivateChannel = onOpenPrivateChannel,
    onCloseChannel = onCloseChannel,
    onRuleViolationChannel = onRuleViolationChannel,
    onRuleViolationRemove = onRuleViolationRemove,
    onRuleViolationCancel = onRuleViolationCancel,
    onRuleViolationLock = onRuleViolationLock,
    onGameEnd = offline,
    onGameStart = online,
  })
  if g_game.isOnline() then clear() end
  consoleToggleChat = nil
  consolePanel:destroy()
end

function save()
  local settings = {}
  settings.messageHistory = messageHistory
  g_settings.setNode('game_console', settings)
end

function load()
  local settings = g_settings.getNode('game_console')
  if settings then
    messageHistory = settings.messageHistory or {}
  end
  loadCommunicationSettings()
end

function onTabChange(tabBar, tab)
  if tab == defaultTab or tab == serverTab then
    consolePanel:getChildById('closeChannelButton'):disable()
  else
    consolePanel:getChildById('closeChannelButton'):enable()
  end
end

function clear()
  -- save last open channels
  local lastChannelsOpen = g_settings.getNode('lastChannelsOpen') or {}
  local char = g_game.getCharacterName()
  local savedChannels = {}
  local set = false
  for channelId, channelName in pairs(channels) do
    if type(channelId) == 'number' then
      savedChannels[channelName] = channelId
      set = true
    end
  end
  if set then
    lastChannelsOpen[char] = savedChannels
  else
    lastChannelsOpen[char] = nil
  end
  g_settings.setNode('lastChannelsOpen', lastChannelsOpen)

  -- close channels
  for _, channelName in pairs(channels) do
    local tab = consoleTabBar:getTab(channelName)
    consoleTabBar:removeTab(tab)
  end
  channels = {}

  --consoleTabBar:removeTab(defaultTab)
  --consoleTabBar:removeTab(serverTab)

  local npcTab = consoleTabBar:getTab('NPCs')
  if npcTab then
    consoleTabBar:removeTab(npcTab)
  end


  if violationReportTab then
    consoleTabBar:removeTab(violationReportTab)
    violationReportTab = nil
  end

  consoleTextEdit:clearText()

  if violationWindow then
    violationWindow:destroy()
    violationWindow = nil
  end

  if channelsWindow then
    channelsWindow:destroy()
    channelsWindow = nil
  end
end

function enableScroll(check)
  local currentTab = consoleTabBar:getCurrentTab()
  if not currentTab then return end
  local tabPanel = currentTab.tabPanel
  if not tabPanel then return end
  local consoleScrollBar = tabPanel:getChildById('consoleScrollBar')
  if not consoleScrollBar then return end

  consoleScrollBar:setVisible(check)
end


function enableResize(e)
  if e then
    consolePanel:getChildById('rB'):setVisible(true)
    consolePanel:getChildById('rB2'):setVisible(true)
  else
    consolePanel:getChildById('rB'):setVisible(false)
    consolePanel:getChildById('rB2'):setVisible(false)
  end
end

function offline()
  if g_game.getClientVersion() < 862 then
    local gameRootPanel = modules.game_interface.getRootPanel()
    g_keyboard.unbindKeyDown('Ctrl+R', gameRootPanel)
  end
  saveChatStatus()
  clear()
  g_mouse.popCursor()
end

function saveAndClickLockButton()
  local lockButton = consolePanel:getChildById('lockButton')
  valor =  g_settings.getBoolean('LockChat')
  if not valor then
    enableResize(true)
    lockButton:setOpacity(0.6)
    g_settings.set('LockChat', valor)
    lockButton:setImageSource('/images/game/console/unlockSmall')
    valor = true
    consolePanel:getChildById('background'):setPhantom(true)
  else
    consolePanel:getChildById('background'):setPhantom(false)
    lockButton:setImageSource('/images/game/console/lockSmall')
    lockButton:setOpacity(1)
    enableResize(false)
    valor = false
  end
  g_settings.set('LockChat', valor)
  g_settings.save()
end

function CheckStatusLockButton()
  local panel =  consolePanel:getChildById('lockButton')
  local LockChat = g_settings.getBoolean('LockChat')
  if LockChat then
    panel:setOpacity(0.6)
    panel:setImageSource('/images/game/console/unlockSmall')
    consolePanel:getChildById('background'):setPhantom(true)
  else
    consolePanel:getChildById('background'):setPhantom(false)
    panel:setImageSource('/images/game/console/lockSmall')
    panel:setOpacity(1)
  end
end

function onTalk(name, level, mode, message, channelId, creaturePos)
  if mode == MessageModes.GamemasterBroadcast then
    modules.game_textmessage.displayBroadcastMessage(name .. ': ' .. message)
    return
  end

  local isNpcMode = (mode == MessageModes.NpcFromStartBlock or mode == MessageModes.NpcFrom)

  if ignoreNpcMessages and isNpcMode then
    return
  end

  speaktype = SpeakTypes[mode]

  if not speaktype then
    perror('unhandled onTalk message mode ' .. mode .. ': ' .. message)
    return
  end

  local localPlayer = g_game.getLocalPlayer()
  if name ~= g_game.getCharacterName() and isUsingIgnoreList() and not (isUsingWhiteList()) or
    (isUsingWhiteList() and not (isWhitelisted(name)) and not (isAllowingVIPs() and localPlayer:hasVip(name))) then
    if mode == MessageModes.Yell and isIgnoringYelling() then
      return
    elseif speaktype.private and isIgnoringPrivate() and not isNpcMode then
      return
    elseif isIgnored(name) then
      return
    end
  end

  if mode == MessageModes.RVRChannel then
    channelId = violationsChannelId
  end

  if (mode == MessageModes.Say or mode == MessageModes.Whisper or mode == MessageModes.Yell or mode ==
    MessageModes.Spell or mode == MessageModes.MonsterSay or mode == MessageModes.MonsterYell or mode ==
    MessageModes.NpcFrom or mode == MessageModes.BarkLow or mode == MessageModes.BarkLoud or mode ==
    MessageModes.NpcFromStartBlock) and creaturePos then
    local staticText = StaticText.create()
    -- Remove curly braces from screen message
    local staticMessage = message
    if isNpcMode then
      local highlightData = getHighlightedText(staticMessage)
      if #highlightData > 0 then
        for i = 1, #highlightData / 3 do
          local dataBlock = {
            _start = highlightData[(i - 1) * 3 + 1],
            _end = highlightData[(i - 1) * 3 + 2],
            words = highlightData[(i - 1) * 3 + 3]
          }
          staticMessage = staticMessage:gsub('{' .. dataBlock.words .. '}', dataBlock.words)
        end
      end
      staticText:setColor(speaktype.color)
    end

    staticText:addMessage(name, mode, staticMessage)
    g_map.addStaticText(staticText, creaturePos)
  end

  local defaultMessage = mode <= 3 and true or false

  if speaktype == SpeakTypesSettings.none then
    return
  end

  if speaktype.hideInConsole then
    return
  end

  local composedMessage = applyMessagePrefixies(name, level, message)

  if mode == MessageModes.RVRAnswer then
    violationReportTab.locked = false
    addTabText(composedMessage, speaktype, violationReportTab, name)
  elseif mode == MessageModes.RVRContinue then
    addText(composedMessage, speaktype, name .. '\'...', name)
  elseif speaktype.private then
    addPrivateText(composedMessage, speaktype, name, false, name)
    if modules.client_options.getOption('showPrivateMessagesOnScreen') and speaktype ~=
      SpeakTypesSettings.privateNpcToPlayer then
      modules.game_textmessage.displayPrivateMessage(name .. ':\n' .. message)
    end
  else
    local channel = tr('Local Chat')
    if not defaultMessage then
      channel = channels[channelId]
    end

    if channel then
      addText(composedMessage, speaktype, channel, name)
    else
      pwarning('message in channel id ' .. channelId .. ' which is unknown, this is a server bug, relogin if you want to see messages in this channel')
    end
  end
end

function onOpenChannel(channelId, channelName)
  addChannel(channelName, channelId)
end

function onOpenPrivateChannel(receiver)
  addPrivateChannel(receiver)
end

function onOpenOwnPrivateChannel(channelId, channelName)
  local privateTab = getTab(channelName)
  if privateTab == nil then
    addChannel(channelName, channelId)
  end
  ownPrivateName = channelName
end

function onCloseChannel(channelId)
  local channel = channels[channelId]
  if channel then
    local tab = getTab(channel)
    if tab then
      consoleTabBar:removeTab(tab)
    end
    for k, v in pairs(channels) do
      if (k == tab.channelId) then channels[k] = nil end
    end
  end
end

function processViolation(name, text)
  local tabname = name .. '\'...'
  local tab = addTab(tabname, true)
  channels[tabname] = tabname
  tab.violationChatName = name
  g_game.openRuleViolation(name)
  addTabText(text, SpeakTypesSettings.say, tab, name)
end

function onRuleViolationChannel(channelId)
  violationsChannelId = channelId
  local tab = addChannel(tr('Rule Violations'), channelId)
  tab.violations = true
end

function onRuleViolationRemove(name)
  local tab = getRuleViolationsTab()
  if not tab then return end
  removeTabLabelByName(tab, name)
end

function onRuleViolationCancel(name)
  local tab = getTab(name .. '\'...')
  if not tab then return end
  addTabText(tr('%s has finished the request', name) .. '.', SpeakTypesSettings.privateRed, tab)
  tab.locked = true
end

function onRuleViolationLock()
  if not violationReportTab then return end
  violationReportTab.locked = false
  addTabText(tr('Your request has been closed') .. '.', SpeakTypesSettings.privateRed, violationReportTab)
  violationReportTab.locked = true
end

function show()
  local player = g_game.getLocalPlayer()
  if not consolePanel:isVisible() then
    addEvent(function() g_effects.fadeIn(consolePanel, 250, 0, 250*0.95) end)
  end
  consolePanel:show()
  --consolePanel:raise()
  return true
end

function toggleChat()
  if not consolePanel or not modules.game_interface.getRootPanel():isFocused() then return end
  if not isActive() then
    consolePanel:getChildById('hideChatButton2'):setVisible(false)
    consolePanel:getChildById('hidesubchat'):setVisible(true)
    consolePanel:getChildById('background'):setVisible(true)
    HideSubChat(true)
    enableScroll(true)
    consolePanel:getChildById('enterBackground'):setVisible(true)
    consolePanel:getChildById('consoleTextEdit'):setFocusable(true)
    consolePanel:getChildById('consoleTextEdit'):setVisible(true)
    consolePanel:getChildById('rB2'):setVisible(true)
    consolePanel:getChildById('rB'):setVisible(true)
    consolePanel:getChildById('textLineWindow'):setVisible(true)
    consolePanel:getChildById('hideChatButton'):setVisible(true)
    consolePanel:getChildById('ignoreButton'):setVisible(true)
    consolePanel:getChildById('channelsButton'):setVisible(true)
    consolePanel:getChildById('clearChannelButton'):setVisible(true)
    consolePanel:getChildById('closeChannelButton'):setVisible(true)
    consolePanel:getChildById('nextChannelButton'):setVisible(true)
    consolePanel:getChildById('consoleTabBar'):setVisible(true)
    consolePanel:getChildById('prevChannelButton'):setVisible(true)
    consolePanel:getChildById('lockButton'):setVisible(true)
    consolePanel:setFocusable(true)
    consolePanel:focus()
    consoleTextEdit:focus()
    hk = false
    unbindMovingKeys()
    valor =  g_settings.getBoolean('LockChat')
    if valor then
      consolePanel:setPhantom(false)
    end
  else
    consolePanel:setPhantom(true)
    bindMovingKeys()
    consolePanel:setFocusable(false)
    HideSubChat(false)
    enableScroll(false)
    consolePanel:getChildById('hidesubchat'):setVisible(false)
    consolePanel:getChildById('rB2'):setVisible(false)
    consolePanel:getChildById('rB'):setVisible(false)
    consolePanel:getChildById('background'):setVisible(false)
    consolePanel:getChildById('enterBackground'):setVisible(false)
    consolePanel:getChildById('consoleTextEdit'):setFocusable(false)
    consolePanel:getChildById('consoleTextEdit'):setVisible(false)
    consolePanel:getChildById('textLineWindow'):setVisible(false)
    consolePanel:getChildById('ignoreButton'):setVisible(false)
    consolePanel:getChildById('channelsButton'):setVisible(false)
    consolePanel:getChildById('clearChannelButton'):setVisible(false)
    consolePanel:getChildById('closeChannelButton'):setVisible(false)
    consolePanel:getChildById('nextChannelButton'):setVisible(false)
    consolePanel:getChildById('consoleTabBar'):setVisible(false)
    consolePanel:getChildById('prevChannelButton'):setVisible(false)
    consolePanel:getChildById('lockButton'):setVisible(false)
    consolePanel:getChildById('hideChatButton'):setVisible(false)
    consolePanel:getChildById('hideChatButton2'):setVisible(true)
    hk = true
  end
end

function enableChat(temporarily)
  consoleTextEdit:focus()
  local gameRootPanel = modules.game_interface.getRootPanel()
  g_keyboard.unbindKeyDown("Enter", gameRootPanel)

  if temporarily then
    local quickFunc = function()
      if not g_game.isOnline() then return end
      g_keyboard.unbindKeyDown("Enter", gameRootPanel)
      g_keyboard.unbindKeyDown("Escape", gameRootPanel)
      disableChat(temporarily)
    end
    g_keyboard.bindKeyDown("Enter", quickFunc, gameRootPanel)
    g_keyboard.bindKeyDown("Escape", quickFunc, gameRootPanel)
  end
end

function disableChat(temporarily)
  local quickFunc = function()
    if not g_game.isOnline() then return end
    enableChat(true)
  end

  local gameRootPanel = modules.game_interface.getRootPanel()
  g_keyboard.bindKeyDown("Enter", quickFunc, gameRootPanel)
end

function isChatEnabled()
  return consoleTextEdit:isVisible()
end



function doChannelListSubmit()
  local channelListPanel = channelsWindow:getChildById('channelList')
  local openPrivateChannelWith = channelsWindow:getChildById('openPrivateChannelWith'):getText()
  if openPrivateChannelWith ~= '' then
    if openPrivateChannelWith:lower() ~= g_game.getCharacterName():lower() then
      g_game.openPrivateChannel(openPrivateChannelWith)
    else
      modules.game_textmessage.displayFailureMessage('You cannot create a private chat channel with yourself.')
    end
  else
    local selectedChannelLabel = channelListPanel:getFocusedChild()
    if not selectedChannelLabel then return end
    if selectedChannelLabel.channelId == 0xFFFF then
      g_game.openOwnChannel()
    else
      g_game.joinChannel(selectedChannelLabel.channelId)
    end
  end

  channelsWindow:destroy()
end

function onChannelList(channelList)
  if channelsWindow then channelsWindow:destroy() end
  channelsWindow = g_ui.displayUI('channelswindow')
  local channelListPanel = channelsWindow:getChildById('channelList')
  channelsWindow.onEnter = doChannelListSubmit
  channelsWindow.onDestroy = function() channelsWindow = nil end
  g_keyboard.bindKeyPress('Down', function() channelListPanel:focusNextChild(KeyboardFocusReason) end, channelsWindow)
  g_keyboard.bindKeyPress('Up', function() channelListPanel:focusPreviousChild(KeyboardFocusReason) end, channelsWindow)

  for k,v in pairs(channelList) do
    local channelId = v[1]
    local channelName = v[2]

    if #channelName > 0 then
      local label = g_ui.createWidget('ChannelListLabel', channelListPanel)
      label.channelId = channelId
      label:setText(channelName)

      label:setPhantom(false)
      label.onDoubleClick = doChannelListSubmit
    end
  end
end

function loadCommunicationSettings()
  communicationSettings.whitelistedPlayers = {}
  communicationSettings.ignoredPlayers = {}

  local ignoreNode = g_settings.getNode('IgnorePlayers')
  if ignoreNode then
    for i = 1, #ignoreNode do
      table.insert(communicationSettings.ignoredPlayers, ignoreNode[i])
    end
  end

  local whitelistNode = g_settings.getNode('WhitelistedPlayers')
  if whitelistNode then
    for i = 1, #whitelistNode do
      table.insert(communicationSettings.whitelistedPlayers, whitelistNode[i])
    end
  end

  communicationSettings.useIgnoreList = g_settings.getBoolean('UseIgnoreList')
  communicationSettings.useWhiteList = g_settings.getBoolean('UseWhiteList')
  communicationSettings.privateMessages = g_settings.getBoolean('IgnorePrivateMessages')
  communicationSettings.yelling = g_settings.getBoolean('IgnoreYelling')
  communicationSettings.allowVIPs = g_settings.getBoolean('AllowVIPs')
end

function saveCommunicationSettings()
  local tmpIgnoreList = {}
  local ignoredPlayers = getIgnoredPlayers()
  for i = 1, #ignoredPlayers do
    table.insert(tmpIgnoreList, ignoredPlayers[i])
  end

  local tmpWhiteList = {}
  local whitelistedPlayers = getWhitelistedPlayers()
  for i = 1, #whitelistedPlayers do
    table.insert(tmpWhiteList, whitelistedPlayers[i])
  end

  g_settings.set('UseIgnoreList', communicationSettings.useIgnoreList)
  g_settings.set('UseWhiteList', communicationSettings.useWhiteList)
  g_settings.set('IgnorePrivateMessages', communicationSettings.privateMessages)
  g_settings.set('IgnoreYelling', communicationSettings.yelling)
  g_settings.setNode('IgnorePlayers', tmpIgnoreList)
  g_settings.setNode('WhitelistedPlayers', tmpWhiteList)
end

function getIgnoredPlayers()
  return communicationSettings.ignoredPlayers
end

function getWhitelistedPlayers()
  return communicationSettings.whitelistedPlayers
end

function isUsingIgnoreList()
  return communicationSettings.useIgnoreList
end

function isUsingWhiteList()
  return communicationSettings.useWhiteList
end
function isIgnored(name)
  return table.find(communicationSettings.ignoredPlayers, name, true)
end

function addIgnoredPlayer(name)
  if isIgnored(name) then return end
  table.insert(communicationSettings.ignoredPlayers, name)
end

function removeIgnoredPlayer(name)
  table.removevalue(communicationSettings.ignoredPlayers, name)
end

function isWhitelisted(name)
  return table.find(communicationSettings.whitelistedPlayers, name, true)
end

function addWhitelistedPlayer(name)
  if isWhitelisted(name) then return end
  table.insert(communicationSettings.whitelistedPlayers, name)
end

function removeWhitelistedPlayer(name)
  table.removevalue(communicationSettings.whitelistedPlayers, name)
end

function isIgnoringPrivate()
  return communicationSettings.privateMessages
end

function isIgnoringYelling()
  return communicationSettings.yelling
end

function isAllowingVIPs()
  return communicationSettings.allowVIPs
end

function onClickIgnoreButton()
  if communicationWindow then return end
  communicationWindow = g_ui.displayUI('communicationwindow')
  local ignoreListPanel = communicationWindow:getChildById('ignoreList')
  local whiteListPanel = communicationWindow:getChildById('whiteList')
  communicationWindow.onDestroy = function() communicationWindow = nil end

  local useIgnoreListBox = communicationWindow:getChildById('checkboxUseIgnoreList')
  useIgnoreListBox:setChecked(communicationSettings.useIgnoreList)
  local useWhiteListBox = communicationWindow:getChildById('checkboxUseWhiteList')
  useWhiteListBox:setChecked(communicationSettings.useWhiteList)

  local removeIgnoreButton = communicationWindow:getChildById('buttonIgnoreRemove')
  removeIgnoreButton:disable()
  ignoreListPanel.onChildFocusChange = function() removeIgnoreButton:enable() end
  removeIgnoreButton.onClick = function()
    local selection = ignoreListPanel:getFocusedChild()
    if selection then
      ignoreListPanel:removeChild(selection)
      selection:destroy()
    end
    removeIgnoreButton:disable()
  end

  local removeWhitelistButton = communicationWindow:getChildById('buttonWhitelistRemove')
  removeWhitelistButton:disable()
  whiteListPanel.onChildFocusChange = function() removeWhitelistButton:enable() end
  removeWhitelistButton.onClick = function()
    local selection = whiteListPanel:getFocusedChild()
    if selection then
      whiteListPanel:removeChild(selection)
      selection:destroy()
    end
    removeWhitelistButton:disable()
  end

  local newlyIgnoredPlayers = {}
  local addIgnoreName = communicationWindow:getChildById('ignoreNameEdit')
  local addIgnoreButton = communicationWindow:getChildById('buttonIgnoreAdd')
  local addIgnoreFunction = function()
    local newEntry = addIgnoreName:getText()
    if newEntry == '' then return end
    if table.find(getIgnoredPlayers(), newEntry) then return end
    if table.find(newlyIgnoredPlayers, newEntry) then return end
    local label = g_ui.createWidget('IgnoreListLabel', ignoreListPanel)
    label:setText(newEntry)
    table.insert(newlyIgnoredPlayers, newEntry)
    addIgnoreName:setText('')
  end
  addIgnoreButton.onClick = addIgnoreFunction

  local newlyWhitelistedPlayers = {}
  local addWhitelistName = communicationWindow:getChildById('whitelistNameEdit')
  local addWhitelistButton = communicationWindow:getChildById('buttonWhitelistAdd')
  local addWhitelistFunction = function()
    local newEntry = addWhitelistName:getText()
    if newEntry == '' then return end
    if table.find(getWhitelistedPlayers(), newEntry) then return end
    if table.find(newlyWhitelistedPlayers, newEntry) then return end
    local label = g_ui.createWidget('WhiteListLabel', whiteListPanel)
    label:setText(newEntry)
    table.insert(newlyWhitelistedPlayers, newEntry)
    addWhitelistName:setText('')
  end
  addWhitelistButton.onClick = addWhitelistFunction

  communicationWindow.onEnter = function()
    if addWhitelistName:isFocused() then
      addWhitelistFunction()
    elseif addIgnoreName:isFocused() then
      addIgnoreFunction()
    end
  end

  local ignorePrivateMessageBox = communicationWindow:getChildById('checkboxIgnorePrivateMessages')
  ignorePrivateMessageBox:setChecked(communicationSettings.privateMessages)
  local ignoreYellingBox = communicationWindow:getChildById('checkboxIgnoreYelling')
  ignoreYellingBox:setChecked(communicationSettings.yelling)
  local allowVIPsBox = communicationWindow:getChildById('checkboxAllowVIPs')
  allowVIPsBox:setChecked(communicationSettings.allowVIPs)

  local saveButton = communicationWindow:recursiveGetChildById('buttonSave')
  saveButton.onClick = function()
    communicationSettings.ignoredPlayers = {}
    for i = 1, ignoreListPanel:getChildCount() do
      addIgnoredPlayer(ignoreListPanel:getChildByIndex(i):getText())
    end

    communicationSettings.whitelistedPlayers = {}
    for i = 1, whiteListPanel:getChildCount() do
      addWhitelistedPlayer(whiteListPanel:getChildByIndex(i):getText())
    end

    communicationSettings.useIgnoreList = useIgnoreListBox:isChecked()
    communicationSettings.useWhiteList = useWhiteListBox:isChecked()
    communicationSettings.yelling = ignoreYellingBox:isChecked()
    communicationSettings.privateMessages = ignorePrivateMessageBox:isChecked()
    communicationSettings.allowVIPs = allowVIPsBox:isChecked()
    communicationWindow:destroy()
  end

  local cancelButton = communicationWindow:recursiveGetChildById('buttonCancel')
  cancelButton.onClick = function()
    communicationWindow:destroy()
  end

  local ignoredPlayers = getIgnoredPlayers()
  for i = 1, #ignoredPlayers do
    local label = g_ui.createWidget('IgnoreListLabel', ignoreListPanel)
    label:setText(ignoredPlayers[i])
  end

  local whitelistedPlayers = getWhitelistedPlayers()
  for i = 1, #whitelistedPlayers do
    local label = g_ui.createWidget('WhiteListLabel', whiteListPanel)
    label:setText(whitelistedPlayers[i])
  end
end

function HideSubChat(check)
  local panel =  consolePanel:getChildById('contentPanel')
  local valor = g_settings.getBoolean('hidesubchat')
  if not valor then return panel:show() end

  if check then
    panel:show()
  else
    panel:hide()
  end
end

function online()
  if not g_settings.getNode('chat') or not g_settings.getNode('chat').x then
    consolePanel:breakAnchors()
    consolePanel:addAnchor(AnchorLeft, "parent", AnchorLeft)
    consolePanel:addAnchor(AnchorBottom, "parent", AnchorBottom)
    consolePanel:setMarginLeft(3)
    consolePanel:setMarginBottom(100)
  else
    if g_settings.getNode('chat') then
      consolePanel:breakAnchors()

      if g_settings.getNode('chat').rightResize and g_settings.getNode('chat').heightResize then
        consolePanel:setSize({width = g_settings.getNode('chat').rightResize, height = g_settings.getNode('chat').heightResize})
        if g_settings.getNode('chat').heightResize > g_window.getHeight() / 2 + 10 or g_settings.getNode('chat').rightResize > g_window.getWidth() / 2 + 10 then
          consolePanel:setSize({width = 520, height = 252})
          g_settings.save()
        end
      end

      if g_settings.getNode('chat') then 
        consolePanel:setPosition({x = g_settings.getNode('chat').x, y = g_settings.getNode('chat').y})
      end
    end
  end

  consolePanel:getChildById('rB2'):setMaximum(g_window.getHeight() / 2)
  consolePanel:getChildById('rB'):setMaximum(g_window.getWidth() / 2)

  saveChatStatus()
  CheckStatusLockButton()
  if not isActive() then
    consolePanel:setPhantom(true)
    enableResize(false)
  else
    HideSubChat(true)
    enableResize(true)
    consolePanel:setPhantom(false)
  end

  local panel =  consolePanel:getChildById('hidesubchat')
  local valor = g_settings.getBoolean('hidesubchat')
  panel:setChecked(valor)
  panel.onClick = function(widget)
    valor = not valor
    widget:setChecked(valor)
    g_settings.set('hidesubchat', valor)
    g_settings.save()
  end

  defaultTab = addTab(tr('Local Chat'), true)
  serverTab = addTab(tr('Server Log'), false)
  if isActive() then
    consolePanel:getChildById('hideChatButton2'):setVisible(false)
  end
  if g_game.getClientVersion() < 862 then
    g_keyboard.bindKeyDown('Ctrl+R', openPlayerReportRuleViolationWindow)
  end
  -- open last channels
  local lastChannelsOpen = g_settings.getNode('lastChannelsOpen')
  if lastChannelsOpen then
    local savedChannels = lastChannelsOpen[g_game.getCharacterName()]
    if savedChannels then
      for channelName, channelId in pairs(savedChannels) do
        channelId = tonumber(channelId)
        if channelId ~= -1 and channelId < 100 then
          if not table.find(channels, channelId) then
            g_game.joinChannel(channelId)
            table.insert(ignoredChannels, channelId)
          end
        end
      end
    end
  end
  scheduleEvent(function() consoleTabBar:selectTab(defaultTab) end, 500)
  scheduleEvent(function() ignoredChannels = {} end, 3000)
end
