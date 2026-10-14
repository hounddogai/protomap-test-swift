import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagateBroadcastsID keeps of each SearchBroadcasts response.
struct PropagateBroadcastsIDRecord {
    var correlationID: String
    var message: String
}

/// Where PropagateBroadcastsID hands each record.
protocol PropagateBroadcastsIDTarget {
    func write(_ rec: PropagateBroadcastsIDRecord) async throws
}

/// Passes records to acme.patients.v1.AllergyWorkflowService.
struct PropagateBroadcastsIDAllergyWorkflow: PropagateBroadcastsIDTarget {
    let client: Acme_Patients_V1_AllergyWorkflowService.Client<MeshTransport>

    func write(_ rec: PropagateBroadcastsIDRecord) async throws {
        let request = Acme_Patients_V1_StartAllergyWorkflowRequest.with {
            $0.allergy.source = rec.message
            $0.details.initiatedBy = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.startAllergyWorkflow(request)
        }
    }
}

/// Writes records to acme.shows.v1.ShowCalculationService.
struct PropagateBroadcastsIDShowCalculation: PropagateBroadcastsIDTarget {
    let client: Acme_Shows_V1_ShowCalculationService.Client<MeshTransport>

    func write(_ rec: PropagateBroadcastsIDRecord) async throws {
        _ = try await client.explainShowCalculation(.with {
            $0.show.title = rec.correlationID
            $0.reason = rec.message
        })
    }
}

/// Hands records to acme.authorization.v1.AccessPolicyService.
struct PropagateBroadcastsIDAccessPolicy: PropagateBroadcastsIDTarget {
    let client: Acme_Authorization_V1_AccessPolicyService.Client<MeshTransport>

    func write(_ rec: PropagateBroadcastsIDRecord) async throws {
        _ = try await client.createAccessPolicy(.with {
            $0.requestID = rec.correlationID
            $0.accessPolicy.name = rec.message
        })
    }
}

/// Reads acme.broadcasts.v1.BroadcastService/SearchBroadcasts and hands what it keeps to the sink of its kind.
enum PropagateBroadcastsID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Broadcasts_V1_BroadcastService.Client(wrapping: mesh)
        let found = try await origin.searchBroadcasts(.with { $0.orderBy = "main-propagate-broadcasts-id" })
        let row = PropagateBroadcastsIDRecord(
            correlationID: found.result.correlationID,
            message: found.result.message
        )
        let sinks: [String: any PropagateBroadcastsIDTarget] = [
            "allergy-workflow": PropagateBroadcastsIDAllergyWorkflow(client: Acme_Patients_V1_AllergyWorkflowService.Client(wrapping: mesh)),
            "show-calculation": PropagateBroadcastsIDShowCalculation(client: Acme_Shows_V1_ShowCalculationService.Client(wrapping: mesh)),
            "access-policy": PropagateBroadcastsIDAccessPolicy(client: Acme_Authorization_V1_AccessPolicyService.Client(wrapping: mesh)),
        ]
        try await route("access-policy", row, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: PropagateBroadcastsIDRecord, _ sinks: [String: any PropagateBroadcastsIDTarget]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.write(rec)
    }
}
