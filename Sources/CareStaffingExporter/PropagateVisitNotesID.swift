import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagateVisitNotesID keeps of each CountVisitNotes response.
struct PropagateVisitNotesIDRecord {
    var correlationID: String
    var status: String
}

/// Where PropagateVisitNotesID hands each record.
protocol PropagateVisitNotesIDSink {
    func push(_ rec: PropagateVisitNotesIDRecord) async throws
}

/// Passes records to acme.itsm.v1.IncidentService.
struct PropagateVisitNotesIDIncident: PropagateVisitNotesIDSink {
    let client: Acme_Itsm_V1_IncidentService.Client<MeshTransport>

    func push(_ rec: PropagateVisitNotesIDRecord) async throws {
        _ = try await client.cloneIncident(.with {
            $0.incident.subject = rec.correlationID
            $0.requestID = rec.status
        })
    }
}

/// Passes records to acme.documents.v1.DocumentQueryService.
struct PropagateVisitNotesIDDocumentQuery: PropagateVisitNotesIDSink {
    let client: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>

    func push(_ rec: PropagateVisitNotesIDRecord) async throws {
        let request = Acme_Documents_V1_SummarizeDocumentsRequest.with {
            $0.details.cron = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.summarizeDocuments(request)
        }
    }
}

/// Writes records to acme.patients.v1.AllergySyncService.
struct PropagateVisitNotesIDAllergySync: PropagateVisitNotesIDSink {
    let client: Acme_Patients_V1_AllergySyncService.Client<MeshTransport>

    func push(_ rec: PropagateVisitNotesIDRecord) async throws {
        _ = try await client.syncAllergies(.with {
            $0.details.checksum = rec.status
        })
    }
}

/// Reads acme.telehealth.v1.VisitNoteQueryService/CountVisitNotes and hands what it keeps to the sink of its kind.
enum PropagateVisitNotesID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Telehealth_V1_VisitNoteQueryService.Client(wrapping: mesh)
        let response = try await reader.countVisitNotes(.with { $0.orderBy = "nightly-propagate-visit-notes-id" })
        let record = PropagateVisitNotesIDRecord(
            correlationID: response.result.correlationID,
            status: response.result.status
        )
        let sinks: [String: any PropagateVisitNotesIDSink] = [
            "incident": PropagateVisitNotesIDIncident(client: Acme_Itsm_V1_IncidentService.Client(wrapping: mesh)),
            "document-query": PropagateVisitNotesIDDocumentQuery(client: Acme_Documents_V1_DocumentQueryService.Client(wrapping: mesh)),
            "allergy-sync": PropagateVisitNotesIDAllergySync(client: Acme_Patients_V1_AllergySyncService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "allergy-sync" {
                continue
            }
            try await sink.push(record)
        }
    }
}
