# Final Project

## Project Summary
[Full project summary found here](./project_summary.md)

## Presentation of the Project
[Click here to see Epic Eth in action!](https://youtu.be/TTqIrQKLqos)

## Hours spent on the assignment
21 hours

## Major Challenges
This final stretch of the SoC project has been pretty rewarding, albeit a little more difficult that anticipated. The main issues that I ran across this time were with the Vitis tool in particular (the replacement for Xilinx SDK):

- There seemed to be no straightforward way to edit the block design and see the results reflected quickly in Vitis. I would generate a new bitstream after every block design edit and export a new hardware description file (XSA) as well. It seems that Vitis expects there to be relative directories from the perspective of the project workspace where are the files should live. This includes the bitstream, the XSA, the ELF file, and also the BMM file for RAM readings. These never seemed to work or have anything file that was expected to be in those directories. To circumvent this, I ended up pointing all of the expected files paths (i.e. the ones in the Xilinx > Program FPGA menu and also the paths expected in the Run Configurations menu).
- I found out quickly that if a memory buffer was not read AND write, I could easily crash the ELF file running on the SoC. I originally had the register where my seven segment would read from write-only because I expected only to update the FPGA. It turns out that if I want to reference the value I just had placed (i.e. `*data_to_draw += (24 >> ip_addr);` or `my_var = *data_to_draw`).
- Getting the ELF together as well as creating a script that can recreate the project is defintely a hassle as well.

## Files
### Files to run project without building it
- [Bitstream](./epic_eth_wrapper_final.bit)
- [ELF File](./ETH_TEST.elf)
- [BIT Download and ELF Load Script](./dwnload_and_load.tcl)

### Files to build project from scratch
- [SoCTop](./SoCTop.sv)
- [SoCTopWrapper](./SoCTopWrapper.v)
- [Seven Segment Special](./SevenSegmentController.vhd)
- [Build project Script](./soc.tcl)
- [Constraints File](./eth_ref_clk.xdc)
- [Altered Main File](./main.c)
- [Altered Server File](./echo.c)

**Detailed Description of Project Implementation:**

_Resources for this process:_

-[Nexys 4DDR Board File](./vivado-boards-master.zip)

-[MII to Reduced MII PHY](./mii_to_rmii_v2_0.zip)

_Versions of Softare:_
- Xilinx Vivado 2019.2
- Xilinx Vitis IDE v2019.2

_Helpful Links:_
- [YouTube Video to Make lwIP Echo Server on Vivado 2022.1](https://www.youtube.com/watch?v=pxbmNsWoId8) (Works in 2019.2 as well)
- [Digilent Reference for lwIP Echo Server](https://digilent.com/reference/learn/programmable-logic/tutorials/nexys-4-getting-started-with-microblaze-servers/start) (Not as helpful as the video, but has good principles)

* Build from Scratch (Based from Bryson's Guide)
    * Steps to complete:
        * This process is difficult. Hopefully, this should work on anything newer than 2019.1.
        * Be sure to extract [this depricated component](./mii_to_rmii_v2_0.zip) into the folder you are working in. Future boards don't need it, so it's obsolete, but for the Nexys4 DDR it's a must-have. You can just leave it in this folder where the rest of the files are.
        * Start by downloading the board file [here](./vivado-boards-master.zip) - you're gonna need it. In the `/vivado-boards-master/new/board_files/` folder, copy the `nexys4_ddr/` folder into your root's `/tools/Xilinx/Vivado/<version>/data/boards/board_files/` folder (if using a newer version of Vivado, the `board_files/` folder may not exist, so just put it in `boards/`).
        * Create a new Vivado project. When it gets to the setup page where you select your part, there should be in the top left something that says "`Parts|Boards`", and you want to select `Boards`. You can then search for `Nexys4 DDR` and select that board.
        * At this point, I would highly recommend that you follow step 2 at [this Digilent tutorial](https://digilent.com/reference/learn/programmable-logic/tutorials/nexys-4-ddr-getting-started-with-microblaze-servers/start#creating_new_block_design). Stop before continuing to step 3.
        * The first part of step 3 lists five IP cores to add. All of these exist in the IP catalog except for the `Ethernet PHY MII to Reduced MII`. This is what you extracted in the second step of my instructions. Here's how you integrate it:
            * In the Vivado `Flow Navigator`, click on 'IP Catalog'. Right click next to the search bar and select `Add Repository...`.
            * Navigate to the location where you extracted the `mii_to_rmii_v2` zip folder and just select the extracted folder.
            * The IP Catalog should now include a `User Repository` section. Open up folders until you get to the `Ether PHY MII to Reduced MII` module. Douple click it and then select `Add IP to Block Diagram`.
        * Now you can finish steps 3 and 4 of the tutorial, except for generating the bitstream (4.16). Once you get there, assuming you're not using SDK but rather Vitis, you'll need to change gears a bit. But before that, you need to add in my core:
            * If it didn't work already, add in my four design files linked above. they should pre-assemble themselves to have the .v file on top. 
            * Add this as a block to the diagram; connect the s_axil_outs to the AXI interconnect, the clk to the clocking wizard's `clk_out1`, and make all the other ports external. Those will have to be added to the xdc file (or you can use the linked one in the folder).
                * Be careful with the naming of the external ports, you may need to remove the `_0` at the end of each one.
        * Here, you'll want to switch over to this [YouTube video](https://youtu.be/pxbmNsWoId8?t=374), at the time the link has it cued up to start. Here you create both a platform and an application to make the project in.
        * You can follow the video exactly right up until the end. At that point, you will want to switch out the code in Vitis' `main.c` and `echo.c` with the one in mine. 
        * Build and run the project, and well done!

    * Tips and Tricks to know
        * Basing the design off of the block diagram is the best way we have gotten this to work. There are always version and board discrepancies that make online videos and tutorials frustrating mainly because of the SDRAM configuration for the ethernet controller. **HAVING THE BOARD FILE IS PARAMOUNT** since all of the parameters for a correct configuration for complex modules are already populated.
        * When creating the project in Vitis, it works mainly right out of the gate. However, there are sometimes issues with the paths for the executables. Vitis likes to look for files relative to the workspace path. This fails quite frequently! A good workaround is to use the paths that coorespond to the Vivado project (especially when it comes to the bitstream).
        * Several times we had an unknown error that only stated `Data2Mem Failed`. We thought it would break something with our MIG, but we were able to ignore the error on multiple occasions without any adverse effects. This normally pops up when trying to change the `BMM` or `MMI` file in the `Program FPGA` menu in Vitis.
        * Ultimately we have found that creating a script and or process that will run this correctly right out of the box could possible take longer than the actual development time of the project itself.