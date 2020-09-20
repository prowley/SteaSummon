-- periodic timers

local addonName, addonData = ...

local monitor = {
  sec_t = {},
  sec30_t = {},

  init = function(self)
    self.sec_t = self:create(1, self.callback_sec)
    self.sec30_t = self:create(30, self.callback_30)
    self:start()
    self.sec30_t:Play()
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

  callback_30 = function(self, event, ...)
    addonData.raid:fishArea()
  end
}

addonData.monitor = monitor