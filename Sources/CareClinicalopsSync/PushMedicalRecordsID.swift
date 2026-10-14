import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushMedicalRecordsID keeps of each LintMedicalRecords response.
struct PushMedicalRecordsIDRecord {
    var medicalRecordID: String
    var message: String
    var resultMessage: String
    var correlationID: String
}

/// Where PushMedicalRecordsID hands each record.
protocol PushMedicalRecordsIDDestination {
    func forward(_ rec: PushMedicalRecordsIDRecord) async throws
}

/// Hands records to acme.careplans.v1.CarePlanLifecycleService.
struct PushMedicalRecordsIDCarePlanLifecycle: PushMedicalRecordsIDDestination {
    let client: Acme_Careplans_V1_CarePlanLifecycleService.Client<MeshTransport>

    func forward(_ rec: PushMedicalRecordsIDRecord) async throws {
        _ = try await client.activateCarePlan(.with {
            $0.details.reasonCode = rec.resultMessage
        })
    }
}

/// Writes records to acme.tours.v1.TourService.
struct PushMedicalRecordsIDTour: PushMedicalRecordsIDDestination {
    let client: Acme_Tours_V1_TourService.Client<MeshTransport>

    func forward(_ rec: PushMedicalRecordsIDRecord) async throws {
        _ = try await client.searchTours(.with {
            $0.filter.query = rec.correlationID
        })
    }
}

/// Hands records to acme.payments.v1.PaymentCalculationService.
struct PushMedicalRecordsIDPaymentCalculation: PushMedicalRecordsIDDestination {
    let client: Acme_Payments_V1_PaymentCalculationService.Client<MeshTransport>

    func forward(_ rec: PushMedicalRecordsIDRecord) async throws {
        _ = try await client.simulatePayment(.with {
            $0.payment.paymentID = rec.correlationID
        })
    }
}

/// Reads acme.patients.v1.MedicalRecordValidationService/LintMedicalRecords and hands what it keeps to the sink of its kind.
enum PushMedicalRecordsID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Patients_V1_MedicalRecordValidationService.Client(wrapping: mesh)
        let got = try await reader.lintMedicalRecords(.with { $0.medicalRecordID = "main-push-medical-records-id" })
        let entry = PushMedicalRecordsIDRecord(
            medicalRecordID: got.medicalRecord.medicalRecordID,
            message: Kit.Text.normalize(got.outcome.message),
            resultMessage: got.result.message,
            correlationID: got.result.correlationID
        )
        try await act("payment-calculation", entry, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: PushMedicalRecordsIDRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "care-plan-lifecycle": { try await PushMedicalRecordsIDCarePlanLifecycle(client: Acme_Careplans_V1_CarePlanLifecycleService.Client(wrapping: mesh)).forward(rec) },
            "tour": { try await PushMedicalRecordsIDTour(client: Acme_Tours_V1_TourService.Client(wrapping: mesh)).forward(rec) },
            "payment-calculation": { try await PushMedicalRecordsIDPaymentCalculation(client: Acme_Payments_V1_PaymentCalculationService.Client(wrapping: mesh)).forward(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
