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

    struct Graph {
        mapping(uint => uint[]) g;
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

    //    mapping(uint => uint[])[] public graph; // Interference Graph, bid[] is the neighbours

    Graph[] graphList;

    mapping(address => uint[]) public A;    //  The result of the final spectrum allocation

    event logMessage(bytes32 s);

    uint MAX_INT = 2**256 - 1;

    uint[] maxSet;
    uint[] currSet;

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
            Graph storage graphConstruct = graphList.push();
            for (uint i = 0; i < G[spId].length; i++) {
                uint[] memory adj = new uint[](G[spId][i].length - 1);

                for (uint j = 1; j < G[spId][i].length; j++) {
                    adj[j - 1] = G[spId][i][j];
                }
                graphConstruct.g[G[spId][i][0]] = adj;
            }
        }
    }

    // print graph
    // layer print
    function getGraph() public {
        for(uint  spId = 0; spId < graphList.length; spId++){
            Graph storage graph = graphList[spId];
            console.log("current spId", spId);
            for(uint bIndex = 0; bIndex < B.length; bIndex++){
                console.log("current buyerIndex", bIndex);
                uint[] memory test = graph.g[bIndex];
                if(test.length == 1 && test[0] == MAX_INT){
                    continue;
                }
                for(uint priceIndex = 0; priceIndex < 2; priceIndex++){
                    console.log("current node", graph.g[bIndex][priceIndex]);
                }
            }
        }
    }

    function getUndeleteBuyer(uint spId) public returns (uint[] memory buyers) {
        uint buyerCount = 0;
        Graph storage graph = graphList[spId];
        for(uint bIndex = 0; bIndex < B.length; bIndex++){
            if(graph.g[bIndex].length == 1 && graph.g[bIndex][0] == MAX_INT){
                continue;
            }
            buyerCount++;
        }

        uint[] memory buyers = new uint[](buyerCount);
        uint i = 0;
        for(uint bIndex = 0; bIndex < B.length; bIndex++){
            if(graph.g[bIndex].length == 1 && graph.g[bIndex][0] == MAX_INT){
                continue;
            }
            buyers[i++] = B[bIndex];
        }
        return buyers;
    }

    function initGroupingSet() public {
        while (maxSet.length > 0) {
            maxSet.pop();
        }

        while (currSet.length > 0) {
            currSet.pop();
        }
    }

    function getMaxGroup(uint spId) public returns (uint[] memory group) {
        initGroupingSet();
        initGroupingSet();
        uint[] memory buyers = getUndeleteBuyer(spId);
        getMaxCore(0, buyers.length - 1, buyers, spId);
        maxSet.push(1);
        maxSet.push(2);

        return maxSet;
    }

    function getMaxCore(uint currBuyerId, uint maxBuyerId, uint[] memory buyers, uint spId) private {
        for (uint i = currBuyerId; i <= maxBuyerId; i++) {
            console.log("buyerId", buyers[i]);
            console.log("Curr Set");
            for (uint j = 0; j < currSet.length; j++) {
                console.log(currSet[j]);
            }
            console.log(canAdd2Set(graphList[spId], buyers[i]));
            if (canAdd2Set(graphList[spId], buyers[i])) {
                currSet.push(buyers[i]);
                if (currSet.length > maxSet.length) {
                    maxSet = currSet;
                }
                getMaxCore(currBuyerId + 1, maxBuyerId, buyers, spId);
                currSet.pop();
            }
        }
    }


    // canAdd2Set
    // 1 -- 2
    // |    |
    // 3 -- 4
    function canAdd2Set(Graph storage graph, uint target) internal returns(bool){
        for(uint i = 0; i < currSet.length; i++){
            if(containsTarget(target, graph.g[currSet[i]])){
                return false;
            }
        }
        return true;
    }
    function containsTarget(uint target, uint[] memory array) internal returns(bool){
        for(uint i = 0; i < array.length; i++){
            // console.log("current node", array[i]);
            if(array[i] == target){
                return true;
            }
        }
        return false;
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
        while (_visited.length<B.length){
            for (uint k = 0;k<spectrumGraph[cur].length;k++){
                _visited.push(spectrumGraph[cur][k]);
            }
            qsort(_visited);
            uint pt = 0;
            uint prev = 9999999;
            for (uint idx=0;idx <_visited.length;idx++){
                if(_visited[idx]!=prev){
                    prev = _visited[idx];
                    _oneGroup[pt] = _visited[idx];
                    pt++;
                }
            }
            uint prevLen = _visited.length;
            while(prevLen>pt){
                _visited.pop();
                pt++;
            }
            // LibArrayForUint256Utils.distinct(visited);
            if (_visited.length==B.length){
                break;
            }

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

    function deleteUsedFromGraph(uint[][] memory usedList, uint idx) public {
        for (uint i = 0; i < usedList.length; i++) {
            uint[] memory used = usedList[i];
            for (uint j = 0; j < used.length; j++) {
                uint usedId = used[j];
                uint[] memory deleted = new uint[](1);
                deleted[0] = MAX_INT;
                graphList[idx].g[usedId] = deleted;
                delete deleted;
                for (uint k = 0; k < B.length; k++) {
                    // if the key exists
                    if (graphList[idx].g[B[k]].length > 0) {
                        // delete the usedId from the array if exists
                        for (uint m = 0; m < graphList[idx].g[B[k]].length; m++) {
                            if (graphList[idx].g[B[k]][m] == usedId) {
                                // replace with the last element
                                graphList[idx].g[B[k]][m] = graphList[idx].g[B[k]][graphList[idx].g[B[k]].length-1];
                                // then delete the last element
                                delete graphList[idx].g[B[k]][graphList[idx].g[B[k]].length-1];
                                graphList[idx].g[B[k]].pop();
                                break;
                            }
                        }
                    }
                }
            }
        }

        console.log(graphList[0].g[1][0]);
        console.log(graphList[0].g[2].length);
    }

    function group() internal {

    }

    // Allocation & Pricing
    function allocation() internal {


    }

    function clearing() internal{

    }

    mapping(uint => uint[]) spectrumGraph;
    function getOneGroup() public returns (uint[] memory) {
        spectrumGraph[1] = [2,3,4];
        spectrumGraph[2] = [3,4,5];
        uint[] memory res = groupOneGraph(spectrumGraph);
        return res;
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

    function getBuyer(uint id) external view returns (uint) {
        return B[id];
    }

}