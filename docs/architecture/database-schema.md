# Database Schema

## PostgreSQL Schema (via ash_postgres)

```sql
-- Nodes table (managed by Ash Resource)
CREATE TABLE nodes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'offline',
    specializations TEXT[] DEFAULT '{}',
    reputation_score DECIMAL(5,2) DEFAULT 0.0,
    wallet_address VARCHAR(100),
    last_heartbeat TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}',
    inserted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_nodes_status ON nodes(status);
CREATE INDEX idx_nodes_specializations ON nodes USING GIN(specializations);
CREATE INDEX idx_nodes_reputation ON nodes(reputation_score DESC);

-- Knowledge table (managed by Ash Resource)
CREATE TABLE knowledge (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content JSONB NOT NULL,
    confidence_score DECIMAL(5,4) NOT NULL DEFAULT 0.0,
    domain VARCHAR(100) NOT NULL,
    version INTEGER NOT NULL DEFAULT 1,
    merkle_root VARCHAR(66) NOT NULL,
    created_by_id UUID REFERENCES nodes(id),
    parent_knowledge_id UUID REFERENCES knowledge(id),
    validation_count INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}',
    inserted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_knowledge_domain ON knowledge(domain);
CREATE INDEX idx_knowledge_confidence ON knowledge(confidence_score DESC);
CREATE INDEX idx_knowledge_created_by ON knowledge(created_by_id);
CREATE INDEX idx_knowledge_content ON knowledge USING GIN(content);

-- Contributions table (managed by Ash Resource)
CREATE TABLE contributions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    node_id UUID NOT NULL REFERENCES nodes(id),
    knowledge_id UUID NOT NULL REFERENCES knowledge(id),
    quality_score DECIMAL(5,4) NOT NULL DEFAULT 0.0,
    xpd_reward DECIMAL(20,8) DEFAULT 0.0,
    validation_count INTEGER DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    transaction_hash VARCHAR(100),
    inserted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_contributions_node ON contributions(node_id);
CREATE INDEX idx_contributions_knowledge ON contributions(knowledge_id);
CREATE INDEX idx_contributions_status ON contributions(status);

-- Mother Core consensus table
CREATE TABLE mother_core_states (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    genesis_node BOOLEAN DEFAULT FALSE,
    consensus_state JSONB NOT NULL,
    network_version VARCHAR(20) NOT NULL,
    total_knowledge INTEGER DEFAULT 0,
    connected_nodes INTEGER DEFAULT 0,
    last_sync TIMESTAMP WITH TIME ZONE,
    merkle_tree JSONB,
    inserted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Validations table for knowledge validation tracking
CREATE TABLE validations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    knowledge_id UUID NOT NULL REFERENCES knowledge(id),
    validator_node_id UUID NOT NULL REFERENCES nodes(id),
    is_valid BOOLEAN NOT NULL,
    confidence_adjustment DECIMAL(3,2),
    feedback TEXT,
    signature VARCHAR(200),
    inserted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_validations_knowledge ON validations(knowledge_id);
CREATE INDEX idx_validations_validator ON validations(validator_node_id);

-- Network events for audit and debugging
CREATE TABLE network_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type VARCHAR(100) NOT NULL,
    node_id UUID REFERENCES nodes(id),
    payload JSONB,
    inserted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_network_events_type ON network_events(event_type);
CREATE INDEX idx_network_events_node ON network_events(node_id);
CREATE INDEX idx_network_events_time ON network_events(inserted_at DESC);

-- Users table for authentication (via ash_authentication)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255),
    role VARCHAR(50) DEFAULT 'user',
    node_id UUID REFERENCES nodes(id),
    confirmed_at TIMESTAMP WITH TIME ZONE,
    inserted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_node ON users(node_id);
```