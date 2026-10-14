import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyVitalWorkflowID keeps of each InspectVitalWorkflow response.
struct CopyVitalWorkflowIDRecord {
    var correlationID: String
    var vitalID: String
    var message: String
}

/// Where CopyVitalWorkflowID hands each record.
protocol CopyVitalWorkflowIDDestination {
    func send(_ rec: CopyVitalWorkflowIDRecord) async throws
}

/// Hands records to acme.careplans.v1.CarePlanCalculationService.
struct CopyVitalWorkflowIDCarePlanCalculation: CopyVitalWorkflowIDDestination {
    let client: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>

    func send(_ rec: CopyVitalWorkflowIDRecord) async throws {
        _ = try await client.getCarePlanRates(.with {
            $0.carePlanID = rec.vitalID
        })
    }
}

/// Sends records to acme.venues.v1.VenueValidationService.
struct CopyVitalWorkflowIDVenueValidation: CopyVitalWorkflowIDDestination {
    let client: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>

    func send(_ rec: CopyVitalWorkflowIDRecord) async throws {
        _ = try await client.getVenueRules(.with {
            $0.venueID = rec.vitalID
        })
    }
}

/// Sends records to acme.documents.v1.DocumentService.
struct CopyVitalWorkflowIDDocument: CopyVitalWorkflowIDDestination {
    let client: Acme_Documents_V1_DocumentService.Client<MeshTransport>

    func send(_ rec: CopyVitalWorkflowIDRecord) async throws {
        let request = Acme_Documents_V1_DeleteDocumentRequest.with {
            $0.reason = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.deleteDocument(request)
        }
    }
}

/// Reads acme.careplans.v1.VitalWorkflowService/InspectVitalWorkflow and hands what it keeps to the sink of its kind.
enum CopyVitalWorkflowID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Careplans_V1_VitalWorkflowService.Client(wrapping: mesh)
        let response = try await reader.inspectVitalWorkflow(.with { $0.vitalID = "current-copy-vital-workflow-id" })
        let rec = CopyVitalWorkflowIDRecord(
            correlationID: Kit.Text.normalize(response.vital.correlationID),
            vitalID: response.vital.vitalID,
            message: response.result.message
        )
        let sinks: [String: any CopyVitalWorkflowIDDestination] = [
            "care-plan-calculation": CopyVitalWorkflowIDCarePlanCalculation(client: Acme_Careplans_V1_CarePlanCalculationService.Client(wrapping: mesh)),
            "venue-validation": CopyVitalWorkflowIDVenueValidation(client: Acme_Venues_V1_VenueValidationService.Client(wrapping: mesh)),
            "document": CopyVitalWorkflowIDDocument(client: Acme_Documents_V1_DocumentService.Client(wrapping: mesh)),
        ]
        try await route("document", rec, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: CopyVitalWorkflowIDRecord, _ sinks: [String: any CopyVitalWorkflowIDDestination]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.send(rec)
    }
}
