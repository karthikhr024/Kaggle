graph TD
    %% --- Definitions ---
    subgraph Sources [Data Sources]
        RT_Stream(Real-Time Stream)
        Batch_ETL(Daily Batch ETL)
    end

    subgraph Messaging [Kafka Buffers]
        Topic_NRT[(Topic: nrt-buffered)]
        Topic_Batch[(Topic: batch-buffered)]
    end

    subgraph Compute [Ingestion Layer]
        Ingest_Service[Ingestion Service: Java 21]
    end

    subgraph Storage [Aerospike Cluster]
        AS_Node[(Aerospike Namespace: mlp)]
        Bin_Imp(Bin: imp - Impressions)
        Bin_Conv(Bin: conv - Conversions)
        Bin_UMB(Bin: umb - Static Features)
    end

    subgraph Clients [Serving Layer]
        Ad_Server(Ad Serving Engine)
    end

    %% --- Flows: NRT Path ---
    RT_Stream -->|Events| Topic_NRT
    Topic_NRT -->|Consumes| Ingest_Service
    Ingest_Service -->|Map Increment| Bin_Imp
    Ingest_Service -->|Map Increment| Bin_Conv

    %% --- Flows: Batch Path ---
    Batch_ETL -->|Daily Aggregates| Topic_Batch
    Topic_Batch -->|Consumes| Ingest_Service
    Ingest_Service -->|Map Put / Overwrite| Bin_Imp
    Ingest_Service -->|Bin Put / Replace| Bin_UMB

    %% --- Read Path ---
    Ad_Server -->|Batch Read| AS_Node

    %% --- Styling (Simple) ---
    style Ingest_Service fill:#f9f,stroke:#333
    style AS_Node fill:#ccf,stroke:#333
    style Topic_NRT fill:#ff9,stroke:#333
    style Topic_Batch fill:#9f9,stroke:#333
