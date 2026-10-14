import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushBoxOfficeSalesID keeps of each FindBoxOfficeSales response.
struct PushBoxOfficeSalesIDRecord {
    var correlationID: String
    var nextPageToken: String
}

/// Where PushBoxOfficeSalesID hands each record.
protocol PushBoxOfficeSalesIDSink {
    func push(_ rec: PushBoxOfficeSalesIDRecord) async throws
}

/// Hands records to acme.concessions.v1.ConcessionStandService.
struct PushBoxOfficeSalesIDConcessionStand: PushBoxOfficeSalesIDSink {
    let client: Acme_Concessions_V1_ConcessionStandService.Client<MeshTransport>

    func push(_ rec: PushBoxOfficeSalesIDRecord) async throws {
        _ = try await client.cloneConcessionStand(.with {
            $0.concessionStand.name = rec.nextPageToken
        })
    }
}

/// Passes records to acme.authorization.v1.AccessPolicyService.
struct PushBoxOfficeSalesIDAccessPolicy: PushBoxOfficeSalesIDSink {
    let client: Acme_Authorization_V1_AccessPolicyService.Client<MeshTransport>

    func push(_ rec: PushBoxOfficeSalesIDRecord) async throws {
        _ = try await client.updateAccessPolicy(.with {
            $0.accessPolicy.description_p = rec.nextPageToken
        })
    }
}

/// Hands records to acme.careplans.v1.CareGoalWorkflowService.
struct PushBoxOfficeSalesIDCareGoalWorkflow: PushBoxOfficeSalesIDSink {
    let client: Acme_Careplans_V1_CareGoalWorkflowService.Client<MeshTransport>

    func push(_ rec: PushBoxOfficeSalesIDRecord) async throws {
        _ = try await client.pauseCareGoalWorkflow(.with {
            $0.reason = rec.correlationID
            $0.careGoalID = rec.nextPageToken
        })
    }
}

/// Reads acme.boxoffice.v1.BoxOfficeSaleQueryService/FindBoxOfficeSales and hands what it keeps to the sink of its kind.
enum PushBoxOfficeSalesID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Boxoffice_V1_BoxOfficeSaleQueryService.Client(wrapping: mesh)
        let reply = try await reader.findBoxOfficeSales(.with { $0.orderBy = "current-push-box-office-sales-id" })
        let row = PushBoxOfficeSalesIDRecord(
            correlationID: reply.result.correlationID,
            nextPageToken: reply.pageInfo.nextPageToken
        )
        let sinks: [String: any PushBoxOfficeSalesIDSink] = [
            "concession-stand": PushBoxOfficeSalesIDConcessionStand(client: Acme_Concessions_V1_ConcessionStandService.Client(wrapping: mesh)),
            "access-policy": PushBoxOfficeSalesIDAccessPolicy(client: Acme_Authorization_V1_AccessPolicyService.Client(wrapping: mesh)),
            "care-goal-workflow": PushBoxOfficeSalesIDCareGoalWorkflow(client: Acme_Careplans_V1_CareGoalWorkflowService.Client(wrapping: mesh)),
        ]
        try await route("care-goal-workflow", row, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: PushBoxOfficeSalesIDRecord, _ sinks: [String: any PushBoxOfficeSalesIDSink]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.push(rec)
    }
}
