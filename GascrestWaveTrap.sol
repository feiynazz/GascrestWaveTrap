// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITrap {
    function collect() external view returns (bytes memory);
    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory);
}

/// @title GascrestWaveTrap — detects gas/basefee waves with configurable threshold (currently constant due to Drosera limits)
contract GascrestWaveTrap is ITrap {
    // Threshold in promille (0.5%)
    uint256 public constant THRESHOLD_PROMILLE = 5;

    /// @notice Collect current block parameters for comparison
    function collect() external view override returns (bytes memory) {
        return abi.encode(block.basefee, block.gaslimit);
    }

    /// @notice Check if wave threshold exceeded between current and previous snapshots
    /// @param data Array of encoded snapshots: [current, previous]
    /// @return triggered True if threshold exceeded
    /// @return response Detailed encoded message with values and diffs
    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        if (data.length < 2) {
            return (false, abi.encode("Not enough data"));
        }

        (uint256 currentFee, uint256 currentLimit) = abi.decode(data[0], (uint256, uint256));
        (uint256 prevFee, uint256 prevLimit) = abi.decode(data[1], (uint256, uint256));

        if (prevFee == 0 || prevLimit == 0) {
            return (false, abi.encode("Invalid baseline data"));
        }

        uint256 feeDiffPromille = _promilleChange(currentFee, prevFee);
        uint256 limitDiffPromille = _promilleChange(currentLimit, prevLimit);

        bool triggered = feeDiffPromille >= THRESHOLD_PROMILLE || limitDiffPromille >= THRESHOLD_PROMILLE;

        bytes memory response = abi.encode(
            "Gascrest wave detected",
            currentFee,
            prevFee,
            currentLimit,
            prevLimit,
            feeDiffPromille,
            limitDiffPromille
        );

        return (triggered, triggered ? response : abi.encode("No significant change", response));
    }

    /// @dev Calculate promille change between two values
    function _promilleChange(uint256 current, uint256 previous) private pure returns (uint256) {
        uint256 diff = current > previous ? current - previous : previous - current;
        return (diff * 1000) / previous;
    }
}
