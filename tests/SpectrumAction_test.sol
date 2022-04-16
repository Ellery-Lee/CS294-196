// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "hardhat/console.sol";
import "../contracts/SpectrumAction.sol";

contract SpectrumActionTest {


    SpectrumAction spectrumAction;
    function beforeAll () public {
        spectrumAction = new SpectrumAction();
        console.log("Finish Initialization");
    }
}
