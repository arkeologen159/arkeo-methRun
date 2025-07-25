## Add these to your inventory

      ["laptop4"] = {
        label = "Hacking Laptop",
        weight = 1,
        stack = false,
        close = true,
        description = "The Onion Router",
        consume = 0.1,
        client = {
            export = 'arkeo-methRun.UseMethLaptop'
        }
      },

      ["drug_phone"] = {
        label = "Drug phone",
        weight = 1,
        stack = true,
        close = true,
        description = "Looks like an old phone",
        consume = 0,
        client = { export = 'arkeo-methRun.UseDrugPhone' },
      },

      ["meth_packaged"] = {
        label = "Meth packaged",
        weight = 1000,
        stack = true,
        close = true,
        description = "Packaged meth",
      },

      ["brick_meth"] = {
        label = "Meth Brick",
        weight = 1000,
        stack = true,
        close = true,
        description = "2kg of Meth"
      },

      ["methtable"] = {
        label = "Methtable",
        weight = 2000,
        stack = false,
        close = true,
        description = "Meth Table huh",
      },

## Must have arkeo-ui started.
## Must have arkeo-hack started.
## Add this line in qbox scoreboard server config

        methRun = {
            minimumPolice = 1, -- change accordingly
            label = 'Meth Run'
        }
