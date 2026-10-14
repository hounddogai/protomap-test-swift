import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SyncMedicationCode keeps of each ApproveMedication response.
struct SyncMedicationCodeRecord {
    var code: String
    var status: String
    var referenceID: String
}

/// Where SyncMedicationCode hands each record.
protocol SyncMedicationCodeTarget {
    func deliver(_ rec: SyncMedicationCodeRecord) async throws
}

/// Hands records to acme.performance.v1.ReviewQueryService.
struct SyncMedicationCodeReviewQuery: SyncMedicationCodeTarget {
    let client: Acme_Performance_V1_ReviewQueryService.Client<MeshTransport>

    func deliver(_ rec: SyncMedicationCodeRecord) async throws {
        _ = try await client.summarizeReviews(.with {
            $0.reviewID = rec.referenceID
            $0.reason = rec.code
            $0.details.format = rec.status
        })
    }
}

/// Passes records to acme.appointments.v1.ClinicSlotApprovalService.
struct SyncMedicationCodeClinicSlotApproval: SyncMedicationCodeTarget {
    let client: Acme_Appointments_V1_ClinicSlotApprovalService.Client<MeshTransport>

    func deliver(_ rec: SyncMedicationCodeRecord) async throws {
        _ = try await client.recallClinicSlot(.with {
            $0.clinicSlotID = rec.status
            $0.clinicSlot.title = rec.referenceID
        })
    }
}

/// Reads acme.prescriptions.v1.MedicationApprovalService/ApproveMedication and hands what it keeps to the sink of its kind.
enum SyncMedicationCode {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Prescriptions_V1_MedicationApprovalService.Client(wrapping: mesh)
        let reply = try await origin.approveMedication(.with { $0.medicationID = "main-sync-medication-code" })
        let record = SyncMedicationCodeRecord(
            code: reply.medication.code,
            status: reply.outcome.status,
            referenceID: reply.outcome.referenceID
        )
        let sinks: [any SyncMedicationCodeTarget] = [
            SyncMedicationCodeReviewQuery(client: Acme_Performance_V1_ReviewQueryService.Client(wrapping: mesh)),
            SyncMedicationCodeClinicSlotApproval(client: Acme_Appointments_V1_ClinicSlotApprovalService.Client(wrapping: mesh)),
        ]
        for sink in sinks {
            try await sink.deliver(record)
        }
    }
}
