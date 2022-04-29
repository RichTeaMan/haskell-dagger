package helloworld

import (
    "dagger.io/dagger"
    "dagger.io/dagger/core"
    "universe.dagger.io/bash"
    "universe.dagger.io/docker"
)

dagger.#Plan & {
    client: {
        filesystem: {
            "./": read: {
                contents: dagger.#FS
                exclude: [
                    "README.md",
                    "build",
                    "dev.cue"
                ]
            }
            "./build": write: contents: actions.build.contents.output
        }
    }
    actions: {
        _haskell: docker.#Build & {
            steps: [
                docker.#Pull & {source: "haskell:9.2.2" },
                docker.#Copy & {
                    contents: client.filesystem."./".read.contents
                    dest:     "."
                }
            ]
        }
        build: {
            run: bash.#Run & {
                input:   _haskell.output
                script: contents: #"""
                    cabal build
                    mkdir build
                    find . -name "helloworld" -type f -exec cp {} build/. \;
                    """#
            }

            contents: core.#Subdir & {
                input: run.output.rootfs
                path:  "/build"
            }
        }
    }
}
