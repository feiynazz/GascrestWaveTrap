// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITrap {
    function collect() external view returns (bytes memory);
    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory);
}

contract GascrestWaveTrap is ITrap {
    uint256 private constant THRESHOLD_PERCENT = 2; // Trigger threshold: 2% change in gaslimit

    function collect() external view override returns (bytes memory) {
        return abi.encode(block.gaslimit);
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        if (data.length < 2) {
            return (false, abi.encode("Not enough data"));
        }

        uint256 currentLimit = abi.decode(data[0], (uint256));
        uint256 previousLimit = abi.decode(data[1], (uint256));

        if (previousLimit == 0) {
            return (false, abi.encode("Invalid previous limit"));
        }

        uint256 diffPercent = currentLimit > previousLimit
            ? ((currentLimit - previousLimit) * 100) / previousLimit
            : ((previousLimit - currentLimit) * 100) / previousLimit;

        if (diffPercent >= THRESHOLD_PERCENT) {
            return (true, abi.encode("Gaslimit crest detected"));
        } else {
            return (false, abi.encode("No significant wave"));
        }
    }
}
