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

local function getAmountOut(amountIn, reserveIn, reserveOut, fee)
    local amountInWithFee = utils.mul(amountIn, utils.subtract(10000, fee))
    local numerator = utils.mul(amountInWithFee, reserveOut)
    local denominator = utils.add(utils.mul(10000, reserveIn), amountInWithFee)
    return utils.div(numerator, denominator)
end

local function validateInitParams(params)
    if not params then
        return false
    end
    return validateAmount(params.fee) and validateAmount(params.px) and validateAmount(params.py)
end

local function validateUpdateLiquidityParams(params)
    if not params then
        return false
    end
    return validateAmount(params.px) and validateAmount(params.py)
end

function Pool.new(x, y, params)
    if not validateInitParams(params) then
        return nil
    end
    local self = setmetatable({}, Pool)
    self.algo = 'UniswapV2'
    self.x = x
    self.y = y
    self.fee = params.fee
    self.px = params.px
    self.py = params.py
    return self
end

function Pool:balances()
    local balance = {
        [self.x] = self.px,
        [self.y] = self.py
    }
    return balance
end

function Pool:info()
    local info = {
        x = self.x,
        y = self.y,
        fee = self.fee,
        algo = self.algo,
        px = self.px,
        py = self.py,
        balances = self:balances()
    }
    return info
end

function Pool:updateLiquidity(params)
    if not validateUpdateLiquidityParams(params) then
        return false
    end
    self.px = params.px
    self.py = params.py
    return true
end

function Pool:updateAfterSwap(tokenIn, amountIn, tokenOut, amountOut)
    if tokenIn == self.x then
        self.px = utils.add(self.px, amountIn)
        self.py = utils.subtract(self.py, amountOut)
    else
        self.py = utils.add(self.py, amountIn)
        self.px = utils.subtract(self.px, amountOut)
    end
end

function Pool:getAmountOut(tokenIn, amountIn)
    local tokenOut = self.y
    local reserveIn = bint(self.px)
    local reserveOut = bint(self.py)
    if tokenIn == self.y then
        reserveIn, reserveOut = reserveOut, reserveIn
        tokenOut = self.x
    end
    local amountOut = getAmountOut(bint(amountIn), reserveIn, reserveOut, bint(self.fee))
    return tokenOut, tostring(amountOut)
end

return Pool
