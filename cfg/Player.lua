local Player =  {
    Weapons = {},
    Coords = vector3(235.71, -411.25, 50.13),
    Health = 150,
    Cash = 20 * 1000, -- 20 thousand

    Customization = { hash = GetHashKey("mp_m_freemode_01"), variations = {}, props = {} },

    Identity = {
        First = "Jørgen",
        Last = "Olsen"
    },

    Groups = {}
}

for i = 0, 19 do
    Player.Customization.variations[i] = {0, 0}
end

return Player