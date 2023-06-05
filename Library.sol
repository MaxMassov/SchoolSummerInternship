// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Library {

    constructor() {
        libAdmin = msg.sender;
    }

    uint public amountOfBooks = 0;

    address libAdmin;
    address NullAdress = 0x0000000000000000000000000000000000000000;

    struct Book {
        string name;
        string author;
        string picture;
        bool availability;
        address borrowed;
        uint price;
    }

    mapping (uint => Book) bookNumber;
    mapping (string => uint) bookName;

    // Admin

    function changeAdmin(address _newAdmin) public {
        require(msg.sender == libAdmin, "You have to be current admin to change.");
        libAdmin = _newAdmin;
    }

    function createBook(string calldata _bookName, 
                        string calldata _bookPicture, 
                        string calldata _bookAuthor,
                        uint _bookPrice) public returns (uint) {
        require(msg.sender == libAdmin, "You have to be admin to create new book.");
        require(_bookPrice > 0, "Book's price must be not null.");
        bookNumber[amountOfBooks] = Book(_bookName, _bookAuthor, _bookPicture, true, NullAdress, _bookPrice);
        bookName[_bookName] = amountOfBooks;
        amountOfBooks++;
        return amountOfBooks - 1;
    }

    function withdraw() public {
        require(msg.sender == libAdmin, "You have to be admin.");
        payable(libAdmin).transfer(address(this).balance);
    }

    // Admin & User

    function bookavailability(string calldata _bookName) public view returns (address) {
        require(msg.sender == libAdmin || 
            bookNumber[bookName[_bookName]].borrowed == msg.sender, 
            "You have to be admin.");
        return bookNumber[bookName[_bookName]].borrowed;
    }

    function bookavailability(uint _bookID) public view returns (address) {
        require(_bookID < amountOfBooks, "There no such many books.");
        require(msg.sender == libAdmin || 
            bookNumber[_bookID].borrowed == msg.sender, 
            "You have to be admin.");
        return bookNumber[_bookID].borrowed;
    }

    // User

    function bookInfo(string calldata _bookName) public view returns (Book memory) {
        return bookNumber[bookName[_bookName]];
    }

    function bookInfo(uint _bookID) public view returns (Book memory) {
        require(_bookID < amountOfBooks, "There no such many books.");
        return bookNumber[_bookID];
    }

    function borrowBook(string calldata _bookName, uint _months) public payable {
        
        require(bookNumber[bookName[_bookName]].price != 0, "Book was not found.");
        require(_months > 0, "Months must be not null.");
        require(msg.value == _months * bookNumber[bookName[_bookName]].price, "The price is different.");
        require(bookNumber[bookName[_bookName]].availability, "The book is borrowed now.");

        bookNumber[bookName[_bookName]].availability = false;
        bookNumber[bookName[_bookName]].borrowed = msg.sender;
    }

    function returnBook(string calldata _bookName) public {

        require(bookNumber[bookName[_bookName]].price != 0, "Book was not found.");
        require(bookNumber[bookName[_bookName]].borrowed == msg.sender, "You didn't borrow this book.");

        bookNumber[bookName[_bookName]].availability = true;
        bookNumber[bookName[_bookName]].borrowed = NullAdress;
    }

}