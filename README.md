# sparkrun-glm52-4x-spark

### Setup

Build the docker via:

 `docker build -f Dockerfile.vllm-overlay -t vllm-zatz-dcp:probe .`

Run in sparkrun via:

`sparkrun run glm52`

The above recipe has 655K context. Alternatively, for 1M context, use the `glm52-1m.yaml` script in its place (work-in-progress).

### To-Do

There are occasional lockups that occur with this build on rare occasions (two times over the course of the past several weeks). I believe they are related to the following issue outlined [here](https://github.com/marksunner/glm52-dgx-spark-deadlock-evidence) -- the next iteration of this image will attempt to resolve this type of hang.

### Acknowledgements

Thank you to [Zatz](https://forums.developer.nvidia.com/u/zatz) and [tonyd615](https://forums.developer.nvidia.com/u/tonyd615)/[tonyd2wild](https://github.com/tonyd2wild)!
