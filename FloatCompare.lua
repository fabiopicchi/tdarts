local Class = require "Class"

local FloatCompare = Class{
    precision = 0.000001
}
setfenv(1, FloatCompare)

function FloatCompare:init(precision)
    if precision then
        self.precision = precision
    end

    self.eq = function (a, b)
        return (a > b - self.precision and a < b + self.precision)
    end

    self.lt = function (a, b)
        return (a + self.precision < b - self.precision)
    end

    self.le = function (a, b)
        return self.eq(a, b) or self.lt(a, b)
    end

    self.gt = function (a, b)
        return not self.le(a, b)
    end

    self.ge = function (a, b)
        return not self.lt(a, b)
    end
end

return FloatCompare
