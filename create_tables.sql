CREATE TABLE clients (
client_id SERIAL PRIMARY KEY,
full_name VARCHAR(120) NOT NULL,
phone VARCHAR(30) UNIQUE,
email VARCHAR(120) UNIQUE,
created_at DATE NOT NULL
);

CREATE TABLE accounts (
account_id SERIAL PRIMARY KEY,
client_id INT NOT NULL REFERENCES clients(client_id),
account_type VARCHAR(20) NOT NULL CHECK (account_type IN ('debit', 'savings', 'credit')),
currency CHAR(3) NOT NULL,
opened_at DATE NOT NULL,
status VARCHAR(20) NOT NULL CHECK (status IN ('active', 'blocked', 'closed'))
);

CREATE TABLE cards (
card_id SERIAL PRIMARY KEY,
account_id INT NOT NULL REFERENCES accounts(account_id),
card_type VARCHAR(20) NOT NULL CHECK (card_type IN ('debit', 'credit', 'virtual')),
issued_at DATE NOT NULL,
expires_at DATE NOT NULL,
status VARCHAR(20) NOT NULL CHECK (status IN ('active', 'blocked', 'expired'))
);

CREATE TABLE transactions (
transaction_id SERIAL PRIMARY KEY,
account_id INT NOT NULL REFERENCES accounts(account_id),
txn_type VARCHAR(20) NOT NULL CHECK (txn_type IN ('deposit', 'withdrawal', 'transfer_in', 'transfer_out', 'fee')),
amount NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
txn_date TIMESTAMP NOT NULL,
description VARCHAR(200)
);

CREATE TABLE loans (
loan_id SERIAL PRIMARY KEY,
client_id INT NOT NULL REFERENCES clients(client_id),
principal NUMERIC(14,2) NOT NULL CHECK (principal > 0),
interest_rate NUMERIC(5,2) NOT NULL CHECK (interest_rate >= 0),
start_date DATE NOT NULL,
end_date DATE NOT NULL,
status VARCHAR(20) NOT NULL CHECK (status IN ('active', 'closed', 'overdue'))
);

CREATE TABLE loan_payments (
payment_id SERIAL PRIMARY KEY,
loan_id INT NOT NULL REFERENCES loans(loan_id),
amount NUMERIC(14,2) NOT NULL CHECK (amount > 0),
payment_date DATE NOT NULL,
status VARCHAR(20) NOT NULL CHECK (status IN ('success', 'failed'))
);
