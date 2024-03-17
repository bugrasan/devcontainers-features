# README

The 'test/_global' folder is a special test folder that is not tied to a single feature.

This test file is executed against a running container constructed
from the value of 'color_and_hello' in the tests/_global/scenarios.json file.

The value of a scenarios element is any properties available in the 'devcontainer.json'.
Scenarios are useful for testing specific options in a feature, or to test a combination of features.

This test can be run with the following command (from the root of this repo)
   devcontainer features test --global-scenarios-only .