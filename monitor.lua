-- periodic timers

local addonName, addonData = ...

local monitor = {
  sec_t = {},
  long_t = {},

  init = function(self)
    addonData.debug:registerCategory("monitor")
    self.sec_t = self:create(1, self.callback_sec)
    self.long = self:create(5, self.callback_long)
    self:start()
    self.long:Play()
  end,

  create = function(self, i, callback)
    local timer
    timer = frame:CreateAnimationGroup()
    timer.anim = timer:CreateAnimation()
    timer.anim:SetDuration(i)
    timer:SetLooping("REPEAT")
    timer:SetScript("OnLoop", callback)
    return timer
  end,

  start = function(self)
    self.sec_t:Play()
  end,

  stop = function(self)
    self.sec_t:Stop()
  end,

  callback_sec = function(self, event, ...)
    addonData.summon:tick()
  end,

  callback_long = function(self, event, ...)
    addonData.raid:fishArea()
  end,

  callback = function(self, event, ...)
    -- this is a generic debug monitor of events that are under observation
    db("monitor", event, ...)
  end,
}

addonData.monitor = monitor