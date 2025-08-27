# Database Schema

Based on the Ash Resources defined in the Data Models section, the PostgreSQL schema implements the core domain entities with optimized indexes and constraints for distributed AI workloads.

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Nodes table - Core P2P network participants
CREATE TABLE nodes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    public_key VARCHAR(88) NOT NULL UNIQUE, -- Ed25519 public key (base64)
    node_type VARCHAR(20) NOT NULL CHECK (node_type IN ('genesis', 'expert', 'participant')),
    specialization_domains TEXT[] DEFAULT '{}',
    reputation_score DECIMAL(10,3) DEFAULT 0.000,
    status VARCHAR(20) NOT NULL DEFAULT 'offline' CHECK (status IN ('online', 'offline', 'connecting', 'maintenance')),
    last_seen_at TIMESTAMP WITH TIME ZONE,
    connection_count INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}',
    inserted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Optimized indexes for nodes
CREATE INDEX idx_nodes_status ON nodes(status);
CREATE INDEX idx_nodes_node_type ON nodes(node_type);
CREATE INDEX idx_nodes_specialization_domains ON nodes USING GIN(specialization_domains);
CREATE INDEX idx_nodes_reputation_score ON nodes(reputation_score DESC);
CREATE INDEX idx_nodes_last_seen_at ON nodes(last_seen_at DESC);

-- Knowledge table - Collective intelligence storage
CREATE TABLE knowledge (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content TEXT NOT NULL,
    content_hash VARCHAR(64) NOT NULL UNIQUE, -- SHA-256 hash
    confidence_score DECIMAL(5,3) DEFAULT 0.000 CHECK (confidence_score >= 0 AND confidence_score <= 1),
    knowledge_type VARCHAR(20) NOT NULL CHECK (knowledge_type IN ('insight', 'fact', 'procedure', 'pattern')),
    domain_tags TEXT[] DEFAULT '{}',
    source_count INTEGER DEFAULT 0,
    validation_status VARCHAR(20) DEFAULT 'pending' CHECK (validation_status IN ('pending', 'validated', 'disputed', 'archived')),
    metadata JSONB DEFAULT '{}',
    inserted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Optimized indexes for knowledge
CREATE INDEX idx_knowledge_content_hash ON knowledge(content_hash);
CREATE INDEX idx_knowledge_confidence_score ON knowledge(confidence_score DESC);
CREATE INDEX idx_knowledge_validation_status ON knowledge(validation_status);
CREATE INDEX idx_knowledge_knowledge_type ON knowledge(knowledge_type);
CREATE INDEX idx_knowledge_domain_tags ON knowledge USING GIN(domain_tags);
CREATE INDEX idx_knowledge_inserted_at ON knowledge(inserted_at DESC);

-- Full-text search for knowledge content
CREATE INDEX idx_knowledge_content_fts ON knowledge USING GIN(to_tsvector('english', content));

-- Contributions table - Join table with quality tracking
CREATE TABLE contributions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    node_id UUID NOT NULL REFERENCES nodes(id) ON DELETE CASCADE,
    knowledge_id UUID NOT NULL REFERENCES knowledge(id) ON DELETE CASCADE,
    contribution_type VARCHAR(20) NOT NULL CHECK (contribution_type IN ('creation', 'validation', 'synthesis', 'correction')),
    quality_score DECIMAL(5,3) DEFAULT 0.000 CHECK (quality_score >= 0 AND quality_score <= 1),
    tokens_earned INTEGER DEFAULT 0,
    peer_validations INTEGER DEFAULT 0,
    contribution_weight DECIMAL(5,3) DEFAULT 1.000,
    metadata JSONB DEFAULT '{}',
    inserted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Optimized indexes for contributions
CREATE INDEX idx_contributions_node_id ON contributions(node_id);
CREATE INDEX idx_contributions_knowledge_id ON contributions(knowledge_id);
CREATE INDEX idx_contributions_contribution_type ON contributions(contribution_type);
CREATE INDEX idx_contributions_quality_score ON contributions(quality_score DESC);
CREATE INDEX idx_contributions_tokens_earned ON contributions(tokens_earned DESC);
CREATE INDEX idx_contributions_inserted_at ON contributions(inserted_at DESC);

-- Composite indexes for common queries
CREATE INDEX idx_contributions_node_type_quality ON contributions(node_id, contribution_type, quality_score DESC);
CREATE INDEX idx_knowledge_status_confidence ON knowledge(validation_status, confidence_score DESC);

-- Database functions for performance
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for automatic timestamp updates
CREATE TRIGGER update_nodes_updated_at BEFORE UPDATE ON nodes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_knowledge_updated_at BEFORE UPDATE ON knowledge
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contributions_updated_at BEFORE UPDATE ON contributions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Materialized view for node reputation aggregation
CREATE MATERIALIZED VIEW node_reputation_summary AS
SELECT 
    n.id,
    n.public_key,
    n.node_type,
    n.specialization_domains,
    n.status,
    COUNT(c.id) as total_contributions,
    AVG(c.quality_score) as avg_quality_score,
    SUM(c.tokens_earned) as total_tokens_earned,
    COUNT(DISTINCT c.knowledge_id) as unique_knowledge_contributed
FROM nodes n
LEFT JOIN contributions c ON n.id = c.node_id
GROUP BY n.id, n.public_key, n.node_type, n.specialization_domains, n.status;

CREATE UNIQUE INDEX idx_node_reputation_summary_id ON node_reputation_summary(id);
CREATE INDEX idx_node_reputation_summary_avg_quality ON node_reputation_summary(avg_quality_score DESC);

-- Refresh materialized view function
CREATE OR REPLACE FUNCTION refresh_node_reputation_summary()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY node_reputation_summary;
END;
$$ LANGUAGE plpgsql;
```
