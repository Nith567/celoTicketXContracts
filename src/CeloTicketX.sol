// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {IMentoRouter} from "./interfaces/IMentoRouter.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./EventTicketNFT.sol";

interface IBroker {
    function swapIn(
        address exchangeProvider,
        bytes32 exchangeId,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin
    ) external returns (uint256 amountOut);
}

interface IMentoOracle {
    function medianRate(address rateFeedId) external view returns (uint256, uint256);
}

contract CeloTicketX {
    address public constant MENTO_ROUTER =0xBE729350F8CdFC19DB6866e8579841188eE57f67;
    address public constant BI_POOL_MANAGER=0x22d9db95E6Ae61c104A7B6F6C78D7993B94ec901;
    address public constant BROKER = 0x777A8255cA72412f0d706dc03C9D1987306B4CaD;
    address public constant CUSD = 0x765DE816845861e75A25fCA122bb6898B8B1282a;
    address public constant KES = 0x456a3D042C0DbD3db53D5489e98dFb038553B0d0;
    address public constant GHS = 0xfAeA5F3404bbA20D3cc2f8C4B0A888F55a3c7313;
    address public constant JPY= 0xc45eCF20f3CD864B32D9794d6f76814aE8892e20;
    address public constant AUD=0x7175504C455076F15c04A2F90a8e352281F492F9;
    address public constant CAD=0xff4Ab19391af240c311c54200a492233052B6325;
    address public constant ZAR=0x4c35853A3B4e647fD266f4de678dCc8fEC410BF6;
    address public constant GBP=0xCCF663b1fF11028f0b19058d0f7B674004a40746;
    address public constant CHF=0xb55a79F398E759E43C95b979163f30eC87Ee131D;
    address public constant NGN=0xE2702Bd97ee33c88c8f6f92DA3B733608aa76F71;
    address public constant COP = 0x8A567e2aE79CA692Bd748aB832081C45de4041eA;
    address public constant USDT=0x48065fbBE25f71C9282ddf5e1cD6D6A887483D5e;
    
    // Mento Oracle for rate calculations on CUSD mainnet
    IMentoOracle public constant ORACLE = IMentoOracle(0xefB84935239dAcdecF7c5bA76d8dE40b077B7b33);
    
    EventTicketNFT public nftMinter;
  uint256 public eventCounter;
    constructor() {
        nftMinter = new EventTicketNFT(address(this));
        eventCounter = 1;
    }

    struct EventSpot {
        address creator;
        string eventName;
        string eventDetails;
        address stablecoinAddress; // fixed typo: lowercase 's'
        uint256 pricePerPerson;
        string ipfsImageUrl;
        bool isActive;
    }

  
    mapping(uint256 => EventSpot) public eventSpots;

    event EventCreated(uint256 indexed eventId, string eventName, address creator, uint256 pricePerPerson);
    event TicketBought(uint256 indexed eventId, address buyer, uint256 quantity, address tokenUsed, uint256 amountPaid);

    function createEvent(
        string memory _eventName,
        string memory _eventDetails,
        uint256 _pricePerPerson,
        string memory _ipfsImageUrl
    ) external returns (uint256){
        // Only allow CUSD as the stablecoin
        require(CUSD != address(0), "CUSD address not set");
        uint256 eventId = eventCounter;
        eventSpots[eventId] = EventSpot({
            creator: msg.sender,
            eventName: _eventName,
            eventDetails: _eventDetails,
            stablecoinAddress: CUSD, // always CUSD
            pricePerPerson: _pricePerPerson,
            ipfsImageUrl: _ipfsImageUrl,
            isActive: true
        });
        emit EventCreated(eventId, _eventName, msg.sender, _pricePerPerson);
             eventCounter++;
        return eventCounter;
   
    }
    
    // Calculate cross rate between two stablecoins using CUSD as the bridge
    function getCrossRate(address tokenA, address tokenB) public view returns (uint256) {
        // Get rates for both tokens against CUSD
        (uint256 rateA, ) = ORACLE.medianRate(tokenA);
        (uint256 rateB, ) = ORACLE.medianRate(tokenB);
        
        // Calculate cross rate with high precision
        uint256 precision = 1e18;
        
        // To get tokenA/tokenB rate, we divide rateA by rateB
        return (rateA * precision) / rateB;
    }
    
    // Convert an amount from one token to another using the cross rate
    function convertAmount(address fromToken, address toToken, uint256 amount) public view returns (uint256) {
        if (fromToken == toToken) {
            return amount;
        }
        
        uint256 crossRate = getCrossRate(fromToken, toToken);
        uint256 precision = 1e18;
        
        // Convert the amount using the cross rate
        return (amount * crossRate) / precision;
    }

    function buyTicket(uint256 _eventId, uint256 _quantity, address _paymentToken) external {
        EventSpot memory spot = eventSpots[_eventId];
        require(spot.isActive, "Event not active");
        require(_quantity > 0, "Invalid quantity");

        uint256 basePrice = spot.pricePerPerson * _quantity;
        uint256 amountToPayInPaymentToken;

        if (_paymentToken == spot.stablecoinAddress) {
            // Accept CUSD only
            amountToPayInPaymentToken = basePrice;
            IERC20Metadata(_paymentToken).transferFrom(msg.sender, spot.creator, amountToPayInPaymentToken);
        } else {
            // Only allow these tokens for payment
            require(
                _paymentToken == USDT ||
                _paymentToken == KES ||
                _paymentToken == COP ||
                _paymentToken == GHS ||
                _paymentToken == GBP ||
                _paymentToken == AUD ||
                _paymentToken == CAD ||
                _paymentToken == ZAR ||
                _paymentToken == CHF ||
                _paymentToken == JPY ||
                _paymentToken == NGN,
                "Payment token not supported"
            );
            amountToPayInPaymentToken = convertAmount(spot.stablecoinAddress, _paymentToken, basePrice);
            IERC20Metadata(_paymentToken).transferFrom(msg.sender, address(this), amountToPayInPaymentToken);
            IERC20Metadata(_paymentToken).approve(BROKER, amountToPayInPaymentToken);
            bytes32 exId = keccak256(abi.encodePacked("cUSD", IERC20Metadata(_paymentToken).symbol(), "ConstantSum"));
            uint256 usdcOut = IBroker(BROKER).swapIn(
                BI_POOL_MANAGER,
                exId,
                _paymentToken,
                CUSD,
                amountToPayInPaymentToken,
                0
            );
            IERC20Metadata(CUSD).transfer(spot.creator, usdcOut);
        }

 
      
            //     string memory tokenSymbol = IERC20Metadata(_paymentToken).symbol();
            //     string memory stablecoinSymbol = IERC20Metadata(spot.stablecoinAddress).symbol();
                
            //     bytes32 ex1 = keccak256(abi.encodePacked("cUSD", tokenSymbol, "ConstantSum"));
            //     bytes32 ex2 = keccak256(abi.encodePacked("cUSD", stablecoinSymbol, "ConstantSum"));

            //     IMentoRouter.Step[] memory path = new IMentoRouter.Step[](2);
            //     path[0] = IMentoRouter.Step({exchangeProvider: BI_POOL_MANAGER, exchangeId: ex1, assetIn: _paymentToken, assetOut: CUSD});
            //     path[1] = IMentoRouter.Step({exchangeProvider: BI_POOL_MANAGER, exchangeId: ex2, assetIn: CUSD, assetOut: spot.stablecoinAddress});

            //     IERC20Metadata(_paymentToken).approve(MENTO_ROUTER, amountToPayInPaymentToken);

            //     IMentoRouter(MENTO_ROUTER).swapExactTokensForTokens(amountToPayInPaymentToken, 0, path)
        nftMinter.mintTicket(msg.sender, spot.ipfsImageUrl, spot.eventName, _eventId, _quantity);
        emit TicketBought(_eventId, msg.sender, _quantity, _paymentToken, amountToPayInPaymentToken);
    }

    function deactivateEvent(uint256 _eventId) external {
        require(eventSpots[_eventId].creator == msg.sender, "Not event owner");
        eventSpots[_eventId].isActive = false;
    }

    function getAllEvents() external view returns (EventSpot[] memory) {
        uint256 total = eventCounter - 1;
        EventSpot[] memory all = new EventSpot[](total);
        for (uint256 i = 1; i <= total; i++) {
            all[i - 1] = eventSpots[i];
        }
        return all;
    }

    function getEvent(uint256 eventId) external view returns (
        address creator,
        string memory eventName,
        string memory eventDetails,
        address stablecoinAddress,
        uint256 pricePerPerson,
        string memory ipfsImageUrl,
        bool isActive
    ) {
        EventSpot memory spot = eventSpots[eventId];
        return (
            spot.creator,
            spot.eventName,
            spot.eventDetails,
            spot.stablecoinAddress,
            spot.pricePerPerson,
            spot.ipfsImageUrl,
            spot.isActive
        );
    }
}