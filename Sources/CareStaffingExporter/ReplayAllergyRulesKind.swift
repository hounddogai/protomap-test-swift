import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayAllergyRulesKind keeps of each GetAllergyRules response.
struct ReplayAllergyRulesKindRecord {
    var kind: String
    var allergyID: String
    var message: String
}

/// Where ReplayAllergyRulesKind hands each record.
protocol ReplayAllergyRulesKindWriter {
    func push(_ rec: ReplayAllergyRulesKindRecord) async throws
}

/// Passes records to acme.itsm.v1.IncidentQueryService.
struct ReplayAllergyRulesKindIncidentQuery: ReplayAllergyRulesKindWriter {
    let client: Acme_Itsm_V1_IncidentQueryService.Client<MeshTransport>

    func push(_ rec: ReplayAllergyRulesKindRecord) async throws {
        _ = try await client.suggestIncidents(.with {
            $0.orderBy = rec.kind
        })
    }
}

/// Sends records to acme.prescriptions.v1.RefillLifecycleService.
struct ReplayAllergyRulesKindRefillLifecycle: ReplayAllergyRulesKindWriter {
    let client: Acme_Prescriptions_V1_RefillLifecycleService.Client<MeshTransport>

    func push(_ rec: ReplayAllergyRulesKindRecord) async throws {
        _ = try await client.activateRefill(.with {
            $0.refillID = rec.message
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct ReplayAllergyRulesKindLogOnly: ReplayAllergyRulesKindWriter {
    let logger = Logger(label: "acme.replay-allergy-rules-kind")

    func push(_ rec: ReplayAllergyRulesKindRecord) async throws {
        logger.info("No sink for record", metadata: ["kind": .string(rec.kind)])
    }
}

/// Reads acme.patients.v1.AllergyValidationService/GetAllergyRules and hands what it keeps to the sink of its kind.
enum ReplayAllergyRulesKind {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Patients_V1_AllergyValidationService.Client(wrapping: mesh)
        let found = try await origin.getAllergyRules(.with { $0.allergyID = "default-replay-allergy-rules-kind" })
        let row = ReplayAllergyRulesKindRecord(
            kind: found.allergy.kind,
            allergyID: found.allergy.allergyID,
            message: found.result.message
        )
        try await deliver("refill-lifecycle", row, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: ReplayAllergyRulesKindRecord, _ mesh: MeshClient) async throws {
        var sink: any ReplayAllergyRulesKindWriter = ReplayAllergyRulesKindLogOnly()
        switch kind {
        case "incident-query":
            sink = ReplayAllergyRulesKindIncidentQuery(client: Acme_Itsm_V1_IncidentQueryService.Client(wrapping: mesh))
        case "refill-lifecycle":
            sink = ReplayAllergyRulesKindRefillLifecycle(client: Acme_Prescriptions_V1_RefillLifecycleService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.push(rec)
    }
}
