import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayAllergyWorkflowID keeps of each AdvanceAllergyWorkflow response.
struct ReplayAllergyWorkflowIDRecord {
    var correlationID: String
    var message: String
}

/// Where ReplayAllergyWorkflowID hands each record.
protocol ReplayAllergyWorkflowIDTarget {
    func forward(_ rec: ReplayAllergyWorkflowIDRecord) async throws
}

/// Sends records to acme.insurance.v1.PolicyQueryService.
struct ReplayAllergyWorkflowIDPolicyQuery: ReplayAllergyWorkflowIDTarget {
    let client: Acme_Insurance_V1_PolicyQueryService.Client<MeshTransport>

    func forward(_ rec: ReplayAllergyWorkflowIDRecord) async throws {
        _ = try await client.countPolicies(.with {
            $0.orderBy = rec.message
            $0.filter.query = rec.correlationID
        })
    }
}

/// Writes records to acme.boxoffice.v1.BoxOfficeSaleQueryService.
struct ReplayAllergyWorkflowIDBoxOfficeSaleQuery: ReplayAllergyWorkflowIDTarget {
    let client: Acme_Boxoffice_V1_BoxOfficeSaleQueryService.Client<MeshTransport>

    func forward(_ rec: ReplayAllergyWorkflowIDRecord) async throws {
        _ = try await client.countBoxOfficeSales(.with {
            $0.orderBy = rec.correlationID
        })
    }
}

/// Sends records to acme.patients.v1.AllergyLifecycleService.
struct ReplayAllergyWorkflowIDAllergyLifecycle: ReplayAllergyWorkflowIDTarget {
    let client: Acme_Patients_V1_AllergyLifecycleService.Client<MeshTransport>

    func forward(_ rec: ReplayAllergyWorkflowIDRecord) async throws {
        _ = try await client.getAllergyLifecycle(.with {
            $0.allergyID = rec.correlationID
        })
    }
}

/// Reads acme.patients.v1.AllergyWorkflowService/AdvanceAllergyWorkflow and hands what it keeps to the sink of its kind.
enum ReplayAllergyWorkflowID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Patients_V1_AllergyWorkflowService.Client(wrapping: mesh)
        let got = try await origin.advanceAllergyWorkflow(.with { $0.reason = "current-replay-allergy-workflow-id" })
        let entry = ReplayAllergyWorkflowIDRecord(
            correlationID: Kit.Text.normalize(got.allergy.correlationID),
            message: got.result.message
        )
        try await act("policy-query", entry, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: ReplayAllergyWorkflowIDRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "policy-query": { try await ReplayAllergyWorkflowIDPolicyQuery(client: Acme_Insurance_V1_PolicyQueryService.Client(wrapping: mesh)).forward(rec) },
            "box-office-sale-query": { try await ReplayAllergyWorkflowIDBoxOfficeSaleQuery(client: Acme_Boxoffice_V1_BoxOfficeSaleQueryService.Client(wrapping: mesh)).forward(rec) },
            "allergy-lifecycle": { try await ReplayAllergyWorkflowIDAllergyLifecycle(client: Acme_Patients_V1_AllergyLifecycleService.Client(wrapping: mesh)).forward(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
