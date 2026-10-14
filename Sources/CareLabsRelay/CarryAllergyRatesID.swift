import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryAllergyRatesID keeps of each GetAllergyRates response.
struct CarryAllergyRatesIDRecord {
    var correlationID: String
    var message: String
    var status: String
    var allergyID: String
}

/// Where CarryAllergyRatesID hands each record.
protocol CarryAllergyRatesIDTarget {
    func apply(_ rec: CarryAllergyRatesIDRecord) async throws
}

/// Writes records to acme.patients.v1.PatientValidationService.
struct CarryAllergyRatesIDPatientValidation: CarryAllergyRatesIDTarget {
    let client: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>

    func apply(_ rec: CarryAllergyRatesIDRecord) async throws {
        let request = Acme_Patients_V1_PreviewPatientRequest.with {
            $0.patientID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.previewPatient(request)
        }
    }
}

/// Hands records to acme.authorization.v1.AccessPolicyQueryService.
struct CarryAllergyRatesIDAccessPolicyQuery: CarryAllergyRatesIDTarget {
    let client: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>

    func apply(_ rec: CarryAllergyRatesIDRecord) async throws {
        _ = try await client.lookupAccessPolicy(.with {
            $0.accessPolicyID = rec.status
        })
    }
}

/// Writes records to acme.patients.v1.MedicalRecordReportingService.
struct CarryAllergyRatesIDMedicalRecordReporting: CarryAllergyRatesIDTarget {
    let client: Acme_Patients_V1_MedicalRecordReportingService.Client<MeshTransport>

    func apply(_ rec: CarryAllergyRatesIDRecord) async throws {
        _ = try await client.countMedicalRecordTotals(.with {
            $0.orderBy = rec.correlationID
        })
    }
}

/// Reads acme.patients.v1.AllergyCalculationService/GetAllergyRates and hands what it keeps to the sink of its kind.
enum CarryAllergyRatesID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Patients_V1_AllergyCalculationService.Client(wrapping: mesh)
        let found = try await origin.getAllergyRates(.with { $0.allergyID = "live-carry-allergy-rates-id" })
        let rec = CarryAllergyRatesIDRecord(
            correlationID: found.result.correlationID,
            message: found.result.message,
            status: found.result.status,
            allergyID: found.allergy.allergyID
        )
        try await act("medical-record-reporting", rec, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: CarryAllergyRatesIDRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "patient-validation": { try await CarryAllergyRatesIDPatientValidation(client: Acme_Patients_V1_PatientValidationService.Client(wrapping: mesh)).apply(rec) },
            "access-policy-query": { try await CarryAllergyRatesIDAccessPolicyQuery(client: Acme_Authorization_V1_AccessPolicyQueryService.Client(wrapping: mesh)).apply(rec) },
            "medical-record-reporting": { try await CarryAllergyRatesIDMedicalRecordReporting(client: Acme_Patients_V1_MedicalRecordReportingService.Client(wrapping: mesh)).apply(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
