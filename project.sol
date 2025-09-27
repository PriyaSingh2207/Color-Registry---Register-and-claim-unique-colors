// Color Registry/Project.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Color Registry
 * @dev A smart contract for registering and claiming unique colors on the blockchain
 * @author Your Name
 */
contract Project {
    
    // Struct to store color information
    struct Color {
        string name;           // Human-readable color name
        string hexCode;        // Hex color code (e.g., "#FF5733")
        address owner;         // Address that owns this color
        uint256 registeredAt;  // Timestamp when color was registered
        bool exists;           // Flag to check if color exists
    }
    
    // Mappings
    mapping(string => Color) public colors;           // hexCode => Color
    mapping(address => string[]) public ownerColors;  // owner => array of hex codes
    mapping(string => bool) public colorExists;       // hexCode => exists
    
    // State variables
    address public owner;
    uint256 public totalColorsRegistered;
    uint256 public registrationFee;
    
    // Events
    event ColorRegistered(
        string indexed hexCode,
        string name,
        address indexed owner,
        uint256 timestamp
    );
    
    event ColorTransferred(
        string indexed hexCode,
        address indexed from,
        address indexed to,
        uint256 timestamp
    );
    
    event RegistrationFeeUpdated(uint256 oldFee, uint256 newFee);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }
    
    modifier validHexCode(string memory _hexCode) {
        require(bytes(_hexCode).length == 7, "Hex code must be 7 characters long");
        require(bytes(_hexCode)[0] == '#', "Hex code must start with #");
        _;
    }
    
    modifier colorNotExists(string memory _hexCode) {
        require(!colorExists[_hexCode], "Color already registered");
        _;
    }
    
    modifier colorExistsCheck(string memory _hexCode) {
        require(colorExists[_hexCode], "Color does not exist");
        _;
    }
    
    modifier onlyColorOwner(string memory _hexCode) {
        require(colors[_hexCode].owner == msg.sender, "You don't own this color");
        _;
    }
    
    // Constructor
    constructor(uint256 _registrationFee) {
        owner = msg.sender;
        registrationFee = _registrationFee;
        totalColorsRegistered = 0;
    }
    
    /**
     * @dev Register a new unique color
     * @param _name Human-readable name for the color
     * @param _hexCode Hex color code (e.g., "#FF5733")
     */
    function registerColor(
        string memory _name,
        string memory _hexCode
    ) 
        external 
        payable 
        validHexCode(_hexCode)
        colorNotExists(_hexCode)
    {
        require(msg.value >= registrationFee, "Insufficient registration fee");
        require(bytes(_name).length > 0, "Color name cannot be empty");
        
        // Create new color
        colors[_hexCode] = Color({
            name: _name,
            hexCode: _hexCode,
            owner: msg.sender,
            registeredAt: block.timestamp,
            exists: true
        });
        
        // Update mappings
        colorExists[_hexCode] = true;
        ownerColors[msg.sender].push(_hexCode);
        totalColorsRegistered++;
        
        // Emit event
        emit ColorRegistered(_hexCode, _name, msg.sender, block.timestamp);
        
        // Refund excess payment
        if (msg.value > registrationFee) {
            payable(msg.sender).transfer(msg.value - registrationFee);
        }
    }
    
    /**
     * @dev Get color information by hex code
     * @param _hexCode The hex code of the color to query
     * @return name The color name
     * @return hexCode The hex color code  
     * @return owner The owner address
     * @return registeredAt Registration timestamp
     */
    function getColor(string memory _hexCode)
        external
        view
        colorExistsCheck(_hexCode)
        returns (
            string memory name,
            string memory hexCode,
            address owner,
            uint256 registeredAt
        )
    {
        Color memory color = colors[_hexCode];
        return (color.name, color.hexCode, color.owner, color.registeredAt);
    }
    
    /**
     * @dev Transfer color ownership to another address
     * @param _hexCode The hex code of the color to transfer
     * @param _to The address to transfer the color to
     */
    function transferColor(
        string memory _hexCode,
        address _to
    )
        external
        colorExistsCheck(_hexCode)
        onlyColorOwner(_hexCode)
    {
        require(_to != address(0), "Cannot transfer to zero address");
        require(_to != msg.sender, "Cannot transfer to yourself");
        
        address from = msg.sender;
        
        // Update color ownership
        colors[_hexCode].owner = _to;
        
        // Update owner mappings
        ownerColors[_to].push(_hexCode);
        _removeColorFromOwner(from, _hexCode);
        
        // Emit event
        emit ColorTransferred(_hexCode, from, _to, block.timestamp);
    }
    
    // Helper function to remove color from owner's array
    function _removeColorFromOwner(address _owner, string memory _hexCode) internal {
        string[] storage userColors = ownerColors[_owner];
        for (uint256 i = 0; i < userColors.length; i++) {
            if (keccak256(bytes(userColors[i])) == keccak256(bytes(_hexCode))) {
                userColors[i] = userColors[userColors.length - 1];
                userColors.pop();
                break;
            }
        }
    }
    
    // Owner-only functions
    function setRegistrationFee(uint256 _newFee) external onlyOwner {
        uint256 oldFee = registrationFee;
        registrationFee = _newFee;
        emit RegistrationFeeUpdated(oldFee, _newFee);
    }
    
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        payable(owner).transfer(balance);
    }
    
    // View functions
    function getOwnerColors(address _owner) external view returns (string[] memory) {
        return ownerColors[_owner];
    }
    
    function isColorAvailable(string memory _hexCode) external view returns (bool) {
        return !colorExists[_hexCode];
    }
    
    function getRegistrationFee() external view returns (uint256) {
        return registrationFee;
    }
    
    function getTotalColors() external view returns (uint256) {
        return totalColorsRegistered;
    }
}
