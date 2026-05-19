# Modelagem Lógica: E‑Commerce com Controle de Clientes PF/PJ, Múltiplos Pagamentos e Logística de Entrega

## Contexto
Este projeto implementa o esquema lógico de um banco de dados para um cenário de e‑commerce, conforme desafio proposto. O modelo atende aos seguintes requisitos de negócio:

- **Cliente PF e PJ** – uma única tabela com restrição de exclusão (cpf para PF, cnpj para PJ).
- **Múltiplas formas de pagamento** – um cliente pode cadastrar várias formas de pagamento (cartão, boleto, pix etc.).
- **Entrega com rastreamento** – cada pedido gera uma entrega com status e código de rastreio.
- **Cadeia de suprimentos** – produtos, fornecedores, vendedores e estoques.
- **Independência vendedor / fornecedor** – um vendedor pode também ser fornecedor (identificado pelo CNPJ).

## Estrutura do Esquema (Diagrama Relacional)

```mermaid
erDiagram
    CLIENTE {
        int id_cliente PK
        enum tipo_cliente "PF/PJ"
        string nome_razao_social
        char11 cpf UK
        char14 cnpj UK
        string email UK
    }
    FORMA_PAGAMENTO {
        int id_forma PK
        string descricao
    }
    CLIENTE_PAGAMENTO {
        int id_cliente PK,FK
        int id_forma PK,FK
    }
    PEDIDO {
        int id_pedido PK
        int id_cliente FK
        int id_forma_pagamento FK
        datetime data_emissao
        enum status_pedido
        decimal valor_total
    }
    ITEM_PEDIDO {
        int id_pedido PK,FK
        int id_produto PK,FK
        int quantidade
        decimal preco_unitario
    }
    ENTREGA {
        int id_entrega PK
        int id_pedido FK,UK
        string codigo_rastreio UK
        enum status_entrega
        timestamp data_atualizacao
    }
    PRODUTO {
        int id_produto PK
        string nome
        decimal preco_unitario
    }
    FORNECEDOR {
        int id_fornecedor PK
        string nome_razao_social
        char14 cnpj UK
    }
    VENDEDOR {
        int id_vendedor PK
        string nome_fantasia
        string cnpj_cpf UK
    }
    PRODUTO_VENDEDOR {
        int id_produto PK,FK
        int id_vendedor PK,FK
        int quantidade_disponivel
    }
    PRODUTO_FORNECEDOR {
        int id_produto PK,FK
        int id_fornecedor PK,FK
    }
    ESTOQUE {
        int id_estoque PK
        string localizacao
    }
    PRODUTO_ESTOQUE {
        int id_produto PK,FK
        int id_estoque PK,FK
        int quantidade
    }

    CLIENTE ||--o{ CLIENTE_PAGAMENTO : possui
    FORMA_PAGAMENTO ||--o{ CLIENTE_PAGAMENTO : vinculado
    CLIENTE ||--o{ PEDIDO : realiza
    PEDIDO ||--|| ENTREGA : gera
    PEDIDO ||--o{ ITEM_PEDIDO : contém
    PRODUTO ||--o{ ITEM_PEDIDO : item
    PRODUTO ||--o{ PRODUTO_VENDEDOR : vendido_por
    VENDEDOR ||--o{ PRODUTO_VENDEDOR : disponibiliza
    PRODUTO ||--o{ PRODUTO_FORNECEDOR : fornecido_por
    FORNECEDOR ||--o{ PRODUTO_FORNECEDOR : fornece
    PRODUTO ||--o{ PRODUTO_ESTOQUE : armazenado_em
    ESTOQUE ||--o{ PRODUTO_ESTOQUE : aloca
