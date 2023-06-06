// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";


contract TokenedLibrary is ERC1155 {

    constructor() ERC1155("") {
        libAdmin = msg.sender;
    }

    uint public amountOfBooks = 0;

    address libAdmin;
    address NullAdress = 0x0000000000000000000000000000000000000000;

    struct Book {
        string name;
        string url;
        address borrowed;
        uint price;
    }

    mapping (uint => Book) bookNumber;
    mapping (string => uint) bookName;

    // Admin

    function changeAdmin(address _newAdmin) public {
        require(msg.sender == libAdmin, "You have to be current admin to change.");
        libAdmin = _newAdmin;

        // transfering books to new admin --> VERY EXPENSIVE --> BAD MOVE
        // uint[] memory ids;
        // uint[] memory amounts;
        // for (uint id = 0; id < amountOfBooks; id++) {
        //     ids[id] = id;
        //     if (balanceOf(libAdmin, id) != 0) {
        //         amounts[id] = 1;
        //     } else {
        //         amounts[id] = 0;
        //     }
        // }
        // safeBatchTransferFrom(libAdmin, _newAdmin, ids, amounts, "");
        //
    }

    function createBook(string calldata _bookUrl, string calldata _bookName, uint _bookPrice) public returns (uint) {
        require(msg.sender == libAdmin, "You have to be admin to create new book.");
        require(_bookPrice > 0, "Book's price must be not null.");
        bookNumber[amountOfBooks] = Book(_bookName, _bookUrl, NullAdress, _bookPrice);
        bookName[_bookName] = amountOfBooks;
        
        _mint(libAdmin, amountOfBooks, 1, ""); //creating a token: to, id, count, data
        amountOfBooks++;
        return amountOfBooks - 1;
    }

    function withdraw() public {
        require(msg.sender == libAdmin, "You have to be admin.");
        payable(libAdmin).transfer(address(this).balance);
    }

    // Admin & User

    function bookAvailability(string calldata _bookName) external view returns (address) {
        return bookAvailability(bookName[_bookName]);
    }

    function bookAvailability(uint _bookID) public view returns (address) {
        require(_bookID < amountOfBooks, "There no such many books.");
        require(msg.sender == libAdmin || 
            bookNumber[_bookID].borrowed == msg.sender, 
            "You have to be admin.");
        return bookNumber[_bookID].borrowed;
    }

    // User

    function uri(string calldata _bookName) external view returns (string memory) {
        return bookNumber[bookName[_bookName]].url;
    }

    function uri(uint _bookID) public override  view returns (string memory) {
        require(_bookID < amountOfBooks, "There no such many books.");
        return bookNumber[_bookID].url;
    }

    function borrowBook(string calldata _bookName, uint _months) public payable {
        uint _bookID = bookName[_bookName];
        require(bookNumber[_bookID].price != 0, "Book was not found.");
        require(_months > 0, "Months must be not null.");
        require(msg.value == _months * bookNumber[_bookID].price, "The price is different.");
        require(balanceOf(libAdmin, _bookID) != 0, "The book is borrowed now.");
        //balanceOf(libAdmin, bookName[_bookName]) != 0 -- checking is book on the admin account

        bookNumber[_bookID].borrowed = msg.sender;
        _setApprovalForAll(libAdmin, msg.sender, true); //giving approval to sender
        safeTransferFrom(libAdmin, msg.sender, _bookID, 1, ""); //book transfering to sender
        _setApprovalForAll(libAdmin, msg.sender, false); //taking approval from sender
    }

    function borrowBook(uint _bookID, uint _months) public payable {
        
        require(bookNumber[_bookID].price != 0, "Book was not found.");
        require(_months > 0, "Months must be not null.");
        require(msg.value == _months * bookNumber[_bookID].price, "The price is different.");
        require(balanceOf(libAdmin, _bookID) != 0, "The book is borrowed now.");
        //balanceOf(libAdmin, bookName[_bookName]) != 0 -- checking is book on the admin account

        bookNumber[_bookID].borrowed = msg.sender;
        _setApprovalForAll(libAdmin, msg.sender, true); //giving approval to sender
        safeTransferFrom(libAdmin, msg.sender, _bookID, 1, ""); //book transfering to sender
        _setApprovalForAll(libAdmin, msg.sender, false); //taking approval from sender
    }

    function returnBook(string calldata _bookName) external {
        returnBook(bookName[_bookName]);
    }

    function returnBook(uint _bookID) public {

        require(bookNumber[_bookID].price != 0, "Book was not found.");
        require(bookNumber[_bookID].borrowed == msg.sender, "You didn't borrow this book.");

        safeTransferFrom(msg.sender, libAdmin, _bookID, 1, "");
        bookNumber[_bookID].borrowed = NullAdress;
    }

}