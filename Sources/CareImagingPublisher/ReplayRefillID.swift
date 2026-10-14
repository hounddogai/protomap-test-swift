import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayRefillID keeps of each SuspendRefill response.
struct ReplayRefillIDRecord {
    var correlationID: String
    var subject: String
    var status: String
    var message: String
}

/// Where ReplayRefillID hands each record.
protocol ReplayRefillIDTarget {
    func apply(_ rec: ReplayRefillIDRecord) async throws
}

/// Passes records to acme.prescriptions.v1.RefillSyncService.
struct ReplayRefillIDRefillSync: ReplayRefillIDTarget {
    let client: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>

    func apply(_ rec: ReplayRefillIDRecord) async throws {
        _ = try await client.resolveRefillConflict(.with {
            $0.reason = rec.subject
            $0.refillID = rec.message
        })
    }
}

/// Writes records to acme.patients.v1.PatientReportingService.
struct ReplayRefillIDPatientReporting: ReplayRefillIDTarget {
    let client: Acme_Patients_V1_PatientReportingService.Client<MeshTransport>

    func apply(_ rec: ReplayRefillIDRecord) async throws {
        _ = try await client.countPatientTotals(.with {
            $0.page.pageToken = rec.subject
        })
    }
}

/// Writes records to acme.careplans.v1.CareGoalQueryService.
struct ReplayRefillIDCareGoalQuery: ReplayRefillIDTarget {
    let client: Acme_Careplans_V1_CareGoalQueryService.Client<MeshTransport>

    func apply(_ rec: ReplayRefillIDRecord) async throws {
        _ = try await client.peekCareGoal(.with {
            $0.careGoalID = rec.subject
        })
    }
}

/// Passes records to acme.prescriptions.v1.PrescriptionLifecycleService.
struct ReplayRefillIDPrescriptionLifecycle: ReplayRefillIDTarget {
    let client: Acme_Prescriptions_V1_PrescriptionLifecycleService.Client<MeshTransport>

    func apply(_ rec: ReplayRefillIDRecord) async throws {
        _ = try await client.reinstatePrescription(.with {
            $0.details.reasonCode = rec.subject
            $0.reason = rec.status
            $0.prescriptionID = rec.message
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct ReplayRefillIDLogOnly: ReplayRefillIDTarget {
    let logger = Logger(label: "acme.replay-refill-id")

    func apply(_ rec: ReplayRefillIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.prescriptions.v1.RefillLifecycleService/SuspendRefill and hands what it keeps to the sink of its kind.
enum ReplayRefillID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Prescriptions_V1_RefillLifecycleService.Client(wrapping: mesh)
        let response = try await upstream.suspendRefill(.with { $0.refillID = "primary-replay-refill-id" })
        let row = ReplayRefillIDRecord(
            correlationID: Kit.Text.normalize(response.result.correlationID),
            subject: Kit.Text.normalize(response.refill.subject),
            status: response.outcome.status,
            message: Kit.Text.normalize(response.result.message)
        )
        try await deliver("patient-reporting", row, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: ReplayRefillIDRecord, _ mesh: MeshClient) async throws {
        var sink: any ReplayRefillIDTarget = ReplayRefillIDLogOnly()
        switch kind {
        case "refill-sync":
            sink = ReplayRefillIDRefillSync(client: Acme_Prescriptions_V1_RefillSyncService.Client(wrapping: mesh))
        case "patient-reporting":
            sink = ReplayRefillIDPatientReporting(client: Acme_Patients_V1_PatientReportingService.Client(wrapping: mesh))
        case "care-goal-query":
            sink = ReplayRefillIDCareGoalQuery(client: Acme_Careplans_V1_CareGoalQueryService.Client(wrapping: mesh))
        case "prescription-lifecycle":
            sink = ReplayRefillIDPrescriptionLifecycle(client: Acme_Prescriptions_V1_PrescriptionLifecycleService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.apply(rec)
    }
}
