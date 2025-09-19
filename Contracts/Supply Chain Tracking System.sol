// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Project {
    
    // Enum for product status
    enum ProductStatus {
        Manufactured,
        InTransit,
        Delivered,
        Sold
    }
    
    // Struct to represent a product
    struct Product {
        uint256 id;
        string name;
        string description;
        address manufacturer;
        uint256 manufacturingDate;
        ProductStatus currentStatus;
        string currentLocation;
        bool isAuthentic;
        uint256 price;
        address currentOwner;
    }
    
    // Struct to represent status updates
    struct StatusUpdate {
        uint256 timestamp;
        ProductStatus status;
        string location;
        address updatedBy;
        string notes;
    }
    
    // State variables
    mapping(uint256 => Product) public products;
    mapping(uint256 => StatusUpdate[]) public productHistory;
    mapping(address => bool) public authorizedManufacturers;
    mapping(address => bool) public authorizedLogistics;
    
    uint256 public productCount;
    address public owner;
    
    // Events
    event ProductAdded(
        uint256 indexed productId,
        string name,
        address indexed manufacturer,
        uint256 timestamp
    );
    
    event StatusUpdated(
        uint256 indexed productId,
        ProductStatus status,
        string location,
        address indexed updatedBy,
        uint256 timestamp
    );
    
    event AuthorityGranted(
        address indexed account,
        string role,
        address indexed grantedBy
    );
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyManufacturer() {
        require(
            authorizedManufacturers[msg.sender] || msg.sender == owner,
            "Only authorized manufacturers can perform this action"
        );
        _;
    }
    
    modifier onlyLogistics() {
        require(
            authorizedLogistics[msg.sender] || msg.sender == owner,
            "Only authorized logistics providers can perform this action"
        );
        _;
    }
    
    modifier productExists(uint256 _productId) {
        require(_productId > 0 && _productId <= productCount, "Product does not exist");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        authorizedManufacturers[msg.sender] = true;
        authorizedLogistics[msg.sender] = true;
    }
    
    // Core Function 1: Add a new product to the supply chain
    function addProduct(
        string memory _name,
        string memory _description,
        string memory _manufacturingLocation,
        uint256 _price
    ) public onlyManufacturer returns (uint256) {
        require(bytes(_name).length > 0, "Product name cannot be empty");
        require(_price > 0, "Price must be greater than 0");
        
        productCount++;
        
        products[productCount] = Product({
            id: productCount,
            name: _name,
            description: _description,
            manufacturer: msg.sender,
            manufacturingDate: block.timestamp,
            currentStatus: ProductStatus.Manufactured,
            currentLocation: _manufacturingLocation,
            isAuthentic: true,
            price: _price,
            currentOwner: msg.sender
        });
        
        // Add initial status update
        productHistory[productCount].push(StatusUpdate({
            timestamp: block.timestamp,
            status: ProductStatus.Manufactured,
            location: _manufacturingLocation,
            updatedBy: msg.sender,
            notes: "Product manufactured and added to supply chain"
        }));
        
        emit ProductAdded(productCount, _name, msg.sender, block.timestamp);
        
        return productCount;
    }
    
    // Core Function 2: Update product status during supply chain journey
    function updateStatus(
        uint256 _productId,
        ProductStatus _newStatus,
        string memory _location,
        string memory _notes
    ) public productExists(_productId) {
        
        // Check permissions based on status
        if (_newStatus == ProductStatus.InTransit) {
            require(
                authorizedLogistics[msg.sender] || msg.sender == owner,
                "Only logistics providers can set InTransit status"
            );
        } else if (_newStatus == ProductStatus.Delivered || _newStatus == ProductStatus.Sold) {
            require(
                authorizedLogistics[msg.sender] || 
                msg.sender == products[_productId].currentOwner ||
                msg.sender == owner,
                "Unauthorized to update to this status"
            );
        }
        
        Product storage product = products[_productId];
        
        // Validate status progression
        require(_newStatus != product.currentStatus, "Status is already set to this value");
        
        // Update product
        product.currentStatus = _newStatus;
        product.currentLocation = _location;
        
        // Add status update to history
        productHistory[_productId].push(StatusUpdate({
            timestamp: block.timestamp,
            status: _newStatus,
            location: _location,
            updatedBy: msg.sender,
            notes: _notes
        }));
        
        // Transfer ownership if sold
        if (_newStatus == ProductStatus.Sold) {
            product.currentOwner = msg.sender;
        }
        
        emit StatusUpdated(_productId, _newStatus, _location, msg.sender, block.timestamp);
    }
    
    // Core Function 3: Verify product authenticity and get complete tracking info
    function verifyAuthenticity(uint256 _productId) public view productExists(_productId) returns (
        bool isAuthentic,
        string memory productName,
        address manufacturer,
        uint256 manufacturingDate,
        ProductStatus currentStatus,
        string memory currentLocation,
        address currentOwner,
        uint256 price,
        uint256 totalUpdates
    ) {
        Product memory product = products[_productId];
        
        return (
            product.isAuthentic,
            product.name,
            product.manufacturer,
            product.manufacturingDate,
            product.currentStatus,
            product.currentLocation,
            product.currentOwner,
            product.price,
            productHistory[_productId].length
        );
    }
    
    // Helper function: Get complete product history
    function getProductHistory(uint256 _productId) public view productExists(_productId) returns (
        StatusUpdate[] memory
    ) {
        return productHistory[_productId];
    }
    
    // Helper function: Get specific status update
    function getStatusUpdate(uint256 _productId, uint256 _updateIndex) public view returns (
        uint256 timestamp,
        ProductStatus status,
        string memory location,
        address updatedBy,
        string memory notes
    ) {
        require(_updateIndex < productHistory[_productId].length, "Update index out of bounds");
        
        StatusUpdate memory update = productHistory[_productId][_updateIndex];
        return (
            update.timestamp,
            update.status,
            update.location,
            update.updatedBy,
            update.notes
        );
    }
    
    // Admin function: Authorize manufacturer
    function authorizeManufacturer(address _manufacturer) public onlyOwner {
        require(_manufacturer != address(0), "Invalid address");
        require(!authorizedManufacturers[_manufacturer], "Already authorized");
        
        authorizedManufacturers[_manufacturer] = true;
        emit AuthorityGranted(_manufacturer, "Manufacturer", msg.sender);
    }
    
    // Admin function: Authorize logistics provider
    function authorizeLogistics(address _logistics) public onlyOwner {
        require(_logistics != address(0), "Invalid address");
        require(!authorizedLogistics[_logistics], "Already authorized");
        
        authorizedLogistics[_logistics] = true;
        emit AuthorityGranted(_logistics, "Logistics", msg.sender);
    }
    
    // Admin function: Revoke manufacturer authorization
    function revokeManufacturerAuth(address _manufacturer) public onlyOwner {
        require(authorizedManufacturers[_manufacturer], "Not authorized");
        authorizedManufacturers[_manufacturer] = false;
    }
    
    // Admin function: Revoke logistics authorization
    function revokeLogisticsAuth(address _logistics) public onlyOwner {
        require(authorizedLogistics[_logistics], "Not authorized");
        authorizedLogistics[_logistics] = false;
    }
    
    // Function: Get all products by manufacturer
    function getProductsByManufacturer(address _manufacturer) public view returns (uint256[] memory) {
        uint256[] memory manufacturerProducts = new uint256[](productCount);
        uint256 count = 0;
        
        for (uint256 i = 1; i <= productCount; i++) {
            if (products[i].manufacturer == _manufacturer) {
                manufacturerProducts[count] = i;
                count++;
            }
        }
        
        // Create array with correct size
        uint256[] memory result = new uint256[](count);
        for (uint256 j = 0; j < count; j++) {
            result[j] = manufacturerProducts[j];
        }
        
        return result;
    }
    
    // Function: Mark product as counterfeit (emergency use)
    function markAsCounterfeit(uint256 _productId) public onlyOwner productExists(_productId) {
        products[_productId].isAuthentic = false;
        
        // Add status update
        productHistory[_productId].push(StatusUpdate({
            timestamp: block.timestamp,
            status: products[_productId].currentStatus,
            location: products[_productId].currentLocation,
            updatedBy: msg.sender,
            notes: "ALERT: Product marked as counterfeit by system administrator"
        }));
    }
    
    // Function: Get product basic info (public view)
    function getProductInfo(uint256 _productId) public view productExists(_productId) returns (
        string memory name,
        string memory description,
        address manufacturer,
        uint256 price,
        ProductStatus status,
        bool isAuthentic
    ) {
        Product memory product = products[_productId];
        return (
            product.name,
            product.description,
            product.manufacturer,
            product.price,
            product.currentStatus,
            product.isAuthentic
        );
    }
    
    // Function: Get status string (helper for frontend)
    function getStatusString(ProductStatus _status) public pure returns (string memory) {
        if (_status == ProductStatus.Manufactured) return "Manufactured";
        if (_status == ProductStatus.InTransit) return "In Transit";
        if (_status == ProductStatus.Delivered) return "Delivered";
        if (_status == ProductStatus.Sold) return "Sold";
        return "Unknown";
    }
}
