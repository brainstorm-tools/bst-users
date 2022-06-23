#  Brainstorm-Users
As the active [Brainstorm's user community](https://neuroimage.usc.edu/brainstorm/Community) is growing in size and diversity, we decided to launch this repository to **data**, **processes** and **scripts** shared by [Brainstorm](https://neuroimage.usc.edu/brainstorm/Introduction) users, and make them available to all users.


## Creating you own processes
If you are interested in running your own code from the Brainstorm interface and benefit from the powerful [database](https://neuroimage.usc.edu/brainstorm/Tutorials/Database) and [visualization systems](https://neuroimage.usc.edu/brainstorm/Screenshots), the best option is probably for you to [create your own Brainstorm processes](https://neuroimage.usc.edu/brainstorm/Tutorials/TutUserProcess). It can take some time to get used to this logic but it is time well invested: you will be able to exchange code easily with your collaborators and the methods you develop could immediately reach thousands of users. Once your process are stable and address a recurrent need for other Brainstorm users, we can integrate them in the [main Brainstorm distribution](https://github.com/brainstorm-tools/brainstorm3) and maintain the code for you to ensure it stays compatible with the future releases of the software.

#### :brain: Check this page on <a href="https://neuroimage.usc.edu/brainstorm/Tutorials/TutUserProcess"> How to write your own Brainstorm process</a>

### Examples
The easiest way to write your own process function is to start working from an existing example. As such, we provide three sample processes that can help you for specific tasks:
 * Generate a head model / leadfield matrix: [`process_headmodel_test.m`](/processes/examples/process_headmodel_test.m)
 * Generate an inverse model / source matrix: [`process_beamformer_test.m`](/processes/examples/process_beamformer_test.m)
 * Load all the trials in input at once and process them: [`process_example_customavg.m`](/processes/examples/process_example_customavg.m)

## Using processes
To use processes from other users, copy only the `process_*.m` functions to the [`process` folder in the user directory](https://neuroimage.usc.edu/brainstorm/Tutorials/TutUserProcess#Process_folders), typically:

| **Windows** |  `C:\Users\username\.brainstorm\process\` |
|--- |--- |
| **Linux** | `/home/username/.brainstorm/process/` |
| **MacOS** | `/Users/username/.brainstorm/process/` |

## Submit
The main way to can send your script and process in Submit a process or script through a GitHub [Pull-Request](https://docs.github.com/en/pull-requests), see the [CONTRIBUTING.md](CONTRIBUTING.md) document for further details. Besides the `process_*.m` file, provide a `README.md` file describing what the process do, and a `screenshot.png` image file showing the GUI of the process.

:bulb: If you want to contribute, but you're not familiar with GitHub, share with us your contribution in the [Brainstorm Forum](https://neuroimage.usc.edu/forums/).

## Resources
* How to write your own process  
  https://neuroimage.usc.edu/brainstorm/Tutorials/TutUserProcess

* Scripting (in Brainstorm)  
  https://neuroimage.usc.edu/brainstorm/Tutorials/Scripting

* Brainstorm's Database Structure  
  https://neuroimage.usc.edu/brainstorm/Tutorials/Database

* Brainstorm Forum  
  https://neuroimage.usc.edu/forums/

* Brainstorm source code  
  https://github.com/brainstorm-tools/brainstorm3
