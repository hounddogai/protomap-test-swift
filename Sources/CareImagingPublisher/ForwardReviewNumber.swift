import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardReviewNumber keeps of each LookupReview response.
struct ForwardReviewNumberRecord {
    var number: String
    var status: String
}

/// Where ForwardReviewNumber hands each record.
protocol ForwardReviewNumberTarget {
    func deliver(_ rec: ForwardReviewNumberRecord) async throws
}

/// Hands records to acme.patientapp.v1.PatientHomeQueryService.
struct ForwardReviewNumberPatientHomeQuery: ForwardReviewNumberTarget {
    let client: Acme_Patientapp_V1_PatientHomeQueryService.Client<MeshTransport>

    func deliver(_ rec: ForwardReviewNumberRecord) async throws {
        _ = try await client.findPatientHomes(.with {
            $0.orderBy = rec.status
            $0.filter.ownerID = rec.number
        })
    }
}

/// Hands records to acme.appointments.v1.ClinicSlotValidationService.
struct ForwardReviewNumberClinicSlotValidation: ForwardReviewNumberTarget {
    let client: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>

    func deliver(_ rec: ForwardReviewNumberRecord) async throws {
        let request = Acme_Appointments_V1_ValidateClinicSlotRequest.with {
            $0.details.locale = rec.number
            $0.clinicSlotID = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.validateClinicSlot(request)
        }
    }
}

/// Hands records to acme.patients.v1.MedicalRecordCalculationService.
struct ForwardReviewNumberMedicalRecordCalculation: ForwardReviewNumberTarget {
    let client: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>

    func deliver(_ rec: ForwardReviewNumberRecord) async throws {
        let request = Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.with {
            $0.medicalRecord.medicalRecordID = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.explainMedicalRecordCalculation(request)
        }
    }
}

/// Reads acme.performance.v1.ReviewQueryService/LookupReview and hands what it keeps to the sink of its kind.
enum ForwardReviewNumber {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Performance_V1_ReviewQueryService.Client(wrapping: mesh)
        let reply = try await upstream.lookupReview(.with { $0.reviewID = "current-forward-review-number" })
        let entry = ForwardReviewNumberRecord(
            number: reply.review.number,
            status: reply.result.status
        )
        let sinks: [String: any ForwardReviewNumberTarget] = [
            "patient-home-query": ForwardReviewNumberPatientHomeQuery(client: Acme_Patientapp_V1_PatientHomeQueryService.Client(wrapping: mesh)),
            "clinic-slot-validation": ForwardReviewNumberClinicSlotValidation(client: Acme_Appointments_V1_ClinicSlotValidationService.Client(wrapping: mesh)),
            "medical-record-calculation": ForwardReviewNumberMedicalRecordCalculation(client: Acme_Patients_V1_MedicalRecordCalculationService.Client(wrapping: mesh)),
        ]
        try await route("medical-record-calculation", entry, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: ForwardReviewNumberRecord, _ sinks: [String: any ForwardReviewNumberTarget]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.deliver(rec)
    }
}
