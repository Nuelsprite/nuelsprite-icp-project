import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Time "mo:base/Time";
import Option "mo:base/Option";
import Iter "mo:base/Iter";

actor {
    type Book = {
        id: Nat;
        title: Text;
        author: Text;
        isbn: Text;
        available: Bool;
    };

    type Member = {
        id: Nat;
        name: Text;
        borrowedBooks: Buffer.Buffer<Nat>;
    };

    type BorrowRecord = {
        bookId: Nat;
        memberId: Nat;
        borrowDate: Int;
        returnDate: ?Int;
    };

    var books = Buffer.Buffer<Book>(0);
    var members = Buffer.Buffer<Member>(0);
    var borrowRecords = Buffer.Buffer<BorrowRecord>(0);

    public func addBook(title: Text, author: Text, isbn: Text) : async Nat {
        let bookId = books.size();
        let newBook : Book = {
            id = bookId;
            title = title;
            author = author;
            isbn = isbn;
            available = true;
        };
        books.add(newBook);
        bookId
    };

    public func registerMember(name: Text) : async Nat {
        let memberId = members.size();
        let newMember : Member = {
            id = memberId;
            name = name;
            borrowedBooks = Buffer.Buffer<Nat>(0);
        };
        members.add(newMember);
        memberId
    };

    public func borrowBook(bookId: Nat, memberId: Nat) : async Bool {
        if (bookId >= books.size() or memberId >= members.size()) {
            return false;
        };

        var book = books.get(bookId);
        if (not book.available) {
            return false;
        };

        book := { book with available = false };
        books.put(bookId, book);

        var member = members.get(memberId);
        let newBorrowedBooks = Buffer.Buffer<Nat>(member.borrowedBooks.size() + 1);
        for (id in member.borrowedBooks.vals()) {
            newBorrowedBooks.add(id);
        };
        newBorrowedBooks.add(bookId);
        member := { member with borrowedBooks = newBorrowedBooks };
        members.put(memberId, member);

        let borrowRecord : BorrowRecord = {
            bookId = bookId;
            memberId = memberId;
            borrowDate = Time.now();
            returnDate = null;
        };
        borrowRecords.add(borrowRecord);
        true
    };

    public func returnBook(bookId: Nat, memberId: Nat) : async Bool {
        if (bookId >= books.size() or memberId >= members.size()) {
            return false;
        };

        var book = books.get(bookId);
        book := { book with available = true };
        books.put(bookId, book);

        var member = members.get(memberId);
        let newBorrowedBooks = Buffer.Buffer<Nat>(0);
        for (id in member.borrowedBooks.vals()) {
            if (id != bookId) {
                newBorrowedBooks.add(id);
            };
        };
        member := { member with borrowedBooks = newBorrowedBooks };
        members.put(memberId, member);

        var recordFound = false;
        for (i in Iter.range(0, borrowRecords.size() - 1)) {
            var record = borrowRecords.get(i);
            if (record.bookId == bookId and record.memberId == memberId and Option.isNull(record.returnDate)) {
                record := { record with returnDate = ?Time.now() };
                borrowRecords.put(i, record);
                recordFound := true;
            };
        };
        recordFound
    };

    public query func getAvailableBooks() : async [Book] {
        var availableBooks = Buffer.Buffer<Book>(0);
        for (book in books.vals()) {
            if (book.available) {
                availableBooks.add(book);
            };
        };
        Buffer.toArray(availableBooks)
    };

    public query func getMemberBorrowedBooks(memberId: Nat) : async [Book] {
        if (memberId >= members.size()) {
            return [];
        };

        let member = members.get(memberId);
        var borrowedBooks = Buffer.Buffer<Book>(0);
        for (bookId in member.borrowedBooks.vals()) {
            if (bookId < books.size()) {
                borrowedBooks.add(books.get(bookId));
            };
        };
        Buffer.toArray(borrowedBooks)
    };
};