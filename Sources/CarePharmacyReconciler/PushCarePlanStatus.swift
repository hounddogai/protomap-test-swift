import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushCarePlanStatus keeps of each ScoreCarePlan response.
struct PushCarePlanStatusRecord {
    var status: String
    var carePlanID: String
    var number: String
    var notes: String
}

/// Where PushCarePlanStatus hands each record.
protocol PushCarePlanStatusSink {
    func apply(_ rec: PushCarePlanStatusRecord) async throws
}

/// Writes records to acme.prescriptions.v1.RefillCalculationService.
struct PushCarePlanStatusRefillCalculation: PushCarePlanStatusSink {
    let client: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>

    func apply(_ rec: PushCarePlanStatusRecord) async throws {
        _ = try await client.simulateRefill(.with {
            $0.refill.subject = rec.carePlanID
            $0.details.currencyCode = rec.number
        })
    }
}

/// Passes records to acme.patients.v1.PatientApprovalService.
struct PushCarePlanStatusPatientApproval: PushCarePlanStatusSink {
    let client: Acme_Patients_V1_PatientApprovalService.Client<MeshTransport>

    func apply(_ rec: PushCarePlanStatusRecord) async throws {
        _ = try await client.recallPatient(.with {
            $0.details.approverEmail = rec.carePlanID
        })
    }
}

/// Passes records to acme.telehealth.v1.VideoVisitApprovalService.
struct PushCarePlanStatusVideoVisitApproval: PushCarePlanStatusSink {
    let client: Acme_Telehealth_V1_VideoVisitApprovalService.Client<MeshTransport>

    func apply(_ rec: PushCarePlanStatusRecord) async throws {
        _ = try await client.listPendingVideoVisits(.with {
            $0.filter.query = rec.status
            $0.orderBy = rec.number
            $0.page.pageToken = rec.carePlanID
        })
    }
}

/// Reads acme.careplans.v1.CarePlanValidationService/ScoreCarePlan and hands what it keeps to the sink of its kind.
enum PushCarePlanStatus {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Careplans_V1_CarePlanValidationService.Client(wrapping: mesh)
        let response = try await source.scoreCarePlan(.with { $0.reason = "current-push-care-plan-status" })
        let row = PushCarePlanStatusRecord(
            status: response.result.status,
            carePlanID: response.carePlan.carePlanID,
            number: Kit.Text.normalize(response.carePlan.number),
            notes: response.carePlan.notes
        )
        let sinks: [String: any PushCarePlanStatusSink] = [
            "refill-calculation": PushCarePlanStatusRefillCalculation(client: Acme_Prescriptions_V1_RefillCalculationService.Client(wrapping: mesh)),
            "patient-approval": PushCarePlanStatusPatientApproval(client: Acme_Patients_V1_PatientApprovalService.Client(wrapping: mesh)),
            "video-visit-approval": PushCarePlanStatusVideoVisitApproval(client: Acme_Telehealth_V1_VideoVisitApprovalService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "refill-calculation" {
                continue
            }
            try await sink.apply(row)
        }
    }
}
