// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PropertyToken is ERC20, Ownable, ReentrancyGuard {
    
    // ========== ESTRUTURAS DE DADOS ==========
    
    struct RentDistribution {
        uint256 amount;
        uint256 timestamp;
        uint256 totalSupply;
    }
    
    struct PropertyInfo {
        string propertyAddress;
        uint256 propertyValue;
        uint256 totalTokens;
        string documentHash;
    }
    
    // ========== VARIÁVEIS DE ESTADO ==========
    
    PropertyInfo public propertyInfo;
    uint256 public totalRentAvailable;
    uint256 public totalRentDistributed;
    uint256 public distributionCount;
    
    mapping(address => uint256) public pendingRentWithdrawals;
    mapping(address => uint256) public totalWithdrawnByInvestor;
    mapping(uint256 => RentDistribution) public rentDistributionHistory;
    mapping(address => uint256) public lastProcessedDistribution;
    
    // ========== EVENTOS ==========
    
    event RentDeposited(uint256 indexed distributionId, uint256 amount, uint256 timestamp);
    event RentWithdrawn(address indexed investor, uint256 amount, uint256 timestamp);
    event PropertyInfoUpdated(string propertyAddress, uint256 propertyValue, string documentHash);
    event TokensMinted(address indexed to, uint256 amount);
    
    // ========== MODIFICADORES ==========
    
    modifier hasTokens(address investor) {
        require(balanceOf(investor) > 0, "Investor has no tokens");
        _;
    }
    
    // ========== CONSTRUTOR ==========
    
    /**
     * @dev Inicializa o contrato
     * @param name Nome do token
     * @param symbol Símbolo
     * @param initialSupply Total de tokens
     * @param _propertyAddress Endereço físico do imóvel
     * @param _propertyValue Valor do imóvel
     * @param _documentHash Hash IPFS da documentação
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        string memory _propertyAddress,
        uint256 _propertyValue,
        string memory _documentHash
    ) ERC20(name, symbol) Ownable(msg.sender) {
        require(initialSupply > 0, "Initial supply must be > 0");
        require(_propertyValue > 0, "Property value must be > 0");
        
        _mint(msg.sender, initialSupply);
        
        propertyInfo = PropertyInfo({
            propertyAddress: _propertyAddress,
            propertyValue: _propertyValue,
            totalTokens: initialSupply,
            documentHash: _documentHash
        });
        
        emit TokensMinted(msg.sender, initialSupply);
        emit PropertyInfoUpdated(_propertyAddress, _propertyValue, _documentHash);
    }
    
    // ========== FUNÇÕES PRINCIPAIS ==========
    
    /**
     * @dev Owner deposita aluguel no contrato
     * ETH
     */
    function depositRent() external payable onlyOwner {
        require(msg.value > 0, "Rent must be > 0");
        
        distributionCount++;
        totalRentAvailable += msg.value;
        
        rentDistributionHistory[distributionCount] = RentDistribution({
            amount: msg.value,
            timestamp: block.timestamp,
            totalSupply: totalSupply()
        });
        
        emit RentDeposited(distributionCount, msg.value, block.timestamp);
    }
    
    /**
     * @dev Calcula aluguel pendente de um investidor
     * @param investor Endereço do investidor
     * @return Valor pendente em wei
     */
    function calculatePendingRent(address investor) public view returns (uint256) {
        if (balanceOf(investor) == 0) {
            return pendingRentWithdrawals[investor];
        }
        
        uint256 pending = pendingRentWithdrawals[investor];
        uint256 lastProcessed = lastProcessedDistribution[investor];
        
        for (uint256 i = lastProcessed + 1; i <= distributionCount; i++) {
            RentDistribution memory dist = rentDistributionHistory[i];
            uint256 investorShare = (balanceOf(investor) * dist.amount) / dist.totalSupply;
            pending += investorShare;
        }
        
        return pending;
    }
    
    /**
     * @dev Atualiza aluguéis pendentes
     */
    function updatePendingRent(address investor) internal {
        if (lastProcessedDistribution[investor] == distributionCount) {
            return;
        }
        
        uint256 pending = 0;
        
        for (uint256 i = lastProcessedDistribution[investor] + 1; i <= distributionCount; i++) {
            RentDistribution memory dist = rentDistributionHistory[i];
            uint256 investorShare = (balanceOf(investor) * dist.amount) / dist.totalSupply;
            pending += investorShare;
        }
        
        pendingRentWithdrawals[investor] += pending;
        lastProcessedDistribution[investor] = distributionCount;
    }
    
    /**
     * @dev Investidor saca seus aluguéis acumulados
     * Qualquer investidor com tokens pode chamar esta função
     */
    function withdrawRent() external nonReentrant hasTokens(msg.sender) {
        updatePendingRent(msg.sender);
        
        uint256 amount = pendingRentWithdrawals[msg.sender];
        require(amount > 0, "No rent available");
        require(address(this).balance >= amount, "Insufficient balance");
        
        pendingRentWithdrawals[msg.sender] = 0;
        totalRentAvailable -= amount;
        totalRentDistributed += amount;
        totalWithdrawnByInvestor[msg.sender] += amount;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit RentWithdrawn(msg.sender, amount, block.timestamp);
    }
    
    // ========== FUNÇÕES DE CONSULTA ==========
    
    /**
     * @dev Informações completas de um investidor
     * @param investor Endereço para consultar
     * @return tokens Quantidade de tokens
     * @return ownership Percentual de propriedade (base 10000 = 100%)
     * @return pendingRent Aluguel disponível para saque
     * @return totalWithdrawn Total já sacado
     */
    function getInvestorInfo(address investor) 
        external 
        view 
        returns (
            uint256 tokens,
            uint256 ownership,
            uint256 pendingRent,
            uint256 totalWithdrawn
        ) 
    {
        tokens = balanceOf(investor);
        ownership = totalSupply() > 0 ? (tokens * 10000) / totalSupply() : 0;
        pendingRent = calculatePendingRent(investor);
        totalWithdrawn = totalWithdrawnByInvestor[investor];
    }
    
    /**
     * @dev Estatísticas gerais do contrato
     */
    function getContractStats() 
        external 
        view 
        returns (
            uint256 _totalSupply,
            uint256 _totalRentDeposited,
            uint256 _totalRentDistributed,
            uint256 _totalRentAvailable,
            uint256 _distributionCount,
            uint256 _contractBalance
        ) 
    {
        uint256 totalDeposited = 0;
        for (uint256 i = 1; i <= distributionCount; i++) {
            totalDeposited += rentDistributionHistory[i].amount;
        }
        
        return (
            totalSupply(),
            totalDeposited,
            totalRentDistributed,
            totalRentAvailable,
            distributionCount,
            address(this).balance
        );
    }
    
    /**
     * @dev Retorna uma distribuição específica
     */
    function getDistribution(uint256 index) 
        external 
        view 
        returns (
            uint256 amount,
            uint256 timestamp,
            uint256 totalSupply_
        ) 
    {
        require(index > 0 && index <= distributionCount, "Invalid index");
        RentDistribution memory dist = rentDistributionHistory[index];
        return (dist.amount, dist.timestamp, dist.totalSupply);
    }
    
    // ========== FUNÇÕES ADMINISTRATIVAS ==========
    
    /**
     * @dev Atualiza informações do imóvel
     */
    function updatePropertyInfo(
        string memory _propertyAddress,
        uint256 _propertyValue,
        string memory _documentHash
    ) external onlyOwner {
        propertyInfo.propertyAddress = _propertyAddress;
        propertyInfo.propertyValue = _propertyValue;
        propertyInfo.documentHash = _documentHash;
        
        emit PropertyInfoUpdated(_propertyAddress, _propertyValue, _documentHash);
    }
    
    /**
     * @dev Emite novos tokens (casos especiais)
     */
    function mintTokens(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Amount must be > 0");
        
        _mint(to, amount);
        propertyInfo.totalTokens += amount;
        
        emit TokensMinted(to, amount);
    }
    
    /**
     * @dev Override transfer para atualizar aluguéis
     */
    function transfer(address to, uint256 amount) 
        public 
        virtual 
        override 
        returns (bool) 
    {
        updatePendingRent(msg.sender);
        updatePendingRent(to);
        return super.transfer(to, amount);
    }
    
    /**
     * @dev Override transferFrom para atualizar aluguéis
     */
    function transferFrom(address from, address to, uint256 amount) 
        public 
        virtual 
        override 
        returns (bool) 
    {
        updatePendingRent(from);
        updatePendingRent(to);
        return super.transferFrom(from, to, amount);
    }
    
    /**
     * @dev Saldo de ETH do contrato
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Rejeita ETH enviado diretamente
     */
    receive() external payable {
        revert("Use depositRent() function");
    }
}