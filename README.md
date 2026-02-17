graph TD
    %% Definitions
    subgraph Sources ["Data Sources"]
        RT_Stream[("Real-Time Stream<br>(Ad Server / Chronon)")]
        Batch_ETL[("Daily Batch ETL<br>(Spark / Data Lake)")]
    end

    subgraph Messaging ["Kafka (Buffers)"]
        Topic_NRT[("Topic: nrt-buffered<br>(High Volume, Fast)")]
        Topic_Batch[("Topic: batch-buffered<br>(High Accuracy, Slow)")]
    end

    subgraph Compute ["Ingestion Layer (K8s)"]
        Ingest_Service("<b>Ingestion Service</b><br>(Java 21 / Virtual Threads)<br><i>Consumer Group: feature-store-writer</i>")
    end

    subgraph Storage ["Aerospike Cluster (3 Nodes)"]
        AS_Node[("<b>Namespace: mlp</b><br>Set: user_features<br>Key: household_id")]
        
        subgraph Record_Structure ["Record Structure"]
            Bin_UMB["Bin: umb (Blob)<br><i>Static Features</i>"]
            Bin_Imp["Bin: imp (Map)<br><i>Impressions</i>"]
            Bin_Conv["Bin: conv (Map)<br><i>Conversions</i>"]
        end
    end

    subgraph Clients ["Serving Layer"]
        Ad_Server["Ad Serving Engine<br>(Reads @ 70k TPS)"]
    end

    %% Flows - NRT Path
    RT_Stream -->|Events| Topic_NRT
    Topic_NRT -->|Consumes| Ingest_Service
    Ingest_Service -->|<b>MapOperation.INCREMENT</b><br><i>(Accumulate)</i>| Bin_Imp
    Ingest_Service -->|<b>MapOperation.INCREMENT</b><br><i>(Accumulate)</i>| Bin_Conv

    %% Flows - Batch Path
    Batch_ETL -->|Daily Aggregates| Topic_Batch
    Topic_Batch -->|Consumes| Ingest_Service
    Ingest_Service -->|<b>MapOperation.PUT</b><br><i>(Overwrite/Correct)</i>| Bin_Imp
    Ingest_Service -->|<b>Bin.PUT</b><br><i>(Replace Blob)</i>| Bin_UMB

    %% Read Path
    Ad_Server -->|<b>Batch Read (Get)</b><br><i>Fetch: umb, imp, conv</i>| AS_Node

    %% Styling
    style Ingest_Service fill:#f9f,stroke:#333,stroke-width:2px
    style AS_Node fill:#ccf,stroke:#333,stroke-width:2px
    style Topic_NRT fill:#ff9,stroke:#333
    style Topic_Batch fill:#9f9,stroke:#333
