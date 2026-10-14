import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardPrescriptionRatesID keeps of each GetPrescriptionRates response.
struct ForwardPrescriptionRatesIDRecord {
    var correlationID: String
    var notes: String
    var number: String
    var prescriptionID: String
}

/// Where ForwardPrescriptionRatesID hands each record.
protocol ForwardPrescriptionRatesIDSink {
    func send(_ rec: ForwardPrescriptionRatesIDRecord) async throws
}

/// Hands records to acme.authorization.v1.AccessPolicyValidationService.
struct ForwardPrescriptionRatesIDAccessPolicyValidation: ForwardPrescriptionRatesIDSink {
    let client: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>

    func send(_ rec: ForwardPrescriptionRatesIDRecord) async throws {
        let request = Acme_Authorization_V1_LintAccessPoliciesRequest.with {
            $0.reason = rec.correlationID
            $0.details.locale = rec.prescriptionID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.lintAccessPolicies(request)
        }
    }
}

/// Hands records to acme.itsm.v1.IncidentCalculationService.
struct ForwardPrescriptionRatesIDIncidentCalculation: ForwardPrescriptionRatesIDSink {
    let client: Acme_Itsm_V1_IncidentCalculationService.Client<MeshTransport>

    func send(_ rec: ForwardPrescriptionRatesIDRecord) async throws {
        let request = Acme_Itsm_V1_RecalculateIncidentsRequest.with {
            $0.incidentID = rec.prescriptionID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.recalculateIncidents(request)
        }
    }
}

/// Reads acme.prescriptions.v1.PrescriptionCalculationService/GetPrescriptionRates and hands what it keeps to the sink of its kind.
enum ForwardPrescriptionRatesID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Prescriptions_V1_PrescriptionCalculationService.Client(wrapping: mesh)
        let got = try await reader.getPrescriptionRates(.with { $0.prescriptionID = "default-forward-prescription-rates-id" })
        let record = ForwardPrescriptionRatesIDRecord(
            correlationID: got.result.correlationID,
            notes: got.prescription.notes,
            number: got.prescription.number,
            prescriptionID: got.prescription.prescriptionID
        )
        try await act("access-policy-validation", record, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: ForwardPrescriptionRatesIDRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "access-policy-validation": { try await ForwardPrescriptionRatesIDAccessPolicyValidation(client: Acme_Authorization_V1_AccessPolicyValidationService.Client(wrapping: mesh)).send(rec) },
            "incident-calculation": { try await ForwardPrescriptionRatesIDIncidentCalculation(client: Acme_Itsm_V1_IncidentCalculationService.Client(wrapping: mesh)).send(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
