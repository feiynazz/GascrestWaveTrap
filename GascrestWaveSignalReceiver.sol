// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GascrestWaveSignalReceiver {
    event GascrestWaveSignal(bytes data);

    function emitWave(bytes calldata data) external {
        emit GascrestWaveSignal(data);
    }
}
