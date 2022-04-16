pragma solidity >=0.7.0 <0.9.0;

contract spectrumAction {

    // Sij
    struct S {
        address seller;     // seller i' address
        uint i;
        uint j;
        uint frequency;
        uint V;             // Valuation
        uint T;             // expire time

    }

    //order book
    S[] public orderBook;


    struct Bid {
        uint i;             // buyer i
        uint[] prices;      // number k spectrum in order book
    }

    address[] B;            // Buyer set

    mapping(address => Bid) public addrToBid;

    mapping(address => uint) public ledger;
    mapping(address => uint) public ESPOOL;

    mapping(address => Bid[]) public graph; // Interference Graph, bid[] is the neighbours

    mapping(address => uint[]) public A;    //  The result of the final spectrum allocation

    // Registration: step 2 - 4
    function sellerSubmit(uint i, uint j, uint frequency, uint price, uint V, uint T) public payable {
        require(T > now, "Spectrum expire");
        require(ledger[msg.sender] + msg.value >= V, "Not enough deposit");

        ledger[msg.sender] += (msg.value - V);
        ESPOOL[msg.sender] += V;
        orderBook.push(S({seller : msg.sender, i : i, j : j, frequency : frequency, V : V, T : T}));
    }

    // *Registration: step 5
    function deleteExpire() internal {
        for (int i = 0; i < orderBook.length; i++) {
            if (orderBook[i].T >= now) {
                ESPOOL[msg.sender] -= orderBook[i].V;
                ledger[msg.sender] += orderBook[i].V;

                orderBook[i] = orderBook[orderBook.length - 1];
                orderBook.pop();

            }
        }
    }

    // *Registration: step 6, sorting in increasing order
    function sortOrderBook(uint left, uint right) internal {
        if (left < right) {
            int pivot = partition(left, right);
            sortOrderBook(left, pivot - 1);
            sortOrderBook(pivot + 1, right);
        }

    }

    function partition(uint left, uint right) internal returns (int){
        uint pivot = right--;
        while (left <= right) {
            if (orderBook[left].frequency > orderBook[right].frequency) swap(left, right--);
            else left++;
        }
        swap(left, right);
        return left;
    }

    function swap(uint left, uint right) internal {
        S memory temp = S({seller : orderBook[left].seller, i : orderBook[left].i, j : orderBook[left].j, frequency : orderBook[left].frequency, V : orderBook[left].V, T : orderBook[left].T});
        orderBook[left] = orderBook[right];
        orderBook[right] = S({seller : temp.seller, i : temp.i, j : temp.j, frequency : temp.frequency, V : temp.V, T : temp.T});
        delete temp;
    }

    // Bid Submission: step 1 - 5
    function bidSubmission(int i, uint[] prices) public payable {
        uint M = findMax(prices);
        require(ledger[msg.sender] + msg.value >= M, "Not enough deposit");

        ledger[msg.sender] += (msg.value - M);
        ESPOOL[msg.sender] += M;

        addrToBid[msg.sender] = Bid(i, prices);
        B.push(msg.sender);
    }

    function findMax(uint[] prices) internal returns (uint) {
        uint max = 0;
        for (int i = 0; i < prices.length; i++) {
            if (prices[i] > max) {
                max = prices[i];
            }
        }
        return max;
    }

    // Group
    function group() internal {}

    // Allocation & Pricing
    function allocation() internal {}


}
