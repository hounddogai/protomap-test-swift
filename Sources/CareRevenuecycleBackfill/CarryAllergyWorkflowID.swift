import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryAllergyWorkflowID keeps of each ResumeAllergyWorkflow response.
struct CarryAllergyWorkflowIDRecord {
    var correlationID: String
    var allergyID: String
    var status: String
    var message: String
}

/// Where CarryAllergyWorkflowID hands each record.
protocol CarryAllergyWorkflowIDSink {
    func send(_ rec: CarryAllergyWorkflowIDRecord) async throws
}

/// Writes records to acme.admissions.v1.AdmissionQueryService.
struct CarryAllergyWorkflowIDAdmissionQuery: CarryAllergyWorkflowIDSink {
    let client: Acme_Admissions_V1_AdmissionQueryService.Client<MeshTransport>

    func send(_ rec: CarryAllergyWorkflowIDRecord) async throws {
        let request = Acme_Admissions_V1_SummarizeAdmissionsRequest.with {
            $0.reason = rec.allergyID
            $0.admissionID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.summarizeAdmissions(request)
        }
    }
}

/// Passes records to acme.patients.v1.PatientQueryService.
struct CarryAllergyWorkflowIDPatientQuery: CarryAllergyWorkflowIDSink {
    let client: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>

    func send(_ rec: CarryAllergyWorkflowIDRecord) async throws {
        _ = try await client.peekPatient(.with {
            $0.patientID = rec.allergyID
        })
    }
}

/// Reads acme.patients.v1.AllergyWorkflowService/ResumeAllergyWorkflow and hands what it keeps to the sink of its kind.
enum CarryAllergyWorkflowID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Patients_V1_AllergyWorkflowService.Client(wrapping: mesh)
        let reply = try await origin.resumeAllergyWorkflow(.with { $0.reason = "live-carry-allergy-workflow-id" })
        let entry = CarryAllergyWorkflowIDRecord(
            correlationID: Kit.Text.normalize(reply.result.correlationID),
            allergyID: reply.allergy.allergyID,
            status: reply.result.status,
            message: reply.result.message
        )
        let sinks: [String: any CarryAllergyWorkflowIDSink] = [
            "admission-query": CarryAllergyWorkflowIDAdmissionQuery(client: Acme_Admissions_V1_AdmissionQueryService.Client(wrapping: mesh)),
            "patient-query": CarryAllergyWorkflowIDPatientQuery(client: Acme_Patients_V1_PatientQueryService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "patient-query" {
                continue
            }
            try await sink.send(entry)
        }
    }
}
