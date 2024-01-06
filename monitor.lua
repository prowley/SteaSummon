-- periodic timers

local _, addonData = ...

local LONG_TIME = 30
local SHORT_TIME = 0.2
local SECOND_TIME = 1

local monitor = {
  second_t = {},
  short_t = {},
  long_t = {},
  isStarted = true,

  init = function(self)
    addonData.debug:registerCategory("monitor")
    self.short_t = self:create(SHORT_TIME, self.callback_short)
    self.long_t = self:create(LONG_TIME, self.callback_long)
    self.second_t = self:create(SECOND_TIME, self.callback_sec)
    self:start()
  end,

  create = function(_, i, callback, timerRepeat)
    local timer

    if timerRepeat == nil then
      timerRepeat = true
    end

    if timerRepeat then
      timer = C_Timer.NewTicker(i, callback)
    else
      timer = C_Timer.NewTimer(i, callback)
    end
    timer.i = i
    timer.callback = callback
    timer.timerRepeat = timerRepeat
    return timer
  end,

  start = function(self)
    if not self.isStarted then
      self.short_t = self:create(SHORT_TIME, self.callback_short)
      self.second_t = self:create(SECOND_TIME, self.callback_sec)
      self.isStarted = true
    end
  end,

  stop = function(self)
    if not self.short_t:IsCancelled() then
      self.short_t:Cancel()
    end
    if not self.second_t:IsCancelled() then
      self.second_t:Cancel()
    end
    self.isStarted = false
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
