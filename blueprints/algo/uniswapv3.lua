local bint = require('.bint')(1024)
local utils = require('.utils')

local Pool = {}
Pool.__index = Pool 

local function getAmountOut(amountIn, reserveIn, reserveOut, fee)
    local amountInWithFee = bint.__mul(amountIn, bint.__sub(10000, fee))
    local numerator = bint.__mul(amountInWithFee, reserveOut)
    local denominator = bint.__add(bint.__mul(10000, reserveIn), amountInWithFee)
    return bint.udiv(numerator, denominator)
end

local function validateInitParams(params)
    if not params then
        return false
    end
    return params.high and params.low and params.current and utils.validateAmount(params.liquidity) and utils.validateAmount(params.fee)
end

local function validateUpdateLiquidityParams(params)
    if not params then
        return false
    end
    return params.high and params.low and params.current and utils.validateAmount(params.liquidity)
end

function Pool.new(params)
    if not validateInitParams(params) then
        return nil
    end
    local self = setmetatable({}, Pool)
    self.algo = 'UniswapV3'
    self.sqrtHigh = math.sqrt(params.high)
    self.sqrtLow = math.sqrt(params.low)
    self.sqrtCurrent = math.sqrt(params.current)
    self.liquidity = params.liquidity
    self.fee = params.fee

    if self.sqrtHigh >= self.sqrtCurrent and self.sqrtLow <= self.sqrtCurrent and self.sqrtHigh > self.sqrtLow then
        return self
    end
    return nil
end

function Pool:balances()
    local bx = (1/self.sqrtCurrent - 1/self.sqrtHigh) * self.liquidity + 1
    local by = (self.sqrtCurrent - self.sqrtLow) * self.liquidity + 1
    local balance = {
        [self.x] = bx,
        [self.y] = by
    }
    return balance
end

function Pool:Info()
    local info = {
        x = self.x,
        y = self.y,
        sqrtHigh = self.sqrtHigh,
        sqrtLow = self.sqrtLow,
        sqrtCurrent = self.sqrtCurrent,
        liquidity = self.liquidity,
        fee = self.fee,
        algo = self.algo,   
        balances = self:balances()
    }
    return info
end

function Pool:updateLiquidity(params)
    if not validateUpdateLiquidityParams(params) then
        return false
    end
    self.sqrtHigh = math.sqrt(params.high)
    self.sqrtLow = math.sqrt(params.low)
    self.sqrtCurrent = math.sqrt(params.current)
    self.liquidity = params.liquidity
    if self.sqrtHigh >= self.sqrtCurrent and self.sqrtLow <= self.sqrtCurrent and self.sqrtHigh > self.sqrtLow then
        return true
    end
    return false
end

function Pool:updateAfterSwap(tokenIn, amountIn, tokenOut, amountOut)
    if tokenIn == self.x then
        self.sqrtCurrent = self.liquidity / (amountInWithFee + 1/self.sqrtCurrent)
    else
        self.sqrtCurrent = amountInWithFee / self.liquidity + self.sqrtCurrent
    end
end

function Pool:getAmountOut(tokenIn, amountIn)
    local amountInWithFee = bint.__mul(amountIn, bint.__sub(10000, self.fee))
    if tokenIn == self.x then
        local sqrtCurrentNew = self.liquidity / (amountInWithFee + 1/self.sqrtCurrent)
        if sqrtCurrentNew < self.sqrtLow then
            return self.y, nil
        end
        local amountOut = self.liquidity * (self.sqrtCurrent - sqrtCurrentNew)
        return self.y, tostring(amountOut)
    end
    if tokenIn == self.y then
        local sqrtCurrentNew = amountInWithFee / self.liquidity + self.sqrtCurrent
        if sqrtCurrentNew > self.sqrtHigh then
            return self.x, nil
        end
        local amountOut = self.liquidity * (1/self.sqrtCurrent - 1/sqrtCurrentNew)
        return self.x, tostring(amountOut)
    end
    return nil, nil
end

return Pool
