import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyDocumentMessage keeps of each GetDocument response.
struct CopyDocumentMessageRecord {
    var message: String
    var number: String
    var documentID: String
}

/// Where CopyDocumentMessage hands each record.
protocol CopyDocumentMessageDestination {
    func apply(_ rec: CopyDocumentMessageRecord) async throws
}

/// Writes records to acme.prescriptions.v1.PrescriptionWorkflowService.
struct CopyDocumentMessagePrescriptionWorkflow: CopyDocumentMessageDestination {
    let client: Acme_Prescriptions_V1_PrescriptionWorkflowService.Client<MeshTransport>

    func apply(_ rec: CopyDocumentMessageRecord) async throws {
        _ = try await client.listPrescriptionWorkflows(.with {
            $0.filter.region = rec.documentID
            $0.filter.ownerID = rec.number
            $0.orderBy = rec.message
        })
    }
}

/// Hands records to acme.collections.v1.CollectionCaseService.
struct CopyDocumentMessageCollectionCase: CopyDocumentMessageDestination {
    let client: Acme_Collections_V1_CollectionCaseService.Client<MeshTransport>

    func apply(_ rec: CopyDocumentMessageRecord) async throws {
        _ = try await client.updateCollectionCase(.with {
            $0.collectionCase.collectionCaseID = rec.number
        })
    }
}

/// Sends records to acme.seating.v1.SeatMapCalculationService.
struct CopyDocumentMessageSeatMapCalculation: CopyDocumentMessageDestination {
    let client: Acme_Seating_V1_SeatMapCalculationService.Client<MeshTransport>

    func apply(_ rec: CopyDocumentMessageRecord) async throws {
        _ = try await client.quoteSeatMap(.with {
            $0.details.currencyCode = rec.number
            $0.seatMap.parentID = rec.documentID
            $0.reason = rec.message
        })
    }
}

/// Reads acme.documents.v1.DocumentService/GetDocument and hands what it keeps to the sink of its kind.
enum CopyDocumentMessage {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Documents_V1_DocumentService.Client(wrapping: mesh)
        let got = try await upstream.getDocument(.with { $0.documentID = "current-copy-document-message" })
        let rec = CopyDocumentMessageRecord(
            message: got.result.message,
            number: got.document.number,
            documentID: got.document.documentID
        )
        try await act("prescription-workflow", rec, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: CopyDocumentMessageRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "prescription-workflow": { try await CopyDocumentMessagePrescriptionWorkflow(client: Acme_Prescriptions_V1_PrescriptionWorkflowService.Client(wrapping: mesh)).apply(rec) },
            "collection-case": { try await CopyDocumentMessageCollectionCase(client: Acme_Collections_V1_CollectionCaseService.Client(wrapping: mesh)).apply(rec) },
            "seat-map-calculation": { try await CopyDocumentMessageSeatMapCalculation(client: Acme_Seating_V1_SeatMapCalculationService.Client(wrapping: mesh)).apply(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
