pragma solidity ^0.4.22;

contract VotingByToken {
    
    
    uint public totalTokens;
    uint public balanceTokens;
    uint public tokenPrice;
    
    struct voter{
        address account;
        uint tokenBought;
        uint[] tokenUsedCandidate;
    }
    
    
    mapping(address=>voter) voterInfo;
    
    bytes32[] public candidateList;
    mapping(bytes32=>uint) mappingCanidateCount;
    
    address admin;
    
    constructor(bytes32[] candidates , uint _totalTokens,uint _tokenPrice) public {
        candidateList = candidates;
        totalTokens = _totalTokens;
        balanceTokens = _totalTokens;
        tokenPrice = _tokenPrice;
        admin = msg.sender;  // 0x1111   0x3333
    }
    
    function buy() payable public returns(uint) {
        uint tokenNum = msg.value / tokenPrice;
        require(tokenNum<=balanceTokens,"must be less equl than balances");
        voterInfo[msg.sender].account = msg.sender;
        voterInfo[msg.sender].tokenBought += tokenNum;
        balanceTokens -= tokenNum;
        return tokenNum;
    }
    
    function transferToAccount(address _to) public {
        require(admin == msg.sender,"tansfer ether must be manager");
        //require(_to==0x0,"0x0 is error address");
        _to.transfer( address(this).balance );
    }
    
    function tokenSold() view public returns(uint) {
        return totalTokens-balanceTokens;
    }
    
    function indexOfCandidate(bytes32 candidateName) view public returns(uint){
        
        for(uint i=0;i<candidateList.length;i++){
            if(candidateName==candidateList[i]){
                return i;
            }
        }
        
        
        return uint(-1); //false 
    }
    
    
    function VotingFor(bytes32 candidateName,uint voteToken) public {
        uint index = indexOfCandidate(candidateName);
        //require(index != uint(-1),"must be in candidateList");
        if( voterInfo[msg.sender].tokenUsedCandidate.length == 0 ){
            for(uint i=0;i<candidateList.length;i++){
                voterInfo[msg.sender].tokenUsedCandidate.push(0);
            }
        }
        uint outPutToken = totalUsedCandidate(voterInfo[msg.sender].tokenUsedCandidate);
        uint ableTokenCount = voterInfo[msg.sender].tokenBought-outPutToken;
        require(ableTokenCount>=voteToken,"outPutToken must be greate than voteToken");
        mappingCanidateCount[candidateName] += voteToken;
        
        voterInfo[msg.sender].tokenUsedCandidate[index] += voteToken;
    }

    
    function totalUsedCandidate(uint[] tokenUsedCandidate) pure public returns(uint) {
        uint totalUsed = 0 ;
        for(uint i=0;i<=tokenUsedCandidate.length;i++){
            totalUsed += tokenUsedCandidate[i];
        }
        return totalUsed;
    }
    
    function getCandidateCount(bytes32 candidateName) view public returns(uint) {
        uint index = indexOfCandidate(candidateName);
        require(index != uint(-1),"must be in candidateList");
        return mappingCanidateCount[candidateName];
    }
    
    
    function voterDetails(address user) view public returns (uint,uint[]) {
        return (voterInfo[user].tokenBought,voterInfo[user].tokenUsedCandidate);
    }
    

    function() payable public{}
    
}