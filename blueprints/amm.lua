local json = require('json')
local bint = require('.bint')(512)
local utils = require('.utils')

local poolUniswapV2 = require('.algo.uniswapv2')
local poolBigOrder = require('.algo.bigorder')

FFP = FFP or {}
-- config
FFP.Settle = FFP.Settle or 'rKpOUxssKxgfXQOpaCq22npHno6oRw66L3kZeoo_Ndk'
FFP.Publisher = FFP.Publisher or '8VzqSX_0rdAr99P3QIYd0bRG-XySTQUNFlfJf20zNEo'
FFP.SettleVersion = FFP.SettleVersion or '0.31'
FFP.MaxNotesToSettle = FFP.MaxNotesToSettle or 2
FFP.TimeoutPeriod = FFP.TimeoutPeriod or 90000

-- database or state
FFP.Pools = FFP.Pools or {}
FFP.Notes = FFP.Notes or {}
FFP.MakeTxToNoteID = FFP.MakeTxToNoteID or {}
FFP.Executing = FFP.Executing or false

-- amm pool functions
FFP.AlgoToPool = FFP.AlgoToPool or {
    UniswapV2 = poolUniswapV2,
    BigOrder = poolBigOrder
}

local function getPoolId(X, Y)
    if X > Y then
        return Y .. ':' .. X
    end
    return X .. ':' .. Y
end

local function getPool(X, Y)
    return FFP.Pools[getPoolId(X, Y)]
end

local function validateAmount(amount)
    if not amount then
        return false, 'err_no_amount'
    end
    local ok, qty = pcall(bint, amount)
    if not ok then
        return false, 'err_invalid_amount'
    end
    if not bint.__lt(0, qty) then
        return false, 'err_negative_amount'
    end
    return true, nil
end

-- tokenIn, tokenOut, amountIn, amountOut(optional)
local function validateOrderMsg(msg)
    local Pool = getPool(msg.TokenIn, msg.TokenOut)
    if not Pool then
        return false, 'err_pool_not_found'
    end
    
    local ok, err = validateAmount(msg.AmountIn)
    if not ok then
        return false, 'err_invalid_amount_in'
    end
    
    if msg.AmountOut then
        local ok, err = validateAmount(msg.AmountOut)
        if not ok then
            return false, 'err_invalid_amount_out'
        end
    end

    return true, nil
end

local function validateAmountOut(pool, tokenIn, amountIn, tokenOut, expectedAmountOut)
    local tokenOut_, amountOut = pool:getAmountOut(tokenIn, amountIn)
    if not amountOut or amountOut == '0' then
        return false, 'err_no_amount_out'
    end
    if tokenOut_ ~= tokenOut then
        return false, 'err_invalid_token_out'
    end
    if expectedAmountOut then
        if utils.lt(amountOut, expectedAmountOut) then
            return false, 'err_amount_out_too_small'
        end
    end 
    return true, nil
end

Handlers.add('ffp.withdraw', 'FFP.Withdraw',
  function(msg)
    assert(msg.From == Owner or msg.From == ao.id, 'Only owner can withdraw')
    assert(type(msg.Token) == 'string', 'Token is required')
    assert(type(msg.Amount) == 'string', 'Amount is required')
    assert(bint.__lt(0, bint(msg.Amount)), 'Amount must be greater than 0')
    
    Send({ 
      Target = msg.Token, 
      Action = 'Transfer', 
      Quantity = msg.Amount, 
      Recipient = Owner
    })
  end
)

Handlers.add('ffp.pools', 'FFP.GetPools', 
    function(msg)
        local pools = {}
        for poolId, pool in pairs(FFP.Pools) do
            pools[poolId] = pool:info()
        end
        msg.reply({Data = json.encode(pools)})
    end
)

Handlers.add('ffp.addPool', 'FFP.AddPool', 
    function(msg)
        assert(msg.From == Owner or msg.From == ao.id, 'Only owner can add pool')
        assert(type(msg.X) == 'string', 'X is required')
        assert(type(msg.Y) == 'string', 'Y is required')
        assert(msg.X < msg.Y, 'X must be less than Y')
        assert(type(msg.Algo) == 'string', 'Algo is required')
        assert(type(msg.Data) == 'string', 'Params is required')

        local poolId = getPoolId(msg.X, msg.Y)
        if FFP.Pools[poolId] then
            msg.reply({Error = 'Pool already exists'})
            return
        end

        local P = FFP.AlgoToPool[msg.Algo]
        if not P then
            msg.reply({Error = 'Unsupported amm algo'})
            return
        end
        
        local pool = P.new(msg.X, msg.Y, json.decode(msg.Data))
        if not pool then
            msg.reply({Error = 'Invalid pool params'})
            return
        end

        FFP.Pools[poolId] = pool
        msg.reply({Action = 'PoolAdded-Notice', Pool = poolId})
        Send({Target = FFP.Publisher, Action = 'PoolAdded-Notice', Creator = ao.id, Data = json.encode(pool)})
    end
)

Handlers.add('ffp.updateLiquidity', 'FFP.UpdateLiquidity', 
    function(msg)
        assert(msg.From == Owner or msg.From == ao.id, 'Only owner can update liquidity')
        assert(type(msg.Y) == 'string', 'Y is required')
        assert(msg.X < msg.Y, 'X must be less than Y')
        assert(type(msg.Data) == 'string', 'Params is required')
        
        local pool = getPool(msg.X, msg.Y)
        if not pool then
            msg.reply({Error = 'Pool not found'})
            return
        end
        
        local ok = pool:updateLiquidity(json.decode(msg.Data))
        if not ok then
            msg.reply({Error = 'Invalid updateLiquidity params'})
            return
        end

        msg.reply({Action = 'LiquidityUpdated-Notice', Data = json.encode(pool)})
    end
)

Handlers.add('ffp.getAmountOut', 'FFP.GetAmountOut',
  function(msg)
    if FFP.Executing then
        msg.reply({Error = 'err_executing'})
        return
    end
    
    local ok, err = validateOrderMsg(msg)
    if not ok then
        msg.reply({Error = err})
        return
    end

    local pool = getPool(msg.TokenIn, msg.TokenOut)
    local tokenOut, amountOut = pool:getAmountOut(msg.TokenIn, msg.AmountIn)
    if not amountOut or amountOut == '0' then
        msg.reply({Error = 'err_no_amount_out'})
        return
    end
    msg.reply({
        TokenIn = msg.TokenIn,
        AmountIn = msg.AmountIn,
        TokenOut = tokenOut,
        AmountOut = tostring(amountOut)
    })
  end
)

Handlers.add('ffp.makeOrder', 'FFP.MakeOrder',
  function(msg)
    if FFP.Executing then
        msg.reply({Error = 'err_executing'})
        return
    end
    
    local ok, err = validateOrderMsg(msg)
    if not ok then
        msg.reply({Error = err})
        return
    end

    local pool = getPool(msg.TokenIn, msg.TokenOut)
    local tokenOut, amountOut = pool:getAmountOut(msg.TokenIn, msg.AmountIn)
    if not amountOut or amountOut == '0' then
        msg.reply({Error = 'err_no_amount_out'})
        return
    end

    if msg.AmountOut then
        local ok, err = validateAmountOut(pool, msg.TokenIn, msg.AmountIn, msg.TokenOut, msg.AmountOut)
        if not ok then
            msg.reply({Error = err})
            return
        end
        amountOut = msg.AmountOut
    end

    -- 90 seconds
    local expireDate = msg.Timestamp + FFP.TimeoutPeriod

    local res = Send({
        Target = FFP.Settle,
        Action = 'CreateNote',
        AssetID = msg.TokenOut,
        Amount = tostring(amountOut),
        HolderAssetID = msg.TokenIn,
        HolderAmount = msg.AmountIn,
        IssueDate = tostring(msg.Timestamp),
        ExpireDate = tostring(expireDate),
        Version = FFP.SettleVersion
    }).receive()
    local noteID = res.NoteID
    local note = json.decode(res.Data)
    note.MakeTx = msg.Id
    FFP.Notes[noteID] = note
    FFP.MakeTxToNoteID[msg.Id] = noteID
    -- remove expired notes in Notes
    for noteID, note in pairs(FFP.Notes) do
        if note.Status == 'Open' and note.ExpireDate and note.ExpireDate < msg.Timestamp then
            FFP.Notes[noteID] = nil
            FFP.MakeTxToNoteID[note.MakeTx] = nil
        end
    end

    msg.reply({
        Action = 'OrderMade-Notice',
        NoteID = noteID,
        Data = json.encode(note)
    })
  end
)

Handlers.add('ffp.getNote', 'FFP.GetNote', 
    function(msg)
        assert(type(msg.MakeTx) == 'string', 'MakeTx is required')
        local note = FFP.Notes[FFP.MakeTxToNoteID[msg.MakeTx]] or ''
        msg.reply({NoteID=note.NoteID, Data = json.encode(note)})
    end
)

Handlers.add('ffp.execute', 'Execute',
  function(msg)
    assert(msg.From == FFP.Settle, 'Only settle can start exectue')
    assert(type(msg.NoteID) == 'string', 'NoteID is required')
    assert(type(msg.SettleID) == 'string', 'SettleID is required')

    if FFP.Executing then
        msg.reply({Action= 'Reject', Error = 'err_executing', SettleID = msg.SettleID, NoteID = msg.NoteID})
        return
    end

    local note = FFP.Notes[msg.NoteID]
    if not note then
        msg.reply({Action= 'Reject', Error = 'err_not_found', SettleID = msg.SettleID, NoteID = msg.NoteID})
        return
    end
    if note.Status ~= 'Open' then
        msg.reply({Action= 'Reject', Error = 'err_not_open', SettleID = msg.SettleID, NoteID = msg.NoteID})
        return
    end
    if note.Issuer ~= ao.id then
        msg.reply({Action = 'Reject', Error = 'err_invalid_issuer', SettleID = msg.SettleID, NoteID = msg.NoteID})
        return
    end
    if note.ExpireDate and note.ExpireDate < msg.Timestamp then
        FFP.Notes[note.NoteID] = nil
        FFP.MakeTxToNoteID[note.MakeTx] = nil
        msg.reply({Action= 'Reject', Error = 'err_expired', SettleID = msg.SettleID, NoteID = msg.NoteID})
        return
    end

    local pool = getPool(note.HolderAssetID, note.AssetID)
    local ok, err = validateAmountOut(pool, note.HolderAssetID, note.HolderAmount, note.AssetID, note.Amount)
    if not ok then
        msg.reply({Action= 'Reject', Error = err, SettleID = msg.SettleID, NoteID = msg.NoteID})
        return
    end

    msg.reply({Action = 'ExecuteStarted', SettleID = msg.SettleID, NoteID = msg.NoteID})

    FFP.Executing = true
    note.Status = 'Executing'

    Send({Target = note.AssetID, Action = 'Transfer', Quantity = note.Amount, Recipient = FFP.Settle, 
      ['X-FFP-SettleID'] = msg.SettleID, 
      ['X-FFP-NoteID'] = msg.NoteID,
      ['X-FFP-For'] = 'Execute'
    })
  end
)

Handlers.add('ffp.done',
    function(msg) return (msg.Action == 'Credit-Notice') and (msg['X-FFP-For'] == 'Settled' or msg['X-FFP-For'] == 'Refund') end,
    function(msg)
        assert(msg.Sender == FFP.Settle, 'Only settle can send settled or refund notice')
        
        local noteID = msg['X-FFP-NoteID']
        local note = FFP.Notes[noteID]
        if not note then
            print('no note found when settled: ' .. noteID)
            return 
        end

        local pool = getPool(note.HolderAssetID, note.AssetID)
        if msg['X-FFP-For'] == 'Settled' then
            pool:updateAfterSwap(note.HolderAssetID, note.HolderAmount, note.AssetID, note.Amount)
        end
        FFP.Notes[noteID].Status = msg['X-FFP-For']
        FFP.Executing = false

        FFP.Notes[noteID] = json.decode(Send({Target = FFP.Settle, Action = 'GetNote', NoteID = noteID}).receive().Data)
        
    end
)