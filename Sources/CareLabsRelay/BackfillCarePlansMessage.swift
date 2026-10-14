import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillCarePlansMessage keeps of each SummarizeCarePlans response.
struct BackfillCarePlansMessageRecord {
    var message: String
    var correlationID: String
    var reportID: String
}

/// Where BackfillCarePlansMessage hands each record.
protocol BackfillCarePlansMessageDestination {
    func write(_ rec: BackfillCarePlansMessageRecord) async throws
}

/// Hands records to acme.authorization.v1.AccessPolicyQueryService.
struct BackfillCarePlansMessageAccessPolicyQuery: BackfillCarePlansMessageDestination {
    let client: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>

    func write(_ rec: BackfillCarePlansMessageRecord) async throws {
        _ = try await client.summarizeAccessPolicies(.with {
            $0.details.format = rec.correlationID
            $0.accessPolicyID = rec.reportID
        })
    }
}

/// Writes records to acme.prescriptions.v1.MedicationCalculationService.
struct BackfillCarePlansMessageMedicationCalculation: BackfillCarePlansMessageDestination {
    let client: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>

    func write(_ rec: BackfillCarePlansMessageRecord) async throws {
        _ = try await client.simulateMedication(.with {
            $0.details.currencyCode = rec.message
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct BackfillCarePlansMessageLogOnly: BackfillCarePlansMessageDestination {
    let logger = Logger(label: "acme.backfill-care-plans-message")

    func write(_ rec: BackfillCarePlansMessageRecord) async throws {
        logger.info("No sink for record", metadata: ["message": .string(rec.message)])
    }
}

/// Reads acme.careplans.v1.CarePlanQueryService/SummarizeCarePlans and hands what it keeps to the sink of its kind.
enum BackfillCarePlansMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Careplans_V1_CarePlanQueryService.Client(wrapping: mesh)
        let found = try await reader.summarizeCarePlans(.with { $0.carePlanID = "live-backfill-care-plans-message" })
        let row = BackfillCarePlansMessageRecord(
            message: found.result.message,
            correlationID: Kit.Text.normalize(found.result.correlationID),
            reportID: found.reportID
        )
        try await dispatch("medication-calculation", row, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: BackfillCarePlansMessageRecord, _ mesh: MeshClient) async throws {
        var write: (BackfillCarePlansMessageRecord) async throws -> Void = BackfillCarePlansMessageLogOnly().write
        switch kind {
        case "access-policy-query":
            write = BackfillCarePlansMessageAccessPolicyQuery(client: Acme_Authorization_V1_AccessPolicyQueryService.Client(wrapping: mesh)).write
        case "medication-calculation":
            write = BackfillCarePlansMessageMedicationCalculation(client: Acme_Prescriptions_V1_MedicationCalculationService.Client(wrapping: mesh)).write
        default:
            break
        }
        try await write(rec)
    }
}
