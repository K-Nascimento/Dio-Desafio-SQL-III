
---

## 2. script.sql

```sql
-- =================================================================
-- SCRIPT DE CRIAÇÃO DO BANCO DE DADOS (DDL) 
-- E CARGA DE DADOS DE TESTE (DML)
-- =================================================================

DROP DATABASE IF EXISTS ecommerce_analytics;
CREATE DATABASE ecommerce_analytics;
USE ecommerce_analytics;

-- -----------------------------------------------------------------
-- 1. TABELAS DE CADASTRO BASE
-- -----------------------------------------------------------------
CREATE TABLE Cliente (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    tipo_cliente ENUM('PF', 'PJ') NOT NULL,
    nome_razao_social VARCHAR(100) NOT NULL,
    cpf CHAR(11) UNIQUE,
    cnpj CHAR(14) UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    CONSTRAINT chk_documento CHECK (
        (tipo_cliente = 'PF' AND cpf IS NOT NULL AND cnpj IS NULL) OR
        (tipo_cliente = 'PJ' AND cnpj IS NOT NULL AND cpf IS NULL)
    )
) ENGINE=InnoDB;

CREATE TABLE FormaPagamento (
    id_forma INT AUTO_INCREMENT PRIMARY KEY,
    descricao VARCHAR(50) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE Cliente_Pagamento (
    id_cliente INT NOT NULL,
    id_forma INT NOT NULL,
    PRIMARY KEY (id_cliente, id_forma),
    FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente) ON DELETE CASCADE,
    FOREIGN KEY (id_forma) REFERENCES FormaPagamento(id_forma) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------
-- 2. TABELAS DE PRODUTOS, FORNECEDORES, VENDEDORES E ESTOQUES
-- -----------------------------------------------------------------
CREATE TABLE Produto (
    id_produto INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE Fornecedor (
    id_fornecedor INT AUTO_INCREMENT PRIMARY KEY,
    nome_razao_social VARCHAR(100) NOT NULL,
    cnpj CHAR(14) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE Vendedor (
    id_vendedor INT AUTO_INCREMENT PRIMARY KEY,
    nome_fantasia VARCHAR(100) NOT NULL,
    cnpj_cpf VARCHAR(14) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE Estoque (
    id_estoque INT AUTO_INCREMENT PRIMARY KEY,
    localizacao VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

-- Tabelas de associação
CREATE TABLE Produto_Vendedor (
    id_produto INT NOT NULL,
    id_vendedor INT NOT NULL,
    quantidade_disponivel INT NOT NULL DEFAULT 0,
    PRIMARY KEY (id_produto, id_vendedor),
    FOREIGN KEY (id_produto) REFERENCES Produto(id_produto) ON DELETE CASCADE,
    FOREIGN KEY (id_vendedor) REFERENCES Vendedor(id_vendedor) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Produto_Fornecedor (
    id_produto INT NOT NULL,
    id_fornecedor INT NOT NULL,
    PRIMARY KEY (id_produto, id_fornecedor),
    FOREIGN KEY (id_produto) REFERENCES Produto(id_produto) ON DELETE CASCADE,
    FOREIGN KEY (id_fornecedor) REFERENCES Fornecedor(id_fornecedor) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Produto_Estoque (
    id_produto INT NOT NULL,
    id_estoque INT NOT NULL,
    quantidade INT NOT NULL DEFAULT 0,
    PRIMARY KEY (id_produto, id_estoque),
    FOREIGN KEY (id_produto) REFERENCES Produto(id_produto) ON DELETE CASCADE,
    FOREIGN KEY (id_estoque) REFERENCES Estoque(id_estoque) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------
-- 3. TABELAS TRANSACIONAIS (PEDIDOS, ITENS E ENTREGAS)
-- -----------------------------------------------------------------
CREATE TABLE Pedido (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_forma_pagamento INT NOT NULL,
    data_emissao DATETIME DEFAULT CURRENT_TIMESTAMP,
    status_pedido ENUM('Processando', 'Aprovado', 'Enviado', 'Entregue', 'Cancelado') DEFAULT 'Processando',
    valor_total DECIMAL(10,2) DEFAULT 0.00,
    FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente) ON DELETE RESTRICT,
    FOREIGN KEY (id_forma_pagamento) REFERENCES FormaPagamento(id_forma) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE Item_Pedido (
    id_pedido INT NOT NULL,
    id_produto INT NOT NULL,
    quantidade INT NOT NULL DEFAULT 1,
    preco_unitario DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id_pedido, id_produto),
    FOREIGN KEY (id_pedido) REFERENCES Pedido(id_pedido) ON DELETE CASCADE,
    FOREIGN KEY (id_produto) REFERENCES Produto(id_produto) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE Entrega (
    id_entrega INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL UNIQUE,
    codigo_rastreio VARCHAR(50) NOT NULL UNIQUE,
    status_entrega ENUM('Separação', 'Em Trânsito', 'Concluído', 'Extraviado') DEFAULT 'Separação',
    data_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_pedido) REFERENCES Pedido(id_pedido) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------
-- 4. TRIGGER PARA ATUALIZAÇÃO AUTOMÁTICA DO VALOR TOTAL DO PEDIDO
-- -----------------------------------------------------------------
DELIMITER $$
CREATE TRIGGER tg_atualiza_faturamento_pedido
AFTER INSERT ON Item_Pedido
FOR EACH ROW
BEGIN
    UPDATE Pedido
    SET valor_total = (
        SELECT SUM(quantidade * preco_unitario)
        FROM Item_Pedido
        WHERE id_pedido = NEW.id_pedido
    )
    WHERE id_pedido = NEW.id_pedido;
END$$
DELIMITER ;

-- =================================================================
-- 5. CARGA DE DADOS (MASSA DE TESTE)
-- =================================================================
INSERT INTO FormaPagamento (descricao) VALUES 
('Cartão de Crédito Corporate'), 
('Pix Transferência'), 
('Boleto Faturado 30d');

-- Clientes (PF e PJ)
INSERT INTO Cliente (tipo_cliente, nome_razao_social, cpf, cnpj, email) VALUES
('PF', 'André Mendoza', '12345678901', NULL, 'andre.mendoza@email.com'),
('PJ', 'Tech Solutions Infra S.A.', NULL, '11222333000181', 'suprimentos@techsolutions.com.br');

-- Formas de pagamento por cliente
INSERT INTO Cliente_Pagamento (id_cliente, id_forma) VALUES 
(1, 1),   -- André: cartão corporate
(1, 2),   -- André: pix
(2, 3);   -- Tech Solutions: boleto

-- Fornecedores e Vendedores
INSERT INTO Fornecedor (nome_razao_social, cnpj) VALUES 
('Dell EMC Brasil', '99887766000199'),
('Cisco Systems', '55667788000122');

INSERT INTO Vendedor (nome_fantasia, cnpj_cpf) VALUES 
('Dell EMC Brasil', '99887766000199'),   -- mesmo CNPJ do fornecedor Dell
('Cisco Distribuidora', '55667788000122'); -- outro vendedor com mesmo CNPJ da Cisco

-- Produtos
INSERT INTO Produto (nome, preco_unitario) VALUES 
('Servidor PowerEdge R740', 25000.00),
('Switch Catalyst 9300', 12000.00),
('Licença de Gerenciamento', 1500.00);

-- Associação produto-vendedor (cada vendedor pode ofertar produtos)
INSERT INTO Produto_Vendedor (id_produto, id_vendedor, quantidade_disponivel) VALUES
(1, 1, 8),   -- Dell vende servidor
(2, 2, 20),  -- Cisco Distribuidora vende switch
(3, 2, 100); -- Licença vendida pela Cisco

-- Associação produto-fornecedor
INSERT INTO Produto_Fornecedor (id_produto, id_fornecedor) VALUES
(1, 1),  -- servidor fornecido pela Dell
(2, 2),  -- switch fornecido pela Cisco
(3, 2);  -- licença fornecida pela Cisco

-- Estoques e localizações
INSERT INTO Estoque (localizacao) VALUES 
('Centro de Distribuição - Barueri'),
('Hub Avançado - Campinas');

INSERT INTO Produto_Estoque (id_produto, id_estoque, quantidade) VALUES
(1, 1, 15),   -- servidor em Barueri
(2, 1, 40),   -- switch em Barueri
(2, 2, 10);   -- switch em Campinas

-- Pedidos
INSERT INTO Pedido (id_cliente, id_forma_pagamento, status_pedido) VALUES 
(2, 3, 'Aprovado'),      -- Tech Solutions, boleto
(1, 1, 'Enviado');       -- André, cartão corporate

-- Itens dos pedidos (trigger atualiza valor_total automaticamente)
INSERT INTO Item_Pedido (id_pedido, id_produto, quantidade, preco_unitario) VALUES
(1, 1, 2, 25000.00),   -- pedido 1: 2 servidores
(1, 2, 5, 12000.00),   -- pedido 1: 5 switches
(2, 3, 1, 1500.00);    -- pedido 2: 1 licença

-- Entregas associadas
INSERT INTO Entrega (id_pedido, codigo_rastreio, status_entrega) VALUES
(1, 'LOG-BR-100293', 'Separação'),
(2, 'LOG-BR-992811', 'Em Trânsito');
