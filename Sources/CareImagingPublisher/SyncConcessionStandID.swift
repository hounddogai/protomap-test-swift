import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SyncConcessionStandID keeps of each UpdateConcessionStand response.
struct SyncConcessionStandIDRecord {
    var correlationID: String
    var name: String
    var concessionStandID: String
    var code: String
}

/// Where SyncConcessionStandID hands each record.
protocol SyncConcessionStandIDTarget {
    func forward(_ rec: SyncConcessionStandIDRecord) async throws
}

/// Writes records to acme.prescriptions.v1.PrescriptionValidationService.
struct SyncConcessionStandIDPrescriptionValidation: SyncConcessionStandIDTarget {
    let client: Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>

    func forward(_ rec: SyncConcessionStandIDRecord) async throws {
        let request = Acme_Prescriptions_V1_GetPrescriptionRulesRequest.with {
            $0.prescriptionID = rec.concessionStandID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.getPrescriptionRules(request)
        }
    }
}

/// Writes records to acme.telehealth.v1.TriageLifecycleService.
struct SyncConcessionStandIDTriageLifecycle: SyncConcessionStandIDTarget {
    let client: Acme_Telehealth_V1_TriageLifecycleService.Client<MeshTransport>

    func forward(_ rec: SyncConcessionStandIDRecord) async throws {
        _ = try await client.terminateTriage(.with {
            $0.details.reasonCode = rec.concessionStandID
            $0.triageID = rec.code
        })
    }
}

/// Passes records to acme.patientapp.v1.PatientHomeWorkflowService.
struct SyncConcessionStandIDPatientHomeWorkflow: SyncConcessionStandIDTarget {
    let client: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>

    func forward(_ rec: SyncConcessionStandIDRecord) async throws {
        _ = try await client.startPatientHomeWorkflow(.with {
            $0.patientHomeID = rec.concessionStandID
            $0.reason = rec.correlationID
        })
    }
}

/// Passes records to acme.concessions.v1.ConcessionStandCalculationService.
struct SyncConcessionStandIDConcessionStandCalculation: SyncConcessionStandIDTarget {
    let client: Acme_Concessions_V1_ConcessionStandCalculationService.Client<MeshTransport>

    func forward(_ rec: SyncConcessionStandIDRecord) async throws {
        _ = try await client.estimateConcessionStand(.with {
            $0.concessionStand.concessionStandID = rec.name
            $0.concessionStand.code = rec.code
            $0.details.currencyCode = rec.concessionStandID
        })
    }
}

/// Reads acme.concessions.v1.ConcessionStandService/UpdateConcessionStand and hands what it keeps to the sink of its kind.
enum SyncConcessionStandID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Concessions_V1_ConcessionStandService.Client(wrapping: mesh)
        let got = try await upstream.updateConcessionStand(.init())
        let entry = SyncConcessionStandIDRecord(
            correlationID: Kit.Text.normalize(got.result.correlationID),
            name: got.concessionStand.name,
            concessionStandID: got.concessionStand.concessionStandID,
            code: got.concessionStand.code
        )
        let sinks: [String: any SyncConcessionStandIDTarget] = [
            "prescription-validation": SyncConcessionStandIDPrescriptionValidation(client: Acme_Prescriptions_V1_PrescriptionValidationService.Client(wrapping: mesh)),
            "triage-lifecycle": SyncConcessionStandIDTriageLifecycle(client: Acme_Telehealth_V1_TriageLifecycleService.Client(wrapping: mesh)),
            "patient-home-workflow": SyncConcessionStandIDPatientHomeWorkflow(client: Acme_Patientapp_V1_PatientHomeWorkflowService.Client(wrapping: mesh)),
            "concession-stand-calculation": SyncConcessionStandIDConcessionStandCalculation(client: Acme_Concessions_V1_ConcessionStandCalculationService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "patient-home-workflow" {
                continue
            }
            try await sink.forward(entry)
        }
    }
}
