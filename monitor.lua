-- periodic timers

local _, addonData = ...

local LONG_TIME = 2
local SHORT_TIME = 0.5
local SECOND_TIME = 1

local monitor = {
  second_t = {},
  short_t = {},
  long_t = {},

  init = function(self)
    addonData.debug:registerCategory("monitor")
    self.short_t = self:create(SHORT_TIME, self.callback_short)
    self.long_t = self:create(LONG_TIME, self.callback_long)
    self.second_t = self:create(SECOND_TIME, self.callback_sec)
    self:start()
    self.long_t:Play()
  end,

  create = function(_, i, callback, timerRepeat)
    local timer
    local loopType = "REPEAT"

    if timerRepeat == nil then
      timerRepeat = true
    end

    if not timerRepeat then
      loopType = "NONE"
    end

    timer = frame:CreateAnimationGroup()
    timer.anim = timer:CreateAnimation()
    timer.anim:SetDuration(i)
    timer:SetLooping(loopType)
    if timerRepeat then
      timer:SetScript("OnLoop", callback)
    else
      timer:SetScript("OnFinished", callback)
    end
    return timer
  end,

  start = function(self)
    self.short_t:Play()
    self.second_t:Play()
  end,

  stop = function(self)
    self.short_t:Stop()
    self.second_t:Stop()
  end,

  callback_short = function()
    addonData.summon:tick()
  end,

  callback_sec = function()
    addonData.summon:timerSecondTick()
  end,

  callback_long = function()
    addonData.raid:fishArea()
  end,

  callback = function(_, event, ...)
    -- this is a generic debug monitor of events that are under observation
    db("monitor", event, ...)
  end,
}

addonData.monitor = monitor