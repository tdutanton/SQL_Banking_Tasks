-- 1. Найти активные счета в EUR, открытые после 2024-01-01, отсортировать по дате открытия
SELECT * FROM accounts 
WHERE opened_at > '2024-01-01' 
ORDER BY opened_at ASC;

-- 2. Вывести ФИО клиента, тип счета, валюту и статус счета
SELECT c.full_name, a.account_type, a.currency, a.status 
FROM accounts a 
INNER JOIN clients c ON a.client_id = c.client_id 
ORDER BY c.full_name ASC;

-- 3. Вывести всех клиентов и количество их счетов (включая 0)
SELECT c.full_name, COUNT(a.account_id) as account_count 
FROM accounts a 
RIGHT JOIN clients c ON a.client_id = c.client_id
GROUP BY c.full_name
ORDER BY account_count DESC;

-- 4. Найти клиентов, у которых больше 2 активных счетов
SELECT c.full_name, COUNT(a.account_id) AS active_account_count
FROM accounts a 
RIGHT JOIN clients c ON a.client_id = c.client_id AND a.status = 'active'
GROUP BY c.full_name
HAVING COUNT(a.account_id) > 2
ORDER BY active_account_count DESC;

-- 5. Найти счета, у которых сумма входящих операций (deposit + transfer_in) выше среднего по банку
WITH incoming_sum AS (
	SELECT account_id,
	COALESCE(SUM(amount), 0) AS total_incoming
	FROM transactions
	WHERE txn_type IN ('deposit', 'transfer_in')
	GROUP BY account_id
),
banking_avg AS (
	SELECT AVG(total_incoming) as avg_incoming
	FROM incoming_sum
)
SELECT 
    a.account_id,
    c.full_name,
    a.account_type,
    a.currency,
    ins.total_incoming
FROM incoming_sum ins
JOIN banking_avg ba ON ins.total_incoming > ba.avg_incoming
JOIN accounts a ON ins.account_id = a.account_id
JOIN clients c ON a.client_id = c.client_id
ORDER BY ins.total_incoming DESC;

-- 6. Топ-5 клиентов по сумме всех операций (оборот) за 2025 год
WITH total_sum AS (
	SELECT account_id,
	COALESCE(SUM(amount), 0) AS sum_txn
	FROM transactions
	WHERE txn_date >= '2025-01-01' AND txn_date < '2026-01-01'
	GROUP BY account_id
)
SELECT c.full_name, SUM(t.sum_txn) AS result_txn
FROM accounts a
JOIN total_sum t ON a.account_id = t.account_id
JOIN clients c ON a.client_id = c.client_id
GROUP BY c.full_name
ORDER BY 2 DESC
LIMIT 5;

-- 7. Определить “активность клиента” по количеству операций за последние 90 дней:
--     0 операций → inactive
--     1–5 → low
--     6–20 → medium
--     20 → high
SELECT 
    c.client_id,
    c.full_name,
    COALESCE(txn_count, 0) AS transaction_count,
    CASE
        WHEN COALESCE(txn_count, 0) = 0 THEN 'inactive'
        WHEN COALESCE(txn_count, 0) BETWEEN 1 AND 5 THEN 'low'
        WHEN COALESCE(txn_count, 0) BETWEEN 6 AND 19 THEN 'medium'
        WHEN COALESCE(txn_count, 0) >= 20 THEN 'high'
    END AS activity_level
FROM clients c
LEFT JOIN (
    SELECT 
        a.client_id,
        COUNT(*) AS txn_count
    FROM accounts a
    JOIN transactions t ON a.account_id = t.account_id
    WHERE t.txn_date >= NOW() - INTERVAL '90 days'
    GROUP BY a.client_id
) recent_txns ON c.client_id = recent_txns.client_id
ORDER BY transaction_count DESC;

-- 8. Найти кредиты, по которым сумма успешных платежей < 50% от principal
SELECT l.loan_id, SUM(lp.amount) AS payments
FROM loans l
JOIN loan_payments lp ON l.loan_id = lp.loan_id
WHERE lp.status = 'success'
GROUP BY l.loan_id, l.principal
HAVING SUM(lp.amount) < (l.principal * 0.5);

-- 9. Показать все активные карты и кому они принадлежат (ФИО, account_id, срок действия)
SELECT cl.full_name, c.account_id, c.expires_at
FROM cards c
JOIN accounts a ON c.account_id = a.account_id
JOIN clients cl ON a.client_id = cl.client_id
WHERE c.status = 'active' AND c.expires_at >= CURRENT_DATE
ORDER BY c.expires_at DESC;

-- 10. Для каждого счета посчитать: количество операций и сумму списаний (withdrawal + transfer_out + fee)
SELECT a.account_id, COUNT(t.transaction_id) AS total_operations,
    COALESCE(
        SUM(
            CASE 
                WHEN t.txn_type IN ('withdrawal', 'transfer_out', 'fee') 
                THEN t.amount 
                ELSE 0 
            END
        ), 
        0
    ) AS total_debits
FROM accounts a
LEFT JOIN transactions t ON a.account_id = t.account_id
GROUP BY a.account_id
ORDER BY a.account_id;
