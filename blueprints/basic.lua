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

Handlers.add('ffp.done',
  function(msg) 
    return (msg.Action == 'Credit-Notice') and (msg['X-FFP-For'] == 'Settled' or msg['X-FFP-For'] == 'Refund') 
  end,
  function(msg)
    assert(msg.Sender == FFP.Settle, 'Only settle can send settled or refund notice')

    local settleID = msg['X-FFP-SettleID']
    if settleID and FFP.Settled[settleID] then
      if msg['X-FFP-For'] == 'Settled' then
        FFP.Settled[settleID].Status = 'Settled'
      else
        FFP.Settled[settleID].Status = 'Rejected'
      end
      FFP.Settled[settleID].SettledDate = msg['X-FFP-SettledDate']
      for _, noteID in ipairs(FFP.Settled[settleID].NoteIDs) do
        local data = Send({Target = FFP.Settle, Action = 'GetNote', NoteID = noteID}).receive().Data
        FFP.Notes[noteID] = json.decode(data)
      end
    else
      print('SettleID not found: ' .. settleID)
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