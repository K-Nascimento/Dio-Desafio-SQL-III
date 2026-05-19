USE ecommerce_analytics;

-- -----------------------------------------------------------------
-- CONSULTAS ANALÍTICAS (ATENDENDO A TODAS AS CLÁUSULAS EXIGIDAS)
-- -----------------------------------------------------------------

-- 1. SELECT simples + WHERE: clientes do tipo PJ (pessoa jurídica)
SELECT id_cliente, nome_razao_social, cnpj, email 
FROM Cliente 
WHERE tipo_cliente = 'PJ';

-- 2. JOIN + ORDER BY: relação de fornecedores e produtos que fornecem
SELECT F.nome_razao_social AS Fornecedor, P.nome AS Produto
FROM Fornecedor F
INNER JOIN Produto_Fornecedor PF ON F.id_fornecedor = PF.id_fornecedor
INNER JOIN Produto P ON PF.id_produto = P.id_produto
ORDER BY F.nome_razao_social ASC;

-- 3. Pergunta: algum vendedor também é fornecedor? (cruzamento por CNPJ)
SELECT V.nome_fantasia AS Entidade, 
       V.cnpj_cpf AS Documento, 
       'Vendedor e Fornecedor' AS Classificacao
FROM Vendedor V
INNER JOIN Fornecedor F ON V.cnpj_cpf = F.cnpj;

-- 4. Atributos derivados + JOINs: capital imobilizado por produto em cada estoque
SELECT P.nome AS Produto, 
       E.localizacao AS Hub_Logistico, 
       PE.quantidade AS Volume_Fisico,
       (PE.quantidade * P.preco_unitario) AS Capital_Imobilizado
FROM Produto P
INNER JOIN Produto_Estoque PE ON P.id_produto = PE.id_produto
INNER JOIN Estoque E ON PE.id_estoque = E.id_estoque
ORDER BY Capital_Imobilizado DESC;

-- 5. GROUP BY + ORDER BY: total de pedidos por cliente (responde a pergunta)
SELECT C.nome_razao_social AS Cliente, 
       COUNT(P.id_pedido) AS Total_Pedidos
FROM Cliente C
LEFT JOIN Pedido P ON C.id_cliente = P.id_cliente
GROUP BY C.id_cliente, C.nome_razao_social
ORDER BY Total_Pedidos DESC;

-- 6. Atributos derivados + agregação: ticket médio e faturamento projetado com impostos (5%)
SELECT id_pedido, 
       SUM(quantidade) AS Total_Itens,
       SUM(quantidade * preco_unitario) AS Subtotal_Bruto,
       ROUND(SUM(quantidade * preco_unitario) * 1.05, 2) AS Faturamento_Com_Impostos
FROM Item_Pedido
GROUP BY id_pedido;

-- 7. HAVING: pedidos com diversidade maior que 1 tipo de produto (mais de uma linha de item)
SELECT id_pedido, COUNT(id_produto) AS Diversidade_Itens
FROM Item_Pedido
GROUP BY id_pedido
HAVING COUNT(id_produto) > 1;

-- 8. JOINs + filtro complexo: painel de tracking operacional (pedidos não finalizados)
SELECT P.id_pedido, 
       C.nome_razao_social, 
       P.status_pedido, 
       E.codigo_rastreio, 
       E.status_entrega
FROM Pedido P
INNER JOIN Cliente C ON P.id_cliente = C.id_cliente
LEFT JOIN Entrega E ON P.id_pedido = E.id_pedido
WHERE P.status_pedido NOT IN ('Cancelado', 'Entregue');

-- 9. Relação de produtos, fornecedores e estoques (responde diretamente a pergunta)
SELECT P.nome AS Produto,
       F.nome_razao_social AS Fornecedor,
       Est.localizacao AS Local_Estoque,
       PE.quantidade AS Qtd_Estoque
FROM Produto P
JOIN Produto_Fornecedor PF ON P.id_produto = PF.id_produto
JOIN Fornecedor F ON PF.id_fornecedor = F.id_fornecedor
JOIN Produto_Estoque PE ON P.id_produto = PE.id_produto
JOIN Estoque Est ON PE.id_estoque = Est.id_estoque;

-- 10. Dashboard de receita retida por hub logístico (HAVING + ORDER BY)
SELECT E.localizacao, 
       SUM(PE.quantidade * P.preco_unitario) AS Valor_Alocado
FROM Estoque E
INNER JOIN Produto_Estoque PE ON E.id_estoque = PE.id_estoque
INNER JOIN Produto P ON PE.id_produto = P.id_produto
GROUP BY E.localizacao
HAVING Valor_Alocado > 0          -- ou > 50000 conforme dados reais
ORDER BY Valor_Alocado DESC;
