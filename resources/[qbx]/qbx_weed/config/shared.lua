---@type WeedSharedConfig
return {
    plantsSpawnType = 'both',

    plants = {
        weed = {
            label = 'Weed Plant',
            item = 'weed',
            seedItem = 'weed_seed',
            requiresBag = true,
            harvestMin = 12,
            harvestMax = 16,
            stages = {
                'bkr_prop_weed_01_small_01c',
                'bkr_prop_weed_01_small_01b',
                'bkr_prop_weed_01_small_01a',
                'bkr_prop_weed_med_01b',
                'bkr_prop_weed_lrg_01a',
                'bkr_prop_weed_lrg_01b',
                'bkr_prop_weed_lrg_01b'
            }
        },

        meth = {
            label = 'Meth Plant',
            item = 'meth_raw',
            seedItem = 'meth_seed',
            requiresBag = true,
            harvestMin = 8,
            harvestMax = 12,
            stages = {
                'bkr_prop_weed_01_small_01c',
                'bkr_prop_weed_01_small_01b',
                'bkr_prop_weed_01_small_01a',
                'bkr_prop_weed_med_01b',
                'bkr_prop_weed_lrg_01a',
                'bkr_prop_weed_lrg_01b',
                'bkr_prop_weed_lrg_01b'
            }
        },

        cocaine = {
            label = 'Coca Plant',
            item = 'coca_leaf',
            seedItem = 'coke_seed',
            requiresBag = true,
            harvestMin = 8,
            harvestMax = 12,
            stages = {
                'bkr_prop_weed_01_small_01c',
                'bkr_prop_weed_01_small_01b',
                'bkr_prop_weed_01_small_01a',
                'bkr_prop_weed_med_01b',
                'bkr_prop_weed_lrg_01a',
                'bkr_prop_weed_lrg_01b',
                'bkr_prop_weed_lrg_01b'
            }
        }
    },

    stageProps = {
        'bkr_prop_weed_01_small_01c',
        'bkr_prop_weed_01_small_01b',
        'bkr_prop_weed_01_small_01a',
        'bkr_prop_weed_med_01b',
        'bkr_prop_weed_lrg_01a',
        'bkr_prop_weed_lrg_01b',
        'bkr_prop_weed_lrg_01b'
    },

    items = {
        nutrition = 'weed_nutrition',
        emptyBag = 'empty_weed_bag'
    }
}