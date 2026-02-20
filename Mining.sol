// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Mining
 * @dev Mining contract with a 5x5 grid and basic deployment.
 */
contract Mining {
    uint256 public constant GRID_SIZE = 25; // 5x5 grid

    // Simple round tracking
    uint256 public currentRoundId;

    // Deployment tracking: roundId => square => user => amount
    mapping(uint256 => mapping(uint8 => mapping(address => uint256))) public userDeployments;

    // Square totals: roundId => square => total
    mapping(uint256 => mapping(uint8 => uint256)) public squareTotals;

    // Round totals
    mapping(uint256 => uint256) public roundTotals;

    // Events
    event RoundStarted(uint256 indexed roundId);
    event Deployed(uint256 indexed roundId, address indexed user, uint8 square, uint256 amount);

    constructor() {
        currentRoundId = 1;
        emit RoundStarted(1);
    }

    /**
     * @notice Deploy ETH to a single square
     * @param square The square index (0-24)
     */
    function deploy(uint8 square) external payable {
        require(square < GRID_SIZE, "Invalid square");
        require(msg.value > 0, "Must send ETH");

        uint256 roundId = currentRoundId;

        userDeployments[roundId][square][msg.sender] += msg.value;
        squareTotals[roundId][square] += msg.value;
        roundTotals[roundId] += msg.value;

        emit Deployed(roundId, msg.sender, square, msg.value);
    }

    /**
     * @notice Deploy ETH to multiple squares
     * @param squares Array of square indices (each 0-24)
     */
    function deployMultiple(uint8[] calldata squares) external payable {
        require(squares.length > 0 && squares.length <= GRID_SIZE, "Invalid length");
        require(msg.value > 0, "Must send ETH");

        uint256 amountPerSquare = msg.value / squares.length;
        require(amountPerSquare > 0, "Amount too small");

        uint256 roundId = currentRoundId;

        for (uint256 i = 0; i < squares.length; i++) {
            uint8 square = squares[i];
            require(square < GRID_SIZE, "Invalid square");

            userDeployments[roundId][square][msg.sender] += amountPerSquare;
            squareTotals[roundId][square] += amountPerSquare;
        }

        roundTotals[roundId] += msg.value;

        for (uint256 i = 0; i < squares.length; i++) {
            emit Deployed(roundId, msg.sender, squares[i], amountPerSquare);
        }
    }

    /**
     * @notice Start a new round (anyone can call)
     */
    function nextRound() external {
        currentRoundId++;
        emit RoundStarted(currentRoundId);
    }

    // ============ View Functions ============

    function getUserDeployment(uint256 roundId, uint8 square, address user) external view returns (uint256) {
        return userDeployments[roundId][square][user];
    }

    function getSquareTotal(uint256 roundId, uint8 square) external view returns (uint256) {
        return squareTotals[roundId][square];
    }

    function getRoundTotal(uint256 roundId) external view returns (uint256) {
        return roundTotals[roundId];
    }

    function getGridState(uint256 roundId) external view returns (uint256[25] memory) {
        uint256[25] memory grid;
        for (uint8 i = 0; i < GRID_SIZE; i++) {
            grid[i] = squareTotals[roundId][i];
        }
        return grid;
    }
}

