-- periodic timers

local _, addonData = ...

local monitor = {
  sec_t = {},
  long_t = {},

  init = function(self)
    addonData.debug:registerCategory("monitor")
    self.sec_t = self:create(1, self.callback_sec)
    self.long = self:create(2, self.callback_long)
    self:start()
    self.long:Play()
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
    self.sec_t:Play()
  end,

  stop = function(self)
    self.sec_t:Stop()
  end,

  callback_sec = function()
    addonData.summon:tick()
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