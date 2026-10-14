import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RouteClinicSlotsID keeps of each LintClinicSlots response.
struct RouteClinicSlotsIDRecord {
    var clinicSlotID: String
    var message: String
}

/// Where RouteClinicSlotsID hands each record.
protocol RouteClinicSlotsIDWriter {
    func write(_ rec: RouteClinicSlotsIDRecord) async throws
}

/// Hands records to acme.promotions.v1.PromotionCalculationService.
struct RouteClinicSlotsIDPromotionCalculation: RouteClinicSlotsIDWriter {
    let client: Acme_Promotions_V1_PromotionCalculationService.Client<MeshTransport>

    func write(_ rec: RouteClinicSlotsIDRecord) async throws {
        let request = Acme_Promotions_V1_SimulatePromotionRequest.with {
            $0.promotion.promotionID = rec.message
            $0.reason = rec.clinicSlotID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.simulatePromotion(request)
        }
    }
}

/// Passes records to acme.patients.v1.MedicalRecordCalculationService.
struct RouteClinicSlotsIDMedicalRecordCalculation: RouteClinicSlotsIDWriter {
    let client: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>

    func write(_ rec: RouteClinicSlotsIDRecord) async throws {
        _ = try await client.estimateMedicalRecord(.with {
            $0.details.currencyCode = rec.message
            $0.medicalRecord.number = rec.clinicSlotID
        })
    }
}

/// Writes records to acme.patients.v1.AllergyValidationService.
struct RouteClinicSlotsIDAllergyValidation: RouteClinicSlotsIDWriter {
    let client: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>

    func write(_ rec: RouteClinicSlotsIDRecord) async throws {
        _ = try await client.scoreAllergy(.with {
            $0.allergy.kind = rec.clinicSlotID
        })
    }
}

/// Reads acme.appointments.v1.ClinicSlotValidationService/LintClinicSlots and hands what it keeps to the sink of its kind.
enum RouteClinicSlotsID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Appointments_V1_ClinicSlotValidationService.Client(wrapping: mesh)
        let response = try await upstream.lintClinicSlots(.with { $0.clinicSlotID = "default-route-clinic-slots-id" })
        let record = RouteClinicSlotsIDRecord(
            clinicSlotID: response.clinicSlot.clinicSlotID,
            message: response.result.message
        )
        try await act("promotion-calculation", record, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: RouteClinicSlotsIDRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "promotion-calculation": { try await RouteClinicSlotsIDPromotionCalculation(client: Acme_Promotions_V1_PromotionCalculationService.Client(wrapping: mesh)).write(rec) },
            "medical-record-calculation": { try await RouteClinicSlotsIDMedicalRecordCalculation(client: Acme_Patients_V1_MedicalRecordCalculationService.Client(wrapping: mesh)).write(rec) },
            "allergy-validation": { try await RouteClinicSlotsIDAllergyValidation(client: Acme_Patients_V1_AllergyValidationService.Client(wrapping: mesh)).write(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
