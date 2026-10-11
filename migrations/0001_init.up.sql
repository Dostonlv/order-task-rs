CREATE TYPE user_role AS ENUM ('admin', 'user');
CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'cancelled');
CREATE TYPE payment_status AS ENUM ('pending', 'succeeded', 'failed', 'refunded');
CREATE TYPE payment_event_type AS ENUM ('succeeded', 'failed', 'refunded');

CREATE TABLE users (
    id            uuid         PRIMARY KEY DEFAULT uuidv7(),
    email         varchar      NOT NULL UNIQUE,
    password_hash varchar      NOT NULL,
    role          user_role    NOT NULL DEFAULT 'user',
    created_at    timestamptz  NOT NULL DEFAULT now()
);

CREATE TABLE products (
    id             uuid         PRIMARY KEY DEFAULT uuidv7(),
    name           varchar      NOT NULL,
    price          bigint       NOT NULL CHECK (price >= 0),
    image_link     varchar      NOT NULL,
    stock_quantity integer      NOT NULL CHECK (stock_quantity >= 0),
    created_at     timestamptz  NOT NULL DEFAULT now()
);

CREATE TABLE orders (
    id          uuid          PRIMARY KEY DEFAULT uuidv7(),
    user_id     uuid          NOT NULL REFERENCES users (id),
    status      order_status  NOT NULL DEFAULT 'pending',
    total_price bigint        NOT NULL CHECK (total_price >= 0),
    expires_at  timestamptz   NOT NULL,
    created_at  timestamptz   NOT NULL DEFAULT now()
);

CREATE INDEX idx_orders_user_id        ON orders (user_id);
CREATE INDEX idx_orders_status_expires ON orders (status, expires_at);

CREATE TABLE order_items (
    id         uuid     PRIMARY KEY DEFAULT uuidv7(),
    order_id   uuid     NOT NULL REFERENCES orders (id),
    product_id uuid     NOT NULL REFERENCES products (id),
    quantity   integer  NOT NULL CHECK (quantity > 0),
    unit_price bigint   NOT NULL CHECK (unit_price >= 0)
);

CREATE UNIQUE INDEX uq_order_items_order_product ON order_items (order_id, product_id);
CREATE INDEX idx_order_items_product_id ON order_items (product_id);

CREATE TABLE idempotency_keys (
    id           uuid         PRIMARY KEY DEFAULT uuidv7(),
    user_id      uuid         NOT NULL REFERENCES users (id),
    key          varchar      NOT NULL,
    request_hash varchar      NOT NULL,
    order_id     uuid         REFERENCES orders (id),
    created_at   timestamptz  NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX uq_idempotency_keys_user_key ON idempotency_keys (user_id, key);
CREATE INDEX idx_idempotency_keys_order_id ON idempotency_keys (order_id);

CREATE TABLE payments (
    id                  uuid            PRIMARY KEY DEFAULT uuidv7(),
    order_id            uuid            NOT NULL REFERENCES orders (id),
    provider            varchar         NOT NULL,
    provider_payment_id varchar         NOT NULL,
    amount              bigint          NOT NULL CHECK (amount >= 0),
    currency            varchar(3)      NOT NULL,
    status              payment_status  NOT NULL DEFAULT 'pending',
    created_at          timestamptz     NOT NULL DEFAULT now()
);

CREATE INDEX idx_payments_order_id ON payments (order_id);
CREATE UNIQUE INDEX uq_payments_provider_payment ON payments (provider, provider_payment_id);

CREATE TABLE payment_events (
    provider   varchar             NOT NULL,
    event_id   varchar             NOT NULL,
    payment_id uuid                NOT NULL REFERENCES payments (id),
    type       payment_event_type  NOT NULL,
    payload    jsonb,
    created_at timestamptz         NOT NULL DEFAULT now(),
    PRIMARY KEY (provider, event_id)
);

CREATE INDEX idx_payment_events_payment_id ON payment_events (payment_id);