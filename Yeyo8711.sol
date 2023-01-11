// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

/*
Created by xdream aka Yesh https://www.github.com/joshweb3/
original request: https://discord.com/channels/872804414107312158/956630362342166528/1062103726275440670
*/


/*
Yeyo8711:
Please make me an erc20 contract with the following specifications:
-Total supply 100M ✅
-5% tax each way. ✅
-The taxes will be kept in the contract and given to winners. ✅
-Each buy generates a psudo number which is random ✅
-Each hour on the dot, you request a chainlink random number ✅
-Compare that number to everyones psudo # who bought that hour.
-There are 3 levels of rewards, the closer they are to the winning number the more they get.
-The levels are:
*Jackpot - If they obtain the EXACT same number as the winning number ✅
*2nd place - if they are 50% away from the winning number ✅
*3rd place - everyone more than 50% away from the winning number ✅

The rewards are distributed as follows 
-Jackpot 50%, 2nd - 30%, 3rd- 20%  ✅

*There can be multiple winners in each catergory each hour so make sure to spread the winnings equally inside each bracket ✅

*The odds of hitting the jackpot will be very low, and the odds of getting 3rd place will be high ✅

*If no one hits the jackpot on that hour then the amount gets carried over to the next one therefore increasing the jackpot amount. Same thing for the other brackets. ✅

Utilize Chainlinks Automation to get winners and distribute winnings each hour ✅

Make sure to have getter functions to be able to render all these stats on the front end such as all winners from each interval and the winning number and each address and their psudo number for that interval ✅

Also make it so that the odds can be modified by owner at will, making it harder or easier to hit the jackpot ✅

Please let me know if you can make this

*/

contract YeyoCoin is IERC20, VRFV2WrapperConsumerBase,
    ConfirmedOwner {

    uint maxSupply = 1000000 * 1 ether;
    uint public totalSupply;
    uint pseudoCounter = 1;
    mapping(address => uint) public addressToPseudo;
   
    uint gameCounter;

    uint rarity = 5;

    mapping(uint => gameData) public numToGameData;
    

    struct gameData {
        // put counters because solidity is awesome and i cant push arrays from storage
        uint totalTax;
        uint winningNumber;
        
        uint jackpotCounter;
        uint secondCounter;
        uint thirdCounter;

        uint ownerCounter;
        address[1000] ownersArray;


        address[1000] jackpotWinners;
        address[1000] secondPlaceWinners;
        address[1000] thirdPlaceWinners;
        uint randomNumber;

        uint[1000] jackpotPseudos;
        uint[1000] secondPseudos;
        uint[1000] thirdPseudos;

    }

    //erc20 stuff
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Yeyo Coin";
    string public symbol = "YEYO";
    uint8 public decimals = 18;

    //VRF stuff
  
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    address linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address wrapperAddress = 0x708701a1DfF4f478de54383E49a627eD4852C816;
    //mapping to reference the address in fulfillrandomwords() not really needed maybe add testing stuff later
    mapping(uint256 => address) public s_requestIdToAddress;

    constructor(uint _rarity)
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
        
    {rarity = _rarity;}

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    //5 % taxes each way
    function transfer(address recipient, uint amount) external returns (bool) {

        //calculate 95%
        uint taxedAmount = (amount * 95) / 100;
        //calculate 5%
        uint tax = (amount * 5) / 100;

        balanceOf[msg.sender] -= amount;
        //send recipient net amount
        balanceOf[recipient] += taxedAmount;
        //send tax to contract
        balanceOf[address(this)] += tax;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) public returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    //special functions
    //ges pseudo random number
  function pseudoRandom() private returns (uint) {
        //get different number every time
        pseudoCounter++;
        //hash then conver to uint
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp,pseudoCounter)));  
  }

    //never specified cost
    function mint(uint amount) external {
        //100M cap
        require(totalSupply <= maxSupply);
        require(totalSupply + amount <= maxSupply);

        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        //get pseudo random number
        uint pseudoRand = pseudoCounter / rarity;
        //add msg.sender to owners array in gamedata struct
        numToGameData[gameCounter].ownersArray[numToGameData[gameCounter].ownerCounter];
        //map msg.sender to pseudo random number
        addressToPseudo[msg.sender] = pseudoRand;

        emit Transfer(address(0), msg.sender, amount);


    }

    //requests a real random number
    function requestVRF() internal {
        require(LINK.balanceOf(address(this)) >= 50 ether);
        requestRandomness(callbackGasLimit, requestConfirmations, 1);
    }



    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {

        numToGameData[gameCounter].totalTax = balanceOf[address(this)];

        uint randomNum = (_randomWords[0] % rarity) + 1;
       numToGameData[gameCounter].winningNumber = randomNum;
        uint arrayLength = numToGameData[gameCounter].ownerCounter;
       for(uint8 i = 0; i < arrayLength; i++){

        //jackpot
        if(addressToPseudo[numToGameData[gameCounter].ownersArray[i]] == randomNum){
            numToGameData[gameCounter].jackpotCounter++;
            numToGameData[gameCounter].jackpotWinners[numToGameData[gameCounter].jackpotCounter] = numToGameData[gameCounter].ownersArray[i];
            //sets pseudo number in struct
            numToGameData[gameCounter].jackpotPseudos[numToGameData[gameCounter].jackpotCounter] = addressToPseudo[numToGameData[gameCounter].ownersArray[i]];
        }

        if(addressToPseudo[numToGameData[gameCounter].ownersArray[i]] == ((randomNum * 30)/100)) {
            numToGameData[gameCounter].secondCounter++;
            numToGameData[gameCounter].secondPlaceWinners[numToGameData[gameCounter].secondCounter] = numToGameData[gameCounter].ownersArray[i];
            numToGameData[gameCounter].secondPseudos[numToGameData[gameCounter].secondCounter] = addressToPseudo[numToGameData[gameCounter].ownersArray[i]];
        }

        if(addressToPseudo[numToGameData[gameCounter].ownersArray[i]] > ((randomNum * 50) / 100) ) {
            numToGameData[gameCounter].thirdCounter++;
            numToGameData[gameCounter].thirdPlaceWinners[numToGameData[gameCounter].thirdCounter] = numToGameData[gameCounter].ownersArray[i];
            numToGameData[gameCounter].thirdPseudos[numToGameData[gameCounter].thirdCounter] = addressToPseudo[numToGameData[gameCounter].ownersArray[i]];
        }


        //calculate prize amounts
        uint _jackpotPerUser = jackpotPerUser(numToGameData[gameCounter].totalTax, numToGameData[gameCounter].jackpotCounter);
        uint _secondPerUser = secondPerUser(numToGameData[gameCounter].totalTax, numToGameData[gameCounter].secondCounter);
        uint _thirdPerUser = thirdPerUser(numToGameData[gameCounter].totalTax, numToGameData[gameCounter].thirdCounter);
        
        for(i = 0; i < 0; i++)  {
            balanceOf[numToGameData[gameCounter].jackpotWinners[i]] += _jackpotPerUser;
            balanceOf[numToGameData[gameCounter].secondPlaceWinners[i]] += _secondPerUser;
            balanceOf[numToGameData[gameCounter].thirdPlaceWinners[i]] + _thirdPerUser;
        }

        //create new game struct
        gameData memory game;

        //increment game counter
        gameCounter++;
        //map new game data to a new game id/ counter
        numToGameData[gameCounter] = game;       

    }
    }

    function jackpotPerUser(uint totalTax, uint winnerAmt) public pure returns (uint) {
        
        uint half = (totalTax * 50) / 100;
        //real solidity math time
        int128 answer = int64(uint64(half)) / int64(uint64((winnerAmt)));

        uint _answer = uint(uint128((answer)));
        return _answer;
    }

    function secondPerUser(uint totalTax, uint winnerAmt) public pure returns (uint) {
        
        uint third = (totalTax * 30) / 100;
        //real solidity math time
        int128 answer = int64(uint64(third)) / int64(uint64((winnerAmt)));

        uint _answer = uint(uint128((answer)));
        return _answer;
    }

    function thirdPerUser(uint totalTax, uint winnerAmt) public pure returns (uint) {
        
        uint eighth = (totalTax * 20) / 100;
        //real solidity math time
        int128 answer = int64(uint64(eighth)) / int64(uint64((winnerAmt)));

        uint _answer = uint(uint128((answer)));
        return _answer;
    }




    // called by chainlink every hour
    function everyHourVRFRequest() external {
        requestVRF();
    }

    //frontend stuff

    function getTotalTax(uint _gameId) public view returns (uint) {
        return numToGameData[_gameId].totalTax;
    }

    function getAmtOfGamesPlayed() public view returns (uint) {
        return gameCounter;
    }

    function getNumJackPots(uint _gameId) public view returns (uint) {
        return numToGameData[_gameId].jackpotCounter;
    }

    function getNumSeconds(uint _gameId) public view returns (uint) {
        return numToGameData[_gameId].secondCounter;
    }

    function getNumThirds(uint _gameId) public view returns (uint) {
        return numToGameData[_gameId].thirdCounter;
    }

    function getNumOwners(uint _gameId) public view returns (uint ) {
        return numToGameData[_gameId].ownerCounter;
    }

    function getOwnerByIndex(uint _gameId, uint index) public view returns (address) {
        return numToGameData[_gameId].ownersArray[index];
    }

    function getJackpotPseudo(uint _gameId, uint index) public view returns (uint) {
        return numToGameData[_gameId].jackpotPseudos[index];
    }

    function getSecondPseudo(uint _gameId, uint index) public view returns (uint) {
        return numToGameData[_gameId].secondPseudos[index];
    }

    function getThirdPseudo(uint _gameId, uint index) public view returns (uint) {
        return numToGameData[_gameId].thirdPseudos[index];
    }


    function setDifficulty(uint _rarity) public onlyOwner {
        rarity = _rarity;
    }






}
