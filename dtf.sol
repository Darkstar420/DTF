// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DTFEventTicketing is ERC721Enumerable, ReentrancyGuard, Ownable {
    struct Event {
        string name;
        uint256 ticketPrice;
        uint256 totalTickets;
        uint256 ticketsSold;
    }

    Event[] public events;
    mapping(uint256 => uint256) public ticketToEvent;
    mapping(uint256 => bool) public ticketResold;

    event EventCreated(uint256 eventId, string eventName, uint256 ticketPrice, uint256 totalTickets);
    event TicketPurchased(uint256 eventId, uint256 ticketId, address buyer);
    event TicketResold(uint256 ticketId, address seller, address buyer);

    constructor() ERC721("DTFEventTicket", "DTFT") {}

    function createEvent(string memory eventName, uint256 ticketPrice, uint256 totalTickets) public onlyOwner {
        events.push(Event(eventName, ticketPrice, totalTickets, 0));
        uint256 eventId = events.length - 1;

        emit EventCreated(eventId, eventName, ticketPrice, totalTickets);
    }

    function buyTicket(uint256 eventId) public payable nonReentrant {
        Event storage eventInfo = events[eventId];
        require(eventInfo.ticketsSold < eventInfo.totalTickets, "All tickets sold");
        require(msg.value == eventInfo.ticketPrice, "Incorrect payment");

        uint256 ticketId = totalSupply();
        ticketToEvent[ticketId] = eventId;
        eventInfo.ticketsSold++;
        _safeMint(msg.sender, ticketId);

        emit TicketPurchased(eventId, ticketId, msg.sender);
    }

    function sellTicket(uint256 ticketId, address to) public {
        require(ownerOf(ticketId) == msg.sender, "Not the ticket owner");
        require(!ticketResold[ticketId], "Ticket already resold");

        uint256 eventId = ticketToEvent[ticketId];
        Event storage eventInfo = events[eventId];

        _transfer(msg.sender, to, ticketId);
        payable(msg.sender).transfer(eventInfo.ticketPrice); // Implement logic to handle price adjustment if necessary
        ticketResold[ticketId] = true;

        emit TicketResold(ticketId, msg.sender, to);
    }

    // Additional functions can be implemented here to handle refunds, event cancellations, and dynamic pricing adjustments.
}

