# Spiker Packages

Public release repository for Spiker setup packages.

The private `hasan-ozdemir/spiker` repository builds `spiker-setup.exe` and dispatches this repository's `publish-spiker-setup.yml` workflow. That workflow downloads the private `spiker-setup` artifact with the `SPIKER_SOURCE_TOKEN` secret and publishes it to GitHub Releases.
