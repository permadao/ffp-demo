local bint = require('.bint')(1024)

local Pool = {}
Pool.__index = Pool 

local utils = {
    add = function (a,b) 
      return tostring(bint(a) + bint(b))
    end,
    subtract = function (a,b)
      return tostring(bint(a) - bint(b))
    end,
    mul = function(a, b)
        return tostring(bint.__mul(bint(a), bint(b)))
    end,
    div = function(a, b)
        return tostring(bint.udiv(bint(a), bint(b)))
    end,
    lt = function (a, b)
        return bint.__lt(bint(a), bint(b))
    end
}

local function validateAmount(amount)
    if not amount then
        return false, 'err_no_amount'
    end
    local ok, qty = pcall(bint, amount)
    if not ok then
        return false, 'err_invalid_amount'
    end
    if not utils.lt(0, qty) then
        return false, 'err_negative_amount'
    end
    return true, nil
end

local function validateInitParams(params)
    if not params then
        return false
    end
    return params.tokenOut and params.tokenIn and validateAmount(params.amountOut) and validateAmount(params.amountIn)
end

function Pool.new(x, y, params)
    if not validateInitParams(params) then
        return nil
    end
    local self = setmetatable({}, Pool)
    self.algo = 'BigOrder'
    self.x = x
    self.y = y
    self.tokenIn = params.tokenIn
    self.tokenOut = params.tokenOut
    self.amountOut = params.amountOut
    self.amountIn = params.amountIn
    self.balanceTokenIn = '0'
    self.balanceTokenOut = self.amountOut
    return self
end

function Pool:balances()
    local balance = {
        [self.tokenOut] = self.balanceTokenOut,
        [self.tokenIn] = self.balanceTokenIn
    }
    return balance
end

function Pool:info()
    local info = {
        x = self.x,
        y = self.y,
        algo = self.algo,
        tokenIn = self.tokenIn,
        tokenOut = self.tokenOut,
        amountOut = self.amountOut,
        amountIn = self.amountIn,
        balances = self:balances()
    }
    return info
end

function Pool:updateLiquidity(params)
    return false
end

function Pool:updateAfterSwap(tokenIn, amountIn, tokenOut, amountOut)
   self.balanceTokenIn = utils.add(self.balanceTokenIn, amountIn)
   self.balanceTokenOut = utils.subtract(self.balanceTokenOut, amountOut)
end

function Pool:getAmountOut(tokenIn, amountIn)
    if tokenIn == self.tokenIn then
        local amountOut = utils.div(utils.mul(amountIn, self.amountOut), self.amountIn)
        if utils.lt(amountOut, self.balanceTokenOut) then
            return self.tokenOut, tostring(amountOut)
        end
    end

    return nil, nil
end

return Pool
