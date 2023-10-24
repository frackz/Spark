--- @class ped
--- @field delete? boolean
--- @field freeze? boolean
--- @field invincible? boolean
--- @field block? boolean
--- @field ragdoll? boolean
--- @field injured? boolean
--- @field canPlay? boolean
--- @field functions? table[]

--- @class job
--- @field name string
--- @field grade number
--- @field time number

--- @class defferals
--- @field defer fun()
--- @field update fun(message: string)
--- @field presentCard? fun(card: table | string, cb?: fun(data: table, rawData: string))
--- @field done fun(failureReason?: string)