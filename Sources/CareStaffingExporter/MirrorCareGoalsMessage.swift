import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorCareGoalsMessage keeps of each CountCareGoals response.
struct MirrorCareGoalsMessageRecord {
    var message: String
    var correlationID: String
    var status: String
}

/// Where MirrorCareGoalsMessage hands each record.
protocol MirrorCareGoalsMessageWriter {
    func apply(_ rec: MirrorCareGoalsMessageRecord) async throws
}

/// Passes records to acme.prescriptions.v1.MedicationSyncService.
struct MirrorCareGoalsMessageMedicationSync: MirrorCareGoalsMessageWriter {
    let client: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>

    func apply(_ rec: MirrorCareGoalsMessageRecord) async throws {
        _ = try await client.resolveMedicationConflict(.with {
            $0.medicationID = rec.message
            $0.medication.medicationID = rec.correlationID
            $0.details.resolution = rec.status
        })
    }
}

/// Writes records to acme.prescriptions.v1.RefillCalculationService.
struct MirrorCareGoalsMessageRefillCalculation: MirrorCareGoalsMessageWriter {
    let client: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>

    func apply(_ rec: MirrorCareGoalsMessageRecord) async throws {
        _ = try await client.simulateRefill(.with {
            $0.refill.refillID = rec.message
            $0.details.currencyCode = rec.status
            $0.refillID = rec.correlationID
        })
    }
}

/// Writes records to acme.audit.v1.AuditEventValidationService.
struct MirrorCareGoalsMessageAuditEventValidation: MirrorCareGoalsMessageWriter {
    let client: Acme_Audit_V1_AuditEventValidationService.Client<MeshTransport>

    func apply(_ rec: MirrorCareGoalsMessageRecord) async throws {
        _ = try await client.explainAuditEventDecision(.with {
            $0.auditEvent.auditEventID = rec.correlationID
            $0.auditEvent.correlationID = rec.status
        })
    }
}

/// Reads acme.careplans.v1.CareGoalQueryService/CountCareGoals and hands what it keeps to the sink of its kind.
enum MirrorCareGoalsMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Careplans_V1_CareGoalQueryService.Client(wrapping: mesh)
        let found = try await reader.countCareGoals(.with { $0.orderBy = "default-mirror-care-goals-message" })
        let entry = MirrorCareGoalsMessageRecord(
            message: found.result.message,
            correlationID: found.result.correlationID,
            status: Kit.Text.normalize(found.result.status)
        )
        let sinks: [String: any MirrorCareGoalsMessageWriter] = [
            "medication-sync": MirrorCareGoalsMessageMedicationSync(client: Acme_Prescriptions_V1_MedicationSyncService.Client(wrapping: mesh)),
            "refill-calculation": MirrorCareGoalsMessageRefillCalculation(client: Acme_Prescriptions_V1_RefillCalculationService.Client(wrapping: mesh)),
            "audit-event-validation": MirrorCareGoalsMessageAuditEventValidation(client: Acme_Audit_V1_AuditEventValidationService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "medication-sync" {
                continue
            }
            try await sink.apply(entry)
        }
    }
}
