local json = require('json')
local bint = require('.bint')(512)
local utils = require('.utils')

FFP = FFP or {}
-- config
FFP.Settle = FFP.Settle or 'rKpOUxssKxgfXQOpaCq22npHno6oRw66L3kZeoo_Ndk'
FFP.SettleVersion = FFP.SettleVersion or '0.31'
FFP.MaxNotesToSettle = FFP.MaxNotesToSettle or 2

-- database
FFP.Notes = FFP.Notes or {}
FFP.Settled = FFP.Settled or {}
FFP.MakeTxToNoteID = FFP.MakeTxToNoteID or {}

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

Handlers.add('ffp.takeOrder', 'FFP.TakeOrder',
  function(msg)
    assert(msg.From == Owner or msg.From == ao.id, 'Only owner can take order')
    
    local noteIDs = utils.getNoteIDs(msg.Data)
    if noteIDs == nil then
      msg.reply({Error = 'err_invalid_note_ids', ['X-FFP-TakeOrderID'] = msg.Id})
      return
    end
    
    if #noteIDs > FFP.MaxNotesToSettle then
      msg.reply({Error = 'err_too_many_orders', ['X-FFP-TakeOrderID'] = msg.Id})
      return
    end

    local notes = {}
    for _, noteID in ipairs(noteIDs) do
      local data = Send({Target = FFP.Settle, Action = 'GetNote', NoteID = noteID}).receive().Data
      if data == '' then
        msg.reply({Error = 'err_not_found', ['X-FFP-TakeOrderID'] = msg.Id})
        return
      end
      local note = json.decode(data)
      if note.Status ~= 'Open' then
        msg.reply({Error = 'err_not_open', ['X-FFP-TakeOrderID'] = msg.Id, Data = noteID})
        return
      end
      if note.Issuer == ao.id then
        msg.reply({Error = 'err_cannot_take_self_order', ['X-FFP-TakeOrderID'] = msg.Id, Data = noteID})
        return
      end
      if note.ExpireDate and note.ExpireDate < msg.Timestamp then
        msg.reply({Error = 'err_expired', ['X-FFP-TakeOrderID'] = msg.Id, Data = noteID})
        return
      end
      table.insert(notes, note)
    end
    
    local si, so = utils.SettlerIO(notes)
    -- todo: make sure we have enough balance

    -- start a settle session
    local res = Send({Target = FFP.Settle, Action = 'StartSettle', Version = FFP.SettleVersion, Data = json.encode(noteIDs)}).receive()
    if res.Error then
      msg.reply({Error = res.Error, ['X-FFP-TakeOrderID'] = msg.Id})     
      return
    end
   
    local settleID = res.SettleID
    FFP.Settled[settleID] = {SettleID = settleID, NoteIDs = noteIDs, Status = 'Pending'}
   
    if next(so) == nil then
      print('TakeOrder: Settler no need to transfer to settle process')
      Send({Target = FFP.Settle, Action = 'Settle', Version = FFP.SettleVersion, SettleID = settleID})
      msg.reply({Action = 'TakeOrder-Settle-Sent-Notice', SettleID = settleID})
      return
    end

    for k, v in pairs(so) do
      local amount = utils.subtract('0', v)
      Send({Target = k, Action = 'Transfer', Quantity = amount,  Recipient = FFP.Settle, 
        ['X-FFP-SettleID'] = settleID, 
        ['X-FFP-For'] = 'Settle'
      })
    end
    msg.reply({Action = 'TakeOrder-Settle-Sent-Notice', SettleID = settleID})
  end
)

Handlers.add('ffp.makeOrder', 'FFP.MakeOrder',
  function(msg)
    assert(msg.From == Owner or msg.From == ao.id, 'Only owner can make order')
    assert(type(msg.AssetID) == 'string', 'AssetID is required')
    assert(type(msg.Amount) == 'string', 'Amount is required')
    assert(bint.__lt(0, bint(msg.Amount)), 'Amount must be greater than 0')
    assert(type(msg.HolderAssetID) == 'string', 'HolderAssetID is required')
    assert(type(msg.HolderAmount) == 'string', 'HolderAmount is required')
    assert(bint.__lt(0, bint(msg.HolderAmount)), 'HolderAmount must be greater than 0')

    local expireDate = msg.ExpireDate
    if expireDate and tonumber(expireDate) < msg.Timestamp then
      msg.reply({Error = 'err_invalid_expire_date', ['X-FFP-MakeOrderID'] = msg.Id})
      return
    end
    if not expireDate then expireDate = '' end

    local res = Send({
      Target = FFP.Settle,
      Action = 'CreateNote',
      AssetID = msg.AssetID,
      Amount = msg.Amount,
      HolderAssetID = msg.HolderAssetID,
      HolderAmount = msg.HolderAmount,
      IssueDate = tostring(msg.Timestamp),
      ExpireDate = expireDate,
      Version = FFP.SettleVersion
    }).receive()
    local noteID = res.NoteID
    local note = json.decode(res.Data)
    FFP.Notes[noteID] = note
    FFP.MakeTxToNoteID[msg.Id] = noteID
    msg.reply({Action = 'OrderMade-Notice', NoteID = note.NoteID, Data = json.encode(note)})
  end
)

Handlers.add('ffp.execute', 'Execute',
  function(msg)
    assert(msg.From == FFP.Settle, 'Only settle can start exectue')
    assert(type(msg.NoteID) == 'string', 'NoteID is required')
    assert(type(msg.SettleID) == 'string', 'SettleID is required')

    local note = FFP.Notes[msg.NoteID]
    if not note then
      msg.reply({Action = 'Reject', Error = 'err_not_found', SettleID = msg.SettleID, NoteID = msg.NoteID})
      return
    end
    if note.Status ~= 'Open' then
      msg.reply({Action = 'Reject', Error = 'err_not_open', SettleID = msg.SettleID, NoteID = msg.NoteID})
      return
    end
    if note.Issuer ~= ao.id then
      msg.reply({Action = 'Reject', Error = 'err_invalid_issuer', SettleID = msg.SettleID, NoteID = msg.NoteID})
      return
    end
    
    msg.reply({Action = 'StartExecute', SettleID = msg.SettleID, NoteID = msg.NoteID})

    FFP.Notes[msg.NoteID].Status = 'Executed'
    Send({Target = note.AssetID, Action = 'Transfer', Quantity = note.Amount, Recipient = FFP.Settle, 
      ['X-FFP-SettleID'] = msg.SettleID, 
      ['X-FFP-NoteID'] = msg.NoteID,
      ['X-FFP-For'] = 'Execute'
    })
  end
)

Handlers.add('ffp.done',
  function(msg) 
    return (msg.Action == 'Credit-Notice') and (msg['X-FFP-For'] == 'Settled' or msg['X-FFP-For'] == 'Refund') 
  end,
  function(msg)
    assert(msg.Sender == FFP.Settle, 'Only settle can send settled or refund notice')

    local noteID = msg['X-FFP-NoteID']
    local settleID = msg['X-FFP-SettleID']
    
    if noteID and FFP.Notes[noteID] then
      if msg['X-FFP-For'] == 'Settled' then
        FFP.Notes[noteID].Status = 'Settled'
      else
        FFP.Notes[noteID].Status = 'Open'
      end
      return
    end

    if settleID and Settled[settleID] then
      if msg['X-FFP-For'] == 'Settled' then
        Settled[settleID].Status = 'Settled'
      else
        Settled[settleID].Status = 'Rejected'
      end
      Settled[settleID].SettledDate = msg['X-FFP-SettledDate']
      for _, noteID in ipairs(Settled[settleID].NoteIDs) do
        local data = Send({Target = FFP.Settle, Action = 'GetNote', NoteID = noteID}).receive().Data
        FFP.Notes[noteID] = json.decode(data)
      end
    end
  end
)

Handlers.add('ffp.cancelOrder', 'FFP.CancelOrder',
  function(msg)
    assert(msg.From == Owner or msg.From == ao.id, 'Only owner can cancel order')
    assert(type(msg.NoteID) == 'string', 'NoteID is required')

    local noteID = msg.NoteID
    local note = FFP.Notes[noteID]
    
    if not note then
      msg.reply({Error = 'err_not_found', ['X-FFP-CancelOrderID'] = msg.Id})
      return
    end
    if note.Issuer ~= ao.id then
      msg.reply({Error = 'err_invalid_user', ['X-FFP-CancelOrderID'] = msg.Id})
      return
    end
    if note.Status ~= 'Open' then
      msg.reply({Error = 'err_not_open', ['X-FFP-CancelOrderID'] = msg.Id})
      return
    end
    
    local res = Send({Target = FFP.Settle, Action = 'Cancel', Version = FFP.SettleVersion, NoteID = noteID}).receive()
    if res.Error then
      msg.reply({Error = res.Error, ['X-FFP-CancelOrderID'] = msg.Id})
      return
    end
    FFP.Notes[noteID] = json.decode(res.Data)
    msg.reply({Action = 'OrderCancelled-Notice', NoteID = noteID})
  end
)

Handlers.add('ffp.getNote', 'FFP.GetNote', 
    function(msg)
        assert(type(msg.MakeTx) == 'string', 'MakeTx is required')
        local noteID = FFP.MakeTxToNoteID[msg.MakeTx]
        if noteID and FFP.Notes[noteID] then
          msg.reply({NoteID=noteID, Data = json.encode(FFP.Notes[noteID])})
        else
          msg.reply({Error = 'err_not_found'})
        end
    end
)

Handlers.add('ffp.getOrders', 'FFP.GetOrders',
  function (msg)
    msg.reply({Action = 'GetOrders-Notice', Data = json.encode(FFP.Notes)})
  end
)

Handlers.add('ffp.getSettled', 'FFP.GetSettled',
  function (msg)
    msg.reply({Action = 'GetSettled-Notice', Data = json.encode(FFP.Settled)})
  end
)