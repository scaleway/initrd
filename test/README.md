# Test

Theses tests will launch lot of instances using `$BOOTSCRIPT_ID` with different flavor and different images and try to connect with ssh.

To run test use the test launcher `run_test.sh` with `bootscript_tests` directory

```
$ ARCH=x86_64 BOOTSCRIPT_ID=0b8ec97b-81f8-46fe-aa59-e5cb5a1dc75b bash run_test.sh -s bootscript_tests/

[test_bootscript_lauch_flavor.sh][INFO] START1-S
[test_bootscript_lauch_flavor.sh][INFO] Test 944a4410 with bootscript 0b8ec97b-81f8-46fe-aa59-e5cb5a1dc75b on START1-S
[test_bootscript_lauch_flavor.sh][INFO] OK on START1-S with image 944a4410
[test_bootscript_lauch_image.sh][INFO]  Test 265b32a3 with bootscript 0b8ec97b-81f8-46fe-aa59-e5cb5a1dc75b on START1-S
[test_bootscript_lauch_image.sh][INFO]  Test 49e33199 with bootscript 0b8ec97b-81f8-46fe-aa59-e5cb5a1dc75b on START1-S
[test_bootscript_lauch_image.sh][INFO]  Test f7696517 with bootscript 0b8ec97b-81f8-46fe-aa59-e5cb5a1dc75b on START1-S
[test_bootscript_lauch_image.sh][INFO]  Test 39d6dad1 with bootscript 0b8ec97b-81f8-46fe-aa59-e5cb5a1dc75b on START1-S
[test_bootscript_lauch_image.sh][INFO]  Test 7300a842 with bootscript 0b8ec97b-81f8-46fe-aa59-e5cb5a1dc75b on START1-S
[test_bootscript_lauch_image.sh][INFO]  Test 944a4410 with bootscript 0b8ec97b-81f8-46fe-aa59-e5cb5a1dc75b on START1-S
[test_bootscript_lauch_image.sh][INFO]  OK on START1-S with image 944a4410
[test_bootscript_lauch_image.sh][INFO]  Test be2293b6 with bootscript 0b8ec97b-81f8-46fe-aa59-e5cb5a1dc75b on START1-S
[test_bootscript_lauch_image.sh][INFO]  OK on START1-S with image 49e33199
[test_bootscript_lauch_image.sh][INFO]  OK on START1-S with image 39d6dad1
[test_bootscript_lauch_image.sh][INFO]  OK on START1-S with image f7696517
[test_bootscript_lauch_image.sh][INFO]  OK on START1-S with image 265b32a3
[test_bootscript_lauch_image.sh][INFO]  OK on START1-S with image 7300a842
[test_bootscript_lauch_image.sh][INFO]  OK on START1-S with image be2293b6
## Result ##
PASS test_bootscript_lauch_flavor.sh
PASS test_bootscript_lauch_image.sh
 ```

2 variables are mandatory:

- `$BOOTSCRIPT_ID`: bootscript_id to test
- `$ARCH`: architecture to test

Other variable can be pass

- `$MAX_PARALLEL_VM`: how many vm a single test can run at same time