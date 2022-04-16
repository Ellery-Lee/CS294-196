// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "hardhat/console.sol";
// import "./LibArrayForUint256Utils.sol";

contract SpectrumAction {

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

    // payment for seller
    uint[] paymentSeller;

    // payment for buyer
    uint[] paymentBuyer;

    //
    uint[] oneGroup;
    uint[] visited;

    struct Bid {
        uint i;             // buyer i
        uint[] prices;      // number k spectrum in order book
    }

    uint[] B;            // Buyer set

    address private owner;

    uint private beginTime;

    mapping(address => Bid) public addrToBid;

    mapping(uint => address) public idToAddr;

    mapping(address => uint) public ledger;
    mapping(address => uint) public ESPOOL;

    mapping(uint => uint[])[] public graph; // Interference Graph, bid[] is the neighbours

    mapping(address => uint[]) public A;    //  The result of the final spectrum allocation

    event logMessage(bytes32 s);

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        console.log("Contract deployed by:", msg.sender);
        owner = msg.sender;
        beginTime = block.timestamp;
    }

    // Registration: step 2 - 4
    function sellerSubmit(uint i, uint j, uint frequency, uint V, uint T) public payable {
        emit logMessage("Seller Sumbit");
        require(T + beginTime > block.timestamp, "Spectrum expire");
        require(ledger[msg.sender] + msg.value >= V, "Not enough deposit");

        ledger[msg.sender] += (msg.value - V);
        ESPOOL[msg.sender] += V;
        orderBook.push(S({seller : msg.sender, i : i, j : j, frequency : frequency, V : V, T : T}));
    }

    // *Registration: step 5
    function deleteExpire() internal {
        for (uint i = 0; i < orderBook.length; i++) {
            if (orderBook[i].T + beginTime >= block.timestamp) {
                ESPOOL[msg.sender] -= orderBook[i].V;
                ledger[msg.sender] += orderBook[i].V;

                orderBook[i] = orderBook[orderBook.length - 1];
                orderBook.pop();

            }
        }
    }

    // *Registration: step 6, sorting in increasing order
    function sortOrderBook() public {
        quickSort(0, orderBook.length);
    }


    function quickSort(uint left, uint right) internal {
        if (left < right) {
            uint pivot = partition(left, right);
            quickSort(left, pivot - 1);
            quickSort(pivot + 1, right);
        }
    }

    function partition(uint left, uint right) internal returns (uint){
        uint pivot = right--;
        while (left <= right) {
            if (orderBook[left].frequency > orderBook[right].frequency) swap(left, right--);
            else left++;
        }
        swap(left, pivot);
        return left;
    }

    function swap(uint left, uint right) internal {
        S memory temp = S({seller : orderBook[left].seller, i : orderBook[left].i, j : orderBook[left].j, frequency : orderBook[left].frequency, V : orderBook[left].V, T : orderBook[left].T});
        orderBook[left] = orderBook[right];
        orderBook[right] = S({seller : temp.seller, i : temp.i, j : temp.j, frequency : temp.frequency, V : temp.V, T : temp.T});
        delete temp;
    }

    // Bid Submission: step 1 - 5
    function bidSubmission(uint i, uint[] memory prices) public payable {
        uint M = findMax(prices);
        require(ledger[msg.sender] + msg.value >= M, "Not enough deposit");

        ledger[msg.sender] += (msg.value - M);
        ESPOOL[msg.sender] += M;

        addrToBid[msg.sender] = Bid(i, prices);
        idToAddr[i] = msg.sender;
        B.push(i);
    }

    function findMax(uint[] memory prices) internal returns (uint) {
        uint max = 0;
        for (uint i = 0; i < prices.length; i++) {
            if (prices[i] > max) {
                max = prices[i];
            }
        }
        return max;
    }

    function constructGraph(uint[][][] memory G) public isOwner {
        for (uint spId = 0; spId < G.length; spId++) {
            for (uint i = 0; i < G[spId].length; i++) {
                uint[] memory adj = new uint[](G[spId][i].length - 1);

                for (uint j = 1; j < G[spId][i].length; j++) {
                    adj[j - 1] = G[spId][i][j];
                }

                graph[spId][G[spId][i][0]] = adj;
            }
        }
    }
    // print graph
    function getGraph() public returns(uint[][][] memory G){
        uint[][][] memory tempGraph;
        for(uint spId = 0; spId < orderBook.length; spId++){
            for(uint bIndex = 0; bIndex < B.length; bIndex++){
                for(uint priceIndex = 0; priceIndex < graph[spId][B[bIndex]].length; priceIndex++){
                    tempGraph[spId][bIndex][priceIndex] = graph[spId][B[bIndex]][priceIndex];
                }
            }
        }
        return tempGraph;
    }

    // Group
    function qsort(uint[] storage array) internal {
        qsort(array, 0, array.length-1);
    }

    function qsort(uint[] storage array, uint begin, uint end) private {
        if(begin >= end || end == uint(0)) return;
        uint pivot = array[end];

        uint store = begin;
        uint i = begin;
        for(;i<end;i++){
            if(array[i] < pivot){
                uint tmp = array[i];
                array[i] = array[store];
                array[store] = tmp;
                store++;
            }
        }

        array[end] = array[store];
        array[store] = pivot;

        qsort(array, begin, store-1);
        qsort(array, store+1, end);
    }

    function groupOneGraph(mapping(uint => uint[]) storage spectrumGraph) internal returns (uint[] storage){
        uint[] storage _oneGroup = oneGroup;
        qsort(B);
        uint start = B[0]; //improve
        uint[] storage _visited = visited;
        _oneGroup.push(start);
        _visited.push(start);
        uint cur = start;
        while (visited.length<B.length){
            for (uint k = 0;k<spectrumGraph[cur].length;k++){
                _visited.push(spectrumGraph[cur][k]);
            }
            // LibArrayForUint256Utils.distinct(visited);
            if (_visited.length==B.length){
                break;
            }
            qsort(_visited);
            uint i=0; uint j=0;
            while (B[i]==_visited[j]){
                i++;j++;
            }
            _oneGroup.push(B[i]);
            _visited.push(B[i]);
            cur = B[i];
        }
        return _oneGroup;
    }

    function deleteUsedFromGraph() internal {

    }

    function group() internal {

    }

    // Allocation & Pricing
    function allocation() internal {


    }

    function clearing() internal{

    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getOrderBook() external view returns (S[] memory) {
        return orderBook;
    }

    function getLedgerWithAddr(address addr) external view returns (uint) {
        return ledger[addr];
    }

    function getESPOOLWithAddr(address addr) external view returns (uint) {
        return ESPOOL[addr];
    }

    function getBidWithAddr(address addr) external view returns (Bid memory) {
        return addrToBid[addr];
    }
}