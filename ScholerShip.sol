// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Scholarship {
    struct Student {
        bool applied;
        bool verified;
        uint256 marks;
        uint256 scholarship;
        string name;
        string stream;
        bool connectedWallet;
    }

    mapping(address => Student) public students;
    mapping(address => uint256) public balances;

    uint256 public applicationDeadline;
    address payable public collegeWallet;
    
    modifier beforeDeadline() {
        require(block.timestamp <= applicationDeadline, "Scholarship application deadline has passed");
        _;
    }
  modifier onlyOwner() {
        require(msg.sender == collegeWallet, "Only the owner can perform this action");
        _;
    }

   

    event BalanceAdded(address indexed account, uint256 amount);
    event WalletConnected(address indexed account);
    event ScholarshipGranted(address indexed account, uint256 amount);
    event RemainingFeesTransferred(address indexed account, uint256 amount);
      event DeadlineUpdated(uint256 newDeadline);

    constructor(address payable _collegeWallet) {
        collegeWallet = _collegeWallet;
    }

    function addBalance(uint256 _amount) public payable {
        require(msg.value == _amount, "Please send the exact amount of ether");
        balances[msg.sender] += _amount;
        emit BalanceAdded(msg.sender, _amount);
    }

    function connectWallet() public {
        require(!students[msg.sender].connectedWallet, "Wallet is already connected");
        students[msg.sender].connectedWallet = true;
        emit WalletConnected(msg.sender);
    }
       function updateDeadline(uint256 _newDeadline) public onlyOwner {
        applicationDeadline = _newDeadline;
        emit DeadlineUpdated(_newDeadline);
    }

    function applys(string memory _name, string memory _stream, uint256 _marks) public payable beforeDeadline {
        require(students[msg.sender].connectedWallet, "Please connect your MetaMask wallet before applying for the scholarship");
        require(!students[msg.sender].applied, "You have already applied for the scholarship");
        require(balances[msg.sender] >= calculateTotalFees(_stream), "Please pay the full scholarship fees");

        students[msg.sender] = Student({
            applied: true,
            verified: false,
            marks: _marks,
            scholarship: 0,
            name: _name,
            stream: _stream,
            connectedWallet: true
        });
    }

    function verify() public {
        Student storage student = students[msg.sender];
        require(student.applied, "You have not applied for the scholarship");
        require(!student.verified, "You have already been verified");

        student.verified = true;

        uint256 scholarshipPercentage = calculateScholarshipPercentage(student.marks);
        student.scholarship = calculateScholarshipAmount(student.stream, scholarshipPercentage);

        // Transfer the scholarship amount to the student's account
        payable(msg.sender).transfer(student.scholarship);
        emit ScholarshipGranted(msg.sender, student.scholarship);

        // Transfer the remaining fees to the college's wallet address
        uint256 remainingFees = calculateTotalFees(student.stream) - student.scholarship;
        collegeWallet.transfer(remainingFees);
        emit RemainingFeesTransferred(collegeWallet, remainingFees);
    }

    function calculateTotalFees(string memory _stream) private pure returns (uint256) {
        if (keccak256(bytes(_stream)) == keccak256(bytes("btech"))) {
            return 650000 wei;
        } else if (keccak256(bytes(_stream)) == keccak256(bytes("bca"))) {
            return 450000 wei;
        } else if (keccak256(bytes(_stream)) == keccak256(bytes("mtech"))) {
            return 500000 wei;
        } else if (keccak256(bytes(_stream)) == keccak256(bytes("mca"))) {
            return 400000 wei;
        }
        revert("Invalid stream");
    }

    function calculateScholarshipPercentage(uint256 _marks) private pure returns (uint256) {
        if (_marks >= 90) {
            return 30;
        } else if (_marks >= 85) {
            return 25;
        } else if (_marks >= 80) {
            return 15;
        } else if (_marks >= 75) {
            return 10;
        }
        return 0;
    }

    function calculateScholarshipAmount(string memory _stream, uint256 _scholarshipPercentage) private pure returns (uint256) {
        uint256 totalFees = calculateTotalFees(_stream);
        return (totalFees * _scholarshipPercentage) / 100;
    }
}
