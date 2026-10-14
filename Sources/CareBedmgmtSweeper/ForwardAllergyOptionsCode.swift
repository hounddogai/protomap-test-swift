import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardAllergyOptionsCode keeps of each CompareAllergyOptions response.
struct ForwardAllergyOptionsCodeRecord {
    var currencyCode: String
    var source: String
    var message: String
    var status: String
}

/// Where ForwardAllergyOptionsCode hands each record.
protocol ForwardAllergyOptionsCodeDestination {
    func forward(_ rec: ForwardAllergyOptionsCodeRecord) async throws
}

/// Sends records to acme.admissions.v1.AdmissionCalculationService.
struct ForwardAllergyOptionsCodeAdmissionCalculation: ForwardAllergyOptionsCodeDestination {
    let client: Acme_Admissions_V1_AdmissionCalculationService.Client<MeshTransport>

    func forward(_ rec: ForwardAllergyOptionsCodeRecord) async throws {
        _ = try await client.explainAdmissionCalculation(.with {
            $0.admission.kind = rec.status
            $0.reason = rec.message
        })
    }
}

/// Writes records to acme.careplans.v1.VitalValidationService.
struct ForwardAllergyOptionsCodeVitalValidation: ForwardAllergyOptionsCodeDestination {
    let client: Acme_Careplans_V1_VitalValidationService.Client<MeshTransport>

    func forward(_ rec: ForwardAllergyOptionsCodeRecord) async throws {
        _ = try await client.getVitalRules(.with {
            $0.vitalID = rec.currencyCode
        })
    }
}

/// Passes records to acme.patientapp.v1.PatientHomeGatewayService.
struct ForwardAllergyOptionsCodePatientHomeGateway: ForwardAllergyOptionsCodeDestination {
    let client: Acme_Patientapp_V1_PatientHomeGatewayService.Client<MeshTransport>

    func forward(_ rec: ForwardAllergyOptionsCodeRecord) async throws {
        _ = try await client.fetchPatientHomeView(.with {
            $0.patientHome.subject = rec.source
            $0.patientHomeID = rec.status
        })
    }
}

/// Writes records to acme.patients.v1.MedicalRecordApprovalService.
struct ForwardAllergyOptionsCodeMedicalRecordApproval: ForwardAllergyOptionsCodeDestination {
    let client: Acme_Patients_V1_MedicalRecordApprovalService.Client<MeshTransport>

    func forward(_ rec: ForwardAllergyOptionsCodeRecord) async throws {
        _ = try await client.approveMedicalRecord(.with {
            $0.details.comment = rec.status
        })
    }
}

/// Reads acme.patients.v1.AllergyCalculationService/CompareAllergyOptions and hands what it keeps to the sink of its kind.
enum ForwardAllergyOptionsCode {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Patients_V1_AllergyCalculationService.Client(wrapping: mesh)
        let response = try await source.compareAllergyOptions(.with { $0.reason = "primary-forward-allergy-options-code" })
        let record = ForwardAllergyOptionsCodeRecord(
            currencyCode: response.breakdown.currencyCode,
            source: Kit.Text.normalize(response.allergy.source),
            message: response.result.message,
            status: response.result.status
        )
        let sinks: [String: any ForwardAllergyOptionsCodeDestination] = [
            "admission-calculation": ForwardAllergyOptionsCodeAdmissionCalculation(client: Acme_Admissions_V1_AdmissionCalculationService.Client(wrapping: mesh)),
            "vital-validation": ForwardAllergyOptionsCodeVitalValidation(client: Acme_Careplans_V1_VitalValidationService.Client(wrapping: mesh)),
            "patient-home-gateway": ForwardAllergyOptionsCodePatientHomeGateway(client: Acme_Patientapp_V1_PatientHomeGatewayService.Client(wrapping: mesh)),
            "medical-record-approval": ForwardAllergyOptionsCodeMedicalRecordApproval(client: Acme_Patients_V1_MedicalRecordApprovalService.Client(wrapping: mesh)),
        ]
        try await route("vital-validation", record, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: ForwardAllergyOptionsCodeRecord, _ sinks: [String: any ForwardAllergyOptionsCodeDestination]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.forward(rec)
    }
}
