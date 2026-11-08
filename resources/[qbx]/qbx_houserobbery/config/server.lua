
return {
    -- Tidak ada persyaratan polisi
    minimumPolice = 0,
    notEnoughCopsNotify = false,

    -- Cooldown global dalam detik
    -- 1800 = 30 menit
    globalCooldownSeconds = 1800,

    -- Item yang diperlukan
    requiredItems = {
        'advancedlockpick',
        'screwdriverset'
    },

    -- Reward berfokus pada barang berharga
    rewards = {
        {
            items = {
                'diamond_ring',
                'goldchain',
                'rolex',
                '10kgoldchain'
            },
            togive = {
                min = 1,
                max = 2
            },
            toget = {
                min = 1,
                max = 2
            }
        },
        {
            items = {
                'rolex',
                '10kgoldchain',
                'diamond_ring',
                'goldchain'
            },
            togive = {
                min = 2,
                max = 3
            },
            toget = {
                min = 1,
                max = 3
            }
        }
    }
}
