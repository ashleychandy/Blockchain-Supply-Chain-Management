// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract SupplyChainManagement {
    enum ProductStatus { Created, SentByManufacturer, ReceivedByDistributor, SentByDistributor, ReceivedByRetailer }
    
    struct Product {
        uint256 id;
        ProductStatus status;
        uint256 createdAt;
        uint256 sentByManufacturerAt;
        uint256 receivedByDistributorAt;
        uint256 sentByDistributorAt;
        uint256 receivedByRetailerAt;
    }

    address public manufacturer;
    address public distributor;
    address public retailer;
    uint256 public productCount;

    mapping(uint256 => Product) public products;

    event ProductCreated(uint256 productId, address manufacturer, uint256 timestamp);
    event ProductSent(uint256 productId, address from, address to, uint256 timestamp);
    event ProductReceived(uint256 productId, address receiver, uint256 timestamp);

    modifier onlyManufacturer() {
        require(msg.sender == manufacturer, "Only manufacturer can call this function");
        _;
    }

    modifier onlyDistributor() {
        require(msg.sender == distributor, "Only distributor can call this function");
        _;
    }

    modifier onlyRetailer() {
        require(msg.sender == retailer, "Only retailer can call this function");
        _;
    }

    function setAddresses(address _manufacturer, address _distributor, address _retailer) public {
        manufacturer = _manufacturer;
        distributor = _distributor;
        retailer = _retailer;
    }

    function productExists(uint256 _productId) internal view returns (bool) {
        return products[_productId].id != 0;
    }   

    function createProduct() external onlyManufacturer {
        productCount++;
        products[productCount] = Product({
            id: productCount,
            status: ProductStatus.Created,
            createdAt: block.timestamp,
            sentByManufacturerAt: 0,
            receivedByDistributorAt: 0,
            sentByDistributorAt: 0,
            receivedByRetailerAt: 0
        });
        emit ProductCreated(productCount, msg.sender, block.timestamp);
    }

    function sendProduct(uint256 _productId) external {
        require(productExists(_productId), "Product does not exist");
        Product storage product = products[_productId];

        if (msg.sender == manufacturer) {
            require(product.status == ProductStatus.Created, "Product is not in the correct state");
            product.status = ProductStatus.SentByManufacturer;
            product.sentByManufacturerAt = block.timestamp;
            emit ProductSent(_productId, manufacturer, distributor, block.timestamp);
        } else if (msg.sender == distributor) {
            require(product.status == ProductStatus.ReceivedByDistributor, "Product is not in the correct state");
            product.status = ProductStatus.SentByDistributor;
            product.sentByDistributorAt = block.timestamp;
            emit ProductSent(_productId, distributor, retailer, block.timestamp);
        } else {
            revert("Unauthorized sender");
        }
    }

    function receiveProduct(uint256 _productId) external {
        require(productExists(_productId), "Product does not exist");
        Product storage product = products[_productId];

        if (msg.sender == distributor) {
            require(product.status == ProductStatus.SentByManufacturer, "Product is not in the correct state");
            product.status = ProductStatus.ReceivedByDistributor;
            product.receivedByDistributorAt = block.timestamp;
            emit ProductReceived(_productId, distributor, block.timestamp);
        } else if (msg.sender == retailer) {
            require(product.status == ProductStatus.SentByDistributor, "Product is not in the correct state");
            product.status = ProductStatus.ReceivedByRetailer;
            product.receivedByRetailerAt = block.timestamp;
            emit ProductReceived(_productId, retailer, block.timestamp);
        } else {
            revert("Unauthorized receiver");
        }
    }

    function getProduct(uint256 _productId) external view returns (Product memory) {
        require(productExists(_productId), "Product does not exist");
        return products[_productId];
    }

    function getProductCount() external view returns (uint256) {
        return productCount;
    }
}
