import Web3 from "web3"
import contract from 'truffle-contract'
import abi from "../../build/contracts/VotingByToken.json"
import { resolve } from 'path'

$(function(){

    //rpcHost
    const rpcHost = "http://localhost:8545";
    //部署客户端合约
    const VotingByToken = contract(abi)
    const httpProvider = new Web3.providers.HttpProvider(rpcHost)
    const web3 = new Web3(httpProvider)
    //把合约的VotingByToken抽取到前端来
    VotingByToken.setProvider(web3.currentProvider)

    //dom映射关系
    const mappingCandidates = {
        zhangsan : "candidate-1",
        lisi : "candidate-2",
        wangwu : "candidate-3"
    }
    //获取候选人列表
    const candidateList = Object.keys(mappingCandidates)
    //建立候选人索引
    const candidatesIndex = ["zhangsan","lisi","wangwu"]

    //token可以购买的剩余量
    let balanceTokens = 0
    //token的单价
    let tokenPrice = 0 
    //售出的总量
    let tokenSold  = 0
    //获取所有的用户
    let accounts = [];

    //渲染区块链的数据到前端
    async function renderFromBlockChain(){
        //部署合约
        const instance = await VotingByToken.deployed()
        //渲染候选人的信息
        for(let item of candidateList){
            const count = await instance.getCandidateCount( web3.utils.toHex(item) )
           
            $("#" + mappingCandidates[item]).html(count.toString(10)) 
        }
       
        //渲染发行总量
        const totalTokens = await instance.totalTokens()
        $("#totalTokens").html( totalTokens.toString(10) ) 
        //发行可购买剩余量
        balanceTokens = await instance.balanceTokens()
        $("#balanceTokens").html(balanceTokens.toString(10) )
        //购买单价
        tokenPrice = await instance.tokenPrice()
        $("#tokenPrePrice").html( web3.utils.fromWei(tokenPrice.toString(10)) + " ether" )
        //一共卖出了多少token
        tokenSold = await instance.tokenSold()
        //tokenSold = await instance.tokensSold()
        $("#tokensSold").html(tokenSold.toString(10)) 
        //获取一共有多少个用户
        accounts = await web3.eth.getAccounts() 
        $("#eosAddress").val( accounts[0] ) 
    }

    renderFromBlockChain()

    //购买token
    $("#buyBtn").on("click",function(){

        async function buyToken(){
            //部署合约
            const instance = await VotingByToken.deployed()
            //获取要买多少个token
            //注意使用Number 变为数字类型
            const _tokenNum = Number( $("#tokenBuyNumber").val() )
            //注意转换为10进制
            const _price = tokenPrice.toString(10)
            let weiTotal = 0 //表示一共要花费多少wei
            if( _tokenNum>0 && _price>0 ) {
                weiTotal = _tokenNum * _price 
                //把钱打入合约地址中
                const buyTx = {from:accounts[0],value:weiTotal,to:instance.address}
                await instance.buy( buyTx ) 
                //如果购买成功需要更新剩余的token可购买总量和售出token的总量
                balanceTokens = await instance.balanceTokens()
                $("#balanceTokens").html(balanceTokens.toString(10) )
                tokenSold = await instance.tokenSold()
               
                $("#tokensSold").html(tokenSold.toString(10)) 
                layer.msg("购买token成功~！！")
                //隐藏投票详情
                $("#tokensDetails").hide("slow")
            }

        }
        buyToken()
    })

    //实现基于token的投票
    $("#voteBtn").on("click",function(){
        //获取候选人的姓名
        const cname = $("#candidateName").val() 
        //获取投票token数
        const voteTokenCount = $("#voteInTokens").val()
        
        async function VotingFor(){
            //部署合约
            const instance = await VotingByToken.deployed()  
            //投票需要使用交易消耗
            const voteTx = {from:accounts[0]} 

            //投票
            await instance.VotingFor(web3.utils.toHex(cname),voteTokenCount,voteTx)
            // 如果投票成功获取对应候选人现在票数是多少,然后重新渲染
            const count = await instance.getCandidateCount(web3.utils.toHex(cname))
            $("#" + mappingCandidates[cname]).html(count.toString(10))
            layer.msg("感谢您为" + cname + "投了1票")
            //隐藏投票详情
            $("#tokensDetails").hide("slow")
        }


        VotingFor() 
    })


    $("#btnDetails").on("click",function(){

        //获取账号信息
        const accountAdr = $("#eosAddress").val() 
        async function Details() {
            //部署合约
            const instance = await VotingByToken.deployed() 
            //获取当前账号地址的token详情
            const res = await instance.voterDetails(accountAdr,{from:accounts[0]})
            console.log(res)
            //这个获取是使用以太坊特有的结构 可以通过打印res结构分别获得
            //token购买的总额
            const buyTokenTotal = res[0].words[0]
            //消耗的详情
            const tokenOuputs = res[1]
            let tokenTotalOut = 0 
            for(let item of tokenOuputs) {
                let out = item.words[0]
                tokenTotalOut += out 
            }
            //剩余可以投票的token
            const balanceToken = buyTokenTotal - tokenTotalOut
            $("#buyTokenTotal").html(buyTokenTotal)
            $("#voterEOS").html(accountAdr) 
            $("#ableTotalToken").html(balanceToken)
            //清空一下 否则会出现详情追加在后面
            $("#tokenDetails>tbody").html("")
            //渲染消耗token的详情
            for(let i=0;i<tokenOuputs.length;i++){
                
                $("#tokenDetails>tbody").append(
                    `
                    <tr>
                        <td>
                            ${candidatesIndex[i]} 
                        </td>

                        <td>
                            ${tokenOuputs[i].words[0]}
                        </td>
                    <tr>
                    `
                )
            }
            //显示结果 之前设置了隐藏 慢显示效果
            $("#tokensDetails").show("slow") 
        }

        Details() 
    })

    

})
