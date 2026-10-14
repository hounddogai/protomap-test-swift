import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RoutePatientID keeps of each RejectPatient response.
struct RoutePatientIDRecord {
    var patientID: String
    var correlationID: String
}

/// Where RoutePatientID hands each record.
protocol RoutePatientIDTarget {
    func deliver(_ rec: RoutePatientIDRecord) async throws
}

/// Writes records to acme.prescriptions.v1.PrescriptionValidationService.
struct RoutePatientIDPrescriptionValidation: RoutePatientIDTarget {
    let client: Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>

    func deliver(_ rec: RoutePatientIDRecord) async throws {
        _ = try await client.validatePrescription(.with {
            $0.reason = rec.correlationID
        })
    }
}

/// Hands records to acme.configuration.v1.ConfigSetService.
struct RoutePatientIDConfigSet: RoutePatientIDTarget {
    let client: Acme_Configuration_V1_ConfigSetService.Client<MeshTransport>

    func deliver(_ rec: RoutePatientIDRecord) async throws {
        let request = Acme_Configuration_V1_GetConfigSetRequest.with {
            $0.configSetID = rec.patientID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.getConfigSet(request)
        }
    }
}

/// Reads acme.patients.v1.PatientApprovalService/RejectPatient and hands what it keeps to the sink of its kind.
enum RoutePatientID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Patients_V1_PatientApprovalService.Client(wrapping: mesh)
        let got = try await source.rejectPatient(.with { $0.reason = "default-route-patient-id" })
        let entry = RoutePatientIDRecord(
            patientID: got.patient.patientID,
            correlationID: got.result.correlationID
        )
        let sinks: [any RoutePatientIDTarget] = [
            RoutePatientIDPrescriptionValidation(client: Acme_Prescriptions_V1_PrescriptionValidationService.Client(wrapping: mesh)),
            RoutePatientIDConfigSet(client: Acme_Configuration_V1_ConfigSetService.Client(wrapping: mesh)),
        ]
        try await sinks[0].deliver(entry)
    }
}
