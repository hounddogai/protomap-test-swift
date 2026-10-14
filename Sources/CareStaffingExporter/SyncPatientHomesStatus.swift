import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SyncPatientHomesStatus keeps of each SearchPatientHomes response.
struct SyncPatientHomesStatusRecord {
    var status: String
    var message: String
    var nextPageToken: String
}

/// Where SyncPatientHomesStatus hands each record.
protocol SyncPatientHomesStatusSink {
    func push(_ rec: SyncPatientHomesStatusRecord) async throws
}

/// Sends records to acme.prescriptions.v1.RefillApprovalService.
struct SyncPatientHomesStatusRefillApproval: SyncPatientHomesStatusSink {
    let client: Acme_Prescriptions_V1_RefillApprovalService.Client<MeshTransport>

    func push(_ rec: SyncPatientHomesStatusRecord) async throws {
        _ = try await client.submitRefill(.with {
            $0.refillID = rec.status
        })
    }
}

/// Sends records to acme.prescriptions.v1.MedicationCalculationService.
struct SyncPatientHomesStatusMedicationCalculation: SyncPatientHomesStatusSink {
    let client: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>

    func push(_ rec: SyncPatientHomesStatusRecord) async throws {
        _ = try await client.getMedicationRates(.with {
            $0.medicationID = rec.message
        })
    }
}

/// Writes records to acme.careplans.v1.CarePlanValidationService.
struct SyncPatientHomesStatusCarePlanValidation: SyncPatientHomesStatusSink {
    let client: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>

    func push(_ rec: SyncPatientHomesStatusRecord) async throws {
        _ = try await client.explainCarePlanDecision(.with {
            $0.carePlan.number = rec.status
            $0.carePlanID = rec.nextPageToken
            $0.carePlan.notes = rec.message
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct SyncPatientHomesStatusLogOnly: SyncPatientHomesStatusSink {
    let logger = Logger(label: "acme.sync-patient-homes-status")

    func push(_ rec: SyncPatientHomesStatusRecord) async throws {
        logger.info("No sink for record", metadata: ["status": .string(rec.status)])
    }
}

/// Reads acme.patientapp.v1.PatientHomeService/SearchPatientHomes and hands what it keeps to the sink of its kind.
enum SyncPatientHomesStatus {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Patientapp_V1_PatientHomeService.Client(wrapping: mesh)
        let reply = try await origin.searchPatientHomes(.with { $0.orderBy = "primary-sync-patient-homes-status" })
        let row = SyncPatientHomesStatusRecord(
            status: reply.result.status,
            message: reply.result.message,
            nextPageToken: reply.pageInfo.nextPageToken
        )
        try await dispatch("medication-calculation", row, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: SyncPatientHomesStatusRecord, _ mesh: MeshClient) async throws {
        var write: (SyncPatientHomesStatusRecord) async throws -> Void = SyncPatientHomesStatusLogOnly().push
        switch kind {
        case "refill-approval":
            write = SyncPatientHomesStatusRefillApproval(client: Acme_Prescriptions_V1_RefillApprovalService.Client(wrapping: mesh)).push
        case "medication-calculation":
            write = SyncPatientHomesStatusMedicationCalculation(client: Acme_Prescriptions_V1_MedicationCalculationService.Client(wrapping: mesh)).push
        case "care-plan-validation":
            write = SyncPatientHomesStatusCarePlanValidation(client: Acme_Careplans_V1_CarePlanValidationService.Client(wrapping: mesh)).push
        default:
            break
        }
        try await write(rec)
    }
}
