![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Network](https://img.shields.io/badge/Network-Ethereum-purple)

# PropertyToken - Tokenização de Imóveis com Blockchain

**Projeto:** SSC0958 - Blockchain e Criptomoedas  
**Aluno:** Matheus Giraldi Alvarenga - 12543669  

---

## Sobre o Projeto

Sistema de tokenização de imóveis utilizando **Ethereum** e padrão **ERC-20**, permitindo o fracionamento de propriedades e distribuição automática de aluguéis através de smart contracts.

## Tecnologias Utilizadas

- **Blockchain:** Ethereum (Sepolia Testnet)
- **Linguagem:** Solidity ^0.8.20
- **Padrão:** ERC-20 (OpenZeppelin)
- **Ferramentas:** Remix IDE
- **Segurança:** ReentrancyGuard, Ownable

---

## Funcionalidades

### Para o Proprietário (Owner)
- Deploy do contrato representando o imóvel
- Emissão de tokens ERC-20 (frações do imóvel)
- Depósito de aluguéis em ETH
- Distribuição automática proporcional aos holders

### Para os Investidores
- Compra/venda de tokens (frações do imóvel)
- Consulta de aluguéis pendentes
- Saque de aluguéis acumulados
- Transferência de tokens entre investidores

### Funções Principais
```solidity
// Depositar aluguel (Owner)
function depositRent() external payable onlyOwner

// Consultar aluguel pendente
function calculatePendingRent(address investor) public view returns (uint256)

// Sacar aluguel
function withdrawRent() external nonReentrant

// Informações do investidor
function getInvestorInfo(address investor) external view returns (...)
```

---

## Segurança

### Proteções Implementadas

- **ReentrancyGuard:** Proteção contra ataques de reentrancy
- **Checks-Effects-Interactions:** Padrão para prevenir vulnerabilidades
- **OpenZeppelin Libraries:** Bibliotecas auditadas e batalha-testadas
- **Ownable:** Controle de acesso para funções administrativas
- **Validações robustas:** Múltiplos require() em funções críticas

### Auditoria

- Código baseado em padrões OpenZeppelin (auditado)
- Seguindo best practices da comunidade Ethereum
- Testado no Remix VM e Sepolia Testnet

## Justificativas Técnicas

### Por que Ethereum?

1. **Ecossistema dominante em RWA:** 90%+ dos projetos sérios
2. **Maturidade:** 10 anos sem paradas (99.99% uptime)
3. **Descentralização:** 1M+ validadores
4. **Infraestrutura completa:** Exchanges, wallets, ferramentas
5. **Clareza regulatória:** ETH não é security (SEC)

### Por que ERC-20?

1. **Padrão universal:** Reconhecido por 100+ exchanges automaticamente
2. **Liquidez garantida:** Funciona com Uniswap, Aave, Compound
3. **Batalha-testado:** Trilhões de dólares transacionados
4. **Adequação perfeita:** Tokens fungíveis, divisíveis, transferíveis
5. **Casos reais:** Ondo Finance ($600M), RealT (1000+ imóveis)


## Licença

Este projeto está licenciado sob a **MIT License** - veja o arquivo [LICENSE](LICENSE) para detalhes.
