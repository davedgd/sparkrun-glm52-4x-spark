# sparkrun-glm52-4x-spark

Run GLM-5.2 on a four-node DGX Spark cluster with a 1-million-token context window and optional vision support.

## Prerequisites

- Install and configure [sparkrun](https://sparkrun.dev) on the head node, including running the setup wizard (for example, `uvx sparkrun setup`).
- Ensure [Docker](https://docs.docker.com/engine/install/ubuntu/) is installed on all four nodes.
- If using vision, ensure the [Hugging Face CLI](https://huggingface.co/docs/huggingface_hub/main/en/guides/cli#standalone-installer-recommended) is installed on all four nodes (for example, `curl -LsSf https://hf.co/cli/install.sh | bash`).
- Clone this repo on the head Spark node and enter its directory:

```bash
git clone \
  https://github.com/davedgd/sparkrun-glm52-4x-spark.git \
  "$HOME/sparkrun-glm52-4x-spark"

cd "$HOME/sparkrun-glm52-4x-spark"
```

## Docker Image

On the head Spark node, create a sparkrun-compatible derivative of [ciprianveg's GLM-5.2 Docker image](https://github.com/ciprianveg/gb10-vllm/tree/main/glm-5.2) with its default entrypoint and command removed:

```bash
docker build --platform=linux/arm64 \
  -t gb10-glm52:v18.1-vision-sparkrun - <<'EOF'
FROM ghcr.io/ciprianveg/gb10-glm-5.2:v18.1-vision
ENTRYPOINT []
CMD []
EOF
```

## Running GLM-5.2 at 1M Context

Run the default text-only recipe on the head Spark node:

```bash
sparkrun run glm52
```

## Vision Alternative

The default recipe (`glm52.yaml`) supports a 1M context window but does not include vision. To include the vision tower from [baseten/GLM-5.2-Vision-NVFP4](https://huggingface.co/baseten/GLM-5.2-Vision-NVFP4) (see this [blog post](https://www.baseten.co/blog/glm-52-with-vision/) for details), prepare the composite model as follows.

> **Important:** The completed composite model must be available at the same Hugging Face cache location on all four DGX Spark nodes. You can either perform the following preparation step on every node or prepare the model once and distribute it to the other nodes manually.

To prepare the composite model independently on each node, run the following commands on all four nodes. The preparation script is adapted from [ciprianveg/gb10-glm-5.2](https://github.com/ciprianveg/gb10-glm-5.2/blob/c3980ec81efacac619237a8bcaf110a8d2890901/v18-vision/README-v18.1.md):

```bash
REPO_DIR="$HOME/sparkrun-glm52-4x-spark"

[ -d "$REPO_DIR/.git" ] ||
  git clone https://github.com/davedgd/sparkrun-glm52-4x-spark.git "$REPO_DIR"

cd "$REPO_DIR"
chmod +x prep-glm52-vision-model.sh
./prep-glm52-vision-model.sh
```

By default, the preparation script writes the composite model to: `$HOME/.cache/huggingface/glm52-quanttrio-vision`. If `HF_HOME` is set, the output is instead written to `$HF_HOME/glm52-quanttrio-vision`. The same location must be used on every node.

Run the vision recipe with sparkrun on the head Spark node:

```bash
sparkrun run glm52-vision
```

## Acknowledgements

Thank you to [ciprianveg](https://forums.developer.nvidia.com/u/ciprianveg), [CosmicRaisins](https://github.com/CosmicRaisins), [Zatz](https://forums.developer.nvidia.com/u/zatz), and [tonyd615](https://forums.developer.nvidia.com/u/tonyd615)!
