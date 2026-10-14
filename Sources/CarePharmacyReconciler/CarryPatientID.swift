import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryPatientID keeps of each LookupPatient response.
struct CarryPatientIDRecord {
    var patientID: String
    var message: String
}

/// Where CarryPatientID hands each record.
protocol CarryPatientIDSink {
    func write(_ rec: CarryPatientIDRecord) async throws
}

/// Sends records to acme.patients.v1.AllergyApprovalService.
struct CarryPatientIDAllergyApproval: CarryPatientIDSink {
    let client: Acme_Patients_V1_AllergyApprovalService.Client<MeshTransport>

    func write(_ rec: CarryPatientIDRecord) async throws {
        let request = Acme_Patients_V1_CommentAllergyApprovalRequest.with {
            $0.details.approverEmail = rec.patientID
            $0.allergy.allergyID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.commentAllergyApproval(request)
        }
    }
}

/// Sends records to acme.itsm.v1.IncidentCalculationService.
struct CarryPatientIDIncidentCalculation: CarryPatientIDSink {
    let client: Acme_Itsm_V1_IncidentCalculationService.Client<MeshTransport>

    func write(_ rec: CarryPatientIDRecord) async throws {
        _ = try await client.getIncidentRates(.with {
            $0.incidentID = rec.patientID
        })
    }
}

/// Passes records to acme.careplans.v1.CareGoalQueryService.
struct CarryPatientIDCareGoalQuery: CarryPatientIDSink {
    let client: Acme_Careplans_V1_CareGoalQueryService.Client<MeshTransport>

    func write(_ rec: CarryPatientIDRecord) async throws {
        _ = try await client.peekCareGoal(.with {
            $0.careGoalID = rec.message
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct CarryPatientIDLogOnly: CarryPatientIDSink {
    let logger = Logger(label: "acme.carry-patient-id")

    func write(_ rec: CarryPatientIDRecord) async throws {
        logger.info("No sink for record", metadata: ["patientID": .string(rec.patientID)])
    }
}

/// Reads acme.patients.v1.PatientQueryService/LookupPatient and hands what it keeps to the sink of its kind.
enum CarryPatientID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Patients_V1_PatientQueryService.Client(wrapping: mesh)
        let reply = try await source.lookupPatient(.with { $0.patientID = "main-carry-patient-id" })
        let record = CarryPatientIDRecord(
            patientID: reply.patient.patientID,
            message: reply.result.message
        )
        try await deliver("allergy-approval", record, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: CarryPatientIDRecord, _ mesh: MeshClient) async throws {
        var sink: any CarryPatientIDSink = CarryPatientIDLogOnly()
        switch kind {
        case "allergy-approval":
            sink = CarryPatientIDAllergyApproval(client: Acme_Patients_V1_AllergyApprovalService.Client(wrapping: mesh))
        case "incident-calculation":
            sink = CarryPatientIDIncidentCalculation(client: Acme_Itsm_V1_IncidentCalculationService.Client(wrapping: mesh))
        case "care-goal-query":
            sink = CarryPatientIDCareGoalQuery(client: Acme_Careplans_V1_CareGoalQueryService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.write(rec)
    }
}
