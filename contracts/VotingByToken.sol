pragma solidity ^0.4.22;

contract VotingByToken {
    
    //发行总token数 剩余token数 token的价格
    uint public totalTokens;
    uint public balanceTokens;
    uint public tokenPrice;

//    投票人:账户,投票人买了多少token 投票人的的对应关系(索引对应候选人名)
    struct voter{
        address account;
        uint tokenBought;
        //候选者索引 对应 候选人名字 比如候选人索引0 投了8票;候选人索引1 投了29票;
        uint[] tokenUsedCandidate;
    }
    
    //根据地址找到投票人信息
    mapping(address=>voter) voterInfo;
    //候选人列表
    bytes32[] public candidateList;
    //候选人(姓名,bytes32格式)对应的票数
    mapping(bytes32=>uint) mappingCanidateCount;
    //合约的部署者,管理者,可以从合约中提取
    address admin;

    //初始化
    constructor(bytes32[] candidates , uint _totalTokens,uint _tokenPrice) public {
        candidateList = candidates;
        totalTokens = _totalTokens;
        balanceTokens = _totalTokens;
        tokenPrice = _tokenPrice;
        admin = msg.sender;  // 0x1111   0x3333
    }

    //其他用户购买token
    //必须使用 payable 函数,需要扣金额
    //返回购买的数量
    //这个payable函数会扣除发送以太坊金额见调用的案例如下:
    //const buyTx = {from:accounts[0],value:weiTotal,to:instance.address}
    function buy() payable public returns(uint) {
        //操作者msg 使用的以太坊数量value token的单价tokenPrice
        uint tokenNum = msg.value / tokenPrice;
        require(tokenNum<=balanceTokens,"must be less equl than balances");
        voterInfo[msg.sender].account = msg.sender;
        voterInfo[msg.sender].tokenBought += tokenNum;
        balanceTokens -= tokenNum;
        return tokenNum;
    }
    //合约中约 可以被转移,转到某个账号
    function transferToAccount(address _to) public {
        //(管理员权限)
        require(admin == msg.sender,"tansfer ether must be manager");
        //require(_to==0x0,"0x0 is error address");
        //地址的越转到 _to账户里面
        _to.transfer( address(this).balance );
    }

    //查询售出的总量 =总量-剩余的数量
    //view表示查询
    function tokenSold() view public returns(uint) {
        return totalTokens-balanceTokens;
    }

    //根据候选人名 返回索引 (不存在返回-1)
    function indexOfCandidate(bytes32 candidateName) view public returns(uint){
        
        for(uint i=0;i<candidateList.length;i++){
            if(candidateName==candidateList[i]){
                return i;
            }
        }
        
        
        return uint(-1); //false 
    }
    
    //进行投票
    //参数:投给谁 投的票数
    function VotingFor(bytes32 candidateName,uint voteToken) public {
        //确保投票人在候选人列表中
        uint index = indexOfCandidate(candidateName);
        require(index != uint(-1),"must be in candidateList");
        if( voterInfo[msg.sender].tokenUsedCandidate.length == 0 ){
            for(uint i=0;i<candidateList.length;i++){
                //将每个投票者的候选人列表都是0
                voterInfo[msg.sender].tokenUsedCandidate.push(0);
            }
        }

        //已经投了票的总数
        uint outPutToken = totalUsedCandidate(voterInfo[msg.sender].tokenUsedCandidate);
        //可投票数 = 买的票数 - 已经投了票的总数
        uint ableTokenCount = voterInfo[msg.sender].tokenBought-outPutToken;
        require(ableTokenCount>=voteToken,"outPutToken must be greate than voteToken");
        //候选人票数
        mappingCanidateCount[candidateName] += voteToken;
        //投票者的投票索引中加上投票票数
        voterInfo[msg.sender].tokenUsedCandidate[index] += voteToken;
    }
    
    //投票人投票之前 已经消耗的总票数
    //pure 比view更严格,不能改也不能读
    function totalUsedCandidate(uint[] tokenUsedCandidate) pure public returns(uint) {
        uint totalUsed = 0 ;
        for(uint i=0;i<=tokenUsedCandidate.length;i++){
            totalUsed += tokenUsedCandidate[i];
        }
        return totalUsed;
    }

    //获得候选人获得的票数
    function getCandidateCount(bytes32 candidateName) view public returns(uint) {
        uint index = indexOfCandidate(candidateName);
        require(index != uint(-1),"must be in candidateList");
        return mappingCanidateCount[candidateName];
    }
    
    //获取投票人的投票信息
    //solidly不方便获取结构提
    function voterDetails(address user) view public returns (uint,uint[]) {
        return (voterInfo[user].tokenBought,voterInfo[user].tokenUsedCandidate);
    }
    
    //需要声明一个payable 转账函数
    function() payable public{}
    
}