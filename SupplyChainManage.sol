// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PharmaDataRegistry {
    address public owner;
    enum UserRole { Manufacturer, Distributor, Retailer }

    struct Medicine {
        address manufacturer;
        string name;
        string batchNumber;
        uint256 manufacturingDate;
        uint256 expiryDate;
        uint256 price;
        uint256 quantity;
    }

    mapping(address => UserRole) private userRoles;
    mapping(address => Medicine[]) private medicineRecords;

    event MedicineManufactured(address indexed manufacturer, string batchNumber);
    event MedicineSold(address indexed seller, address indexed buyer, string batchNumber, uint256 quantity);
    event RoleUpdated(address indexed user, UserRole newRole);
    event OwnershipTransferred(address indexed from, address indexed to, string batchNumber);

    constructor() {
        owner = msg.sender;
        userRoles[msg.sender] = UserRole.Manufacturer; 
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyManufacturer() {
        require(userRoles[msg.sender] == UserRole.Manufacturer, "Only manufacturers can use this");
        _;
    }

    modifier onlyDistributorOrRetailer() {
        require(
            userRoles[msg.sender] == UserRole.Distributor || userRoles[msg.sender] == UserRole.Retailer,
            "Only distributors and retailers can use this"
        );
        _;
    }

    function addUser(address user, UserRole role) external onlyOwner {
        userRoles[user] = role;
        emit RoleUpdated(user, role);
    }

    function updateUserRole(address user, UserRole newRole) external onlyOwner {
        require(user != owner, "Cannot change owner's role");
        userRoles[user] = newRole;
        emit RoleUpdated(user, newRole);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        owner = newOwner;
    }

    function manufactureMedicine(
        string memory name,
        string memory batchNumber,
        uint256 manufacturingDate,
        uint256 expiryDate,
        uint256 price,
        uint256 quantity
    ) external onlyManufacturer {
        medicineRecords[msg.sender].push(Medicine({
            manufacturer: msg.sender,
            name: name,
            batchNumber: batchNumber,
            manufacturingDate: manufacturingDate,
            expiryDate: expiryDate,
            price: price,
            quantity: quantity
        }));
        emit MedicineManufactured(msg.sender, batchNumber);
    }

    function sellMedicine(address buyer, string memory batchNumber, uint256 quantity) external onlyDistributorOrRetailer {
        Medicine[] storage medicines = medicineRecords[msg.sender];
        int256 index = findMedicineIndexByBatchNumber(medicines, batchNumber);

        require(index != -1, "Medicine not found");
        require(medicines[uint256(index)].quantity >= quantity, "Insufficient quantity");

        medicines[uint256(index)].quantity -= quantity;

        medicineRecords[buyer].push(Medicine({
            manufacturer: medicines[uint256(index)].manufacturer,
            name: medicines[uint256(index)].name,
            batchNumber: batchNumber,
            manufacturingDate: medicines[uint256(index)].manufacturingDate,
            expiryDate: medicines[uint256(index)].expiryDate,
            price: medicines[uint256(index)].price,
            quantity: quantity
        }));
        emit MedicineSold(msg.sender, buyer, batchNumber, quantity);
    }

    function getUserRole(address user) external view returns (UserRole) {
        return userRoles[user];
    }

    function getUserMedicineCount(address user) external view returns (uint256) {
        return medicineRecords[user].length;
    }

    function getUserMedicine(address user, uint256 index) external view returns (
        address manufacturer,
        string memory name,
        string memory batchNumber,
        uint256 manufacturingDate,
        uint256 expiryDate,
        uint256 price,
        uint256 quantity
    ) {
        require(index < medicineRecords[user].length, "Invalid index");
        Medicine memory medicine = medicineRecords[user][index];
        return (
            medicine.manufacturer,
            medicine.name,
            medicine.batchNumber,
            medicine.manufacturingDate,
            medicine.expiryDate,
            medicine.price,
            medicine.quantity
        );
    }

    function findMedicineIndexByBatchNumber(Medicine[] storage medicines, string memory batchNumber) internal view returns (int256) {
        for (int256 i = 0; i < int256(medicines.length); i++) {
            if (keccak256(bytes(medicines[uint256(i)].batchNumber)) == keccak256(bytes(batchNumber))) {
                return i;
            }
        }
        return -1;
    }
}
