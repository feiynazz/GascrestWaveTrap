// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITrap {
    function collect() external view returns (bytes memory);
    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory);
}

contract GascrestWaveTrap is ITrap {
    uint256 private constant THRESHOLD_PROMILLE = 5; // 0.5% порог, срабатывает часто

    function collect() external view override returns (bytes memory) {
        return abi.encode(block.basefee, block.gaslimit);
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        if (data.length < 2) {
            return (false, abi.encode("Not enough data"));
        }

        (uint256 currentFee, uint256 currentLimit) = abi.decode(data[0], (uint256, uint256));
        (uint256 prevFee, uint256 prevLimit) = abi.decode(data[1], (uint256, uint256));

        // Проверка basefee
        uint256 feeDiffPromille = currentFee > prevFee
            ? ((currentFee - prevFee) * 1000) / prevFee
            : ((prevFee - currentFee) * 1000) / prevFee;

        // Проверка gaslimit
        uint256 limitDiffPromille = currentLimit > prevLimit
            ? ((currentLimit - prevLimit) * 1000) / prevLimit
            : ((prevLimit - currentLimit) * 1000) / prevLimit;

        if (feeDiffPromille >= THRESHOLD_PROMILLE || limitDiffPromille >= THRESHOLD_PROMILLE) {
            return (true, abi.encode("Gascrest wave detected"));
        }

        return (false, abi.encode("No significant change"));
    }
}
