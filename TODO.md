- [ ] link to a template repo to showcase forge-deplpoy features
- [ ] read deployments on start
- [ ] instead of saving all info in the run() function returns values, we can simply return a filepath that will have all the info in it. This will require us to write at execution time though (see next TODO). We can do that at the complete end
- [ ] request a feature in forge to let execution to know whether the script has been executed with --broadcast so as to not waste writing to file when the broadcast will not actually happen
- [ ] allow user to provide their own template to generate deploy functions
- [ ] should we remove proxy management from the core and ask use to install a library that contains a template for it
    This will require a system to pick template automatically or via configuraiton