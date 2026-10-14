import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayPatientID keeps of each ExpirePatient response.
struct RelayPatientIDRecord {
    var patientID: String
    var referenceID: String
    var status: String
    var outcomeStatus: String
}

/// Where RelayPatientID hands each record.
protocol RelayPatientIDSink {
    func apply(_ rec: RelayPatientIDRecord) async throws
}

/// Hands records to acme.patients.v1.AllergySyncService.
struct RelayPatientIDAllergySync: RelayPatientIDSink {
    let client: Acme_Patients_V1_AllergySyncService.Client<MeshTransport>

    func apply(_ rec: RelayPatientIDRecord) async throws {
        _ = try await client.pushAllergy(.with {
            $0.allergyID = rec.patientID
            $0.allergy.source = rec.referenceID
        })
    }
}

/// Sends records to acme.careplans.v1.CarePlanCalculationService.
struct RelayPatientIDCarePlanCalculation: RelayPatientIDSink {
    let client: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>

    func apply(_ rec: RelayPatientIDRecord) async throws {
        let request = Acme_Careplans_V1_CompareCarePlanOptionsRequest.with {
            $0.carePlan.notes = rec.patientID
            $0.reason = rec.status
            $0.carePlanID = rec.referenceID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.compareCarePlanOptions(request)
        }
    }
}

/// Reads acme.patients.v1.PatientLifecycleService/ExpirePatient and hands what it keeps to the sink of its kind.
enum RelayPatientID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Patients_V1_PatientLifecycleService.Client(wrapping: mesh)
        let reply = try await upstream.expirePatient(.with { $0.patientID = "default-relay-patient-id" })
        let record = RelayPatientIDRecord(
            patientID: Kit.Text.normalize(reply.patient.patientID),
            referenceID: reply.outcome.referenceID,
            status: reply.result.status,
            outcomeStatus: reply.outcome.status
        )
        try await act("care-plan-calculation", record, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: RelayPatientIDRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "allergy-sync": { try await RelayPatientIDAllergySync(client: Acme_Patients_V1_AllergySyncService.Client(wrapping: mesh)).apply(rec) },
            "care-plan-calculation": { try await RelayPatientIDCarePlanCalculation(client: Acme_Careplans_V1_CarePlanCalculationService.Client(wrapping: mesh)).apply(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
