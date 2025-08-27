# Core Workflows

The following sequence diagrams illustrate key system workflows that demonstrate how xPando's components interact to achieve collective intelligence. These workflows show both the happy path and error handling scenarios critical for distributed AI operations.

## Knowledge Contribution and Validation Workflow

This workflow demonstrates how knowledge flows from individual nodes through the Mother Core validation process to network-wide distribution.

```mermaid
sequenceDiagram
    participant N as AI Node
    participant MC as Mother Core
    participant VC as Validation Consensus
    participant NN as Node Network
    participant BC as Blockchain Service
    participant DB as PostgreSQL
    
    N->>MC: contribute_knowledge(content, metadata)
    MC->>DB: store_pending_knowledge()
    DB-->>MC: knowledge_id
    
    MC->>VC: initiate_consensus_validation(knowledge_id)
    VC->>NN: broadcast_validation_request(knowledge_id)
    
    loop Validator Selection
        NN->>N: request_validation(knowledge_id, expertise_match)
        N->>VC: submit_validation(knowledge_id, confidence_score, reasoning)
    end
    
    VC->>VC: calculate_weighted_consensus()
    
    alt Validation Passes (consensus >= threshold)
        VC->>MC: validation_complete(knowledge_id, final_confidence)
        MC->>DB: update_knowledge_status(validated)
        MC->>NN: distribute_validated_knowledge(knowledge_id)
        MC->>BC: award_tokens(contributor_node, validator_nodes, quality_score)
        BC-->>N: token_reward_notification
    else Validation Fails
        VC->>MC: validation_failed(knowledge_id, reasons)
        MC->>DB: update_knowledge_status(disputed)
        MC->>N: validation_failure_notice(reasons)
    end
    
    Note over MC, NN: Knowledge propagated to all connected nodes within 1 hour
```

## Expert Node Discovery and Query Routing Workflow

This workflow shows how queries are intelligently routed to the most qualified expert nodes based on specialization and availability.

```mermaid
sequenceDiagram
    participant U as User/Client
    participant SE as Specialization Engine
    participant NN as Node Network
    participant EN as Expert Node
    participant AI as AI Provider Hub
    participant MC as Mother Core
    
    U->>SE: submit_query(question, domain_hint)
    SE->>SE: classify_query_domain(question)
    
    SE->>NN: find_domain_experts(domain, min_reputation)
    NN-->>SE: expert_nodes_list(sorted_by_expertise)
    
    loop Expert Selection
        SE->>EN: check_availability()
        alt Expert Available
            EN-->>SE: available(current_load)
            SE->>EN: route_query(question, context)
            break Expert Accepts Query
        else Expert Busy/Offline
            EN-->>SE: unavailable()
        end
    end
    
    EN->>AI: enhance_with_ai(question, specialization_context)
    AI-->>EN: ai_enhanced_response
    
    EN->>MC: contribute_enhanced_knowledge(response, confidence)
    MC->>MC: validate_and_score_response()
    
    EN->>U: deliver_expert_response(answer, confidence_score)
    MC->>BC: award_expertise_tokens(expert_node, query_complexity)
    
    Note over SE, EN: Expert reputation updated based on response quality
```

## Network Node Discovery and P2P Connection Workflow

This workflow illustrates how nodes discover each other and establish P2P connections in the distributed network.

```mermaid
sequenceDiagram
    participant N1 as New Node
    participant LC as libcluster
    participant NN as Node Network Manager
    participant N2 as Existing Node
    participant CH as Phoenix Channel
    participant DB as PostgreSQL
    
    N1->>LC: start_node(node_config)
    LC->>LC: discover_cluster_nodes()
    LC-->>N1: available_nodes_list
    
    N1->>NN: register_node(public_key, specialization)
    NN->>DB: create_node_record()
    DB-->>NN: node_id
    
    NN->>CH: join_node_network_channel(node_id)
    CH->>CH: authenticate_node(public_key)
    
    alt Authentication Success
        CH-->>NN: connection_established
        NN->>N2: broadcast_new_node(node_id, specialization)
        N2-->>N1: welcome_handshake(network_status)
        
        NN->>NN: update_network_topology()
        NN->>DB: update_connection_count(node_id)
        
        loop Periodic Health Check
            N1->>NN: heartbeat(status, metadata)
            NN->>CH: broadcast_status_update()
        end
        
    else Authentication Failure
        CH-->>N1: connection_rejected(reason)
        N1->>N1: retry_with_new_credentials()
    end
    
    Note over N1, N2: P2P mesh network established with fault-tolerant connections
```

## XPD Token Distribution Workflow

This workflow shows how the blockchain integration manages token rewards based on knowledge contribution quality.

```mermaid
sequenceDiagram
    participant MC as Mother Core
    participant BC as Blockchain Service
    participant OB as Oban Queue
    participant SR as Solana RPC
    participant W as User Wallet
    participant DB as PostgreSQL
    
    MC->>BC: calculate_token_rewards(contributions, quality_scores)
    BC->>BC: apply_reward_algorithm(anti_gaming_rules)
    
    BC->>DB: record_pending_distributions(wallet_addresses, amounts)
    
    loop For Each Reward
        BC->>OB: queue_token_transfer(wallet, amount, transaction_metadata)
        OB->>SR: submit_spl_token_transfer()
        
        alt Transaction Success
            SR-->>OB: transaction_signature
            OB->>DB: update_transaction_status(confirmed)
            OB->>W: notify_token_received(amount, transaction_id)
            OB->>MC: update_contributor_balance(node_id, new_total)
        else Transaction Failure
            SR-->>OB: transaction_error(reason)
            OB->>OB: retry_with_backoff()
            
            alt Max Retries Exceeded
                OB->>DB: mark_transaction_failed()
                OB->>BC: alert_failed_distribution(wallet, amount)
            end
        end
    end
    
    Note over BC, W: All token distributions tracked with full audit trail
```

## AI Provider Integration and Failover Workflow

This workflow demonstrates how the system handles AI provider integration with failover capabilities for high availability.

```mermaid
sequenceDiagram
    participant MC as Mother Core
    participant AI as AI Provider Hub
    participant OAI as OpenAI API
    participant ANT as Anthropic API
    participant GGL as Google AI API
    participant CB as Circuit Breaker
    participant CACHE as Redis Cache
    
    MC->>AI: process_ai_query(prompt, requirements)
    AI->>CACHE: check_cached_response(prompt_hash)
    
    alt Cache Hit
        CACHE-->>AI: cached_response
        AI-->>MC: return_cached_result()
    else Cache Miss
        AI->>AI: select_optimal_provider(prompt_type, load_balance)
        
        AI->>CB: check_circuit_state(primary_provider)
        alt Circuit Open (Provider Healthy)
            AI->>OAI: submit_request(prompt, parameters)
            
            alt OpenAI Success
                OAI-->>AI: ai_response
                AI->>CACHE: store_response(prompt_hash, response, ttl: 1h)
                CB->>CB: record_success()
            else OpenAI Failure
                OAI-->>AI: error_response
                CB->>CB: record_failure()
                AI->>AI: initiate_failover()
            end
            
        else Circuit Half-Open/Closed
            AI->>ANT: failover_to_anthropic()
            
            alt Anthropic Success
                ANT-->>AI: ai_response
                AI->>CACHE: store_response()
            else Anthropic Failure
                AI->>GGL: failover_to_google()
                
                alt Google Success
                    GGL-->>AI: ai_response
                else All Providers Failed
                    AI-->>MC: service_unavailable_error()
                end
            end
        end
    end
    
    Note over AI, CB: Circuit breaker prevents cascade failures across AI providers
```
