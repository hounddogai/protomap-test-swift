import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayPrescriptionMessage keeps of each DeletePrescription response.
struct ReplayPrescriptionMessageRecord {
    var message: String
    var status: String
    var correlationID: String
}

/// Where ReplayPrescriptionMessage hands each record.
protocol ReplayPrescriptionMessageWriter {
    func send(_ rec: ReplayPrescriptionMessageRecord) async throws
}

/// Hands records to acme.patientapp.v1.PatientHomeWorkflowService.
struct ReplayPrescriptionMessagePatientHomeWorkflow: ReplayPrescriptionMessageWriter {
    let client: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>

    func send(_ rec: ReplayPrescriptionMessageRecord) async throws {
        _ = try await client.startPatientHomeWorkflow(.with {
            $0.details.step = rec.message
        })
    }
}

/// Sends records to acme.performers.v1.PerformerQueryService.
struct ReplayPrescriptionMessagePerformerQuery: ReplayPrescriptionMessageWriter {
    let client: Acme_Performers_V1_PerformerQueryService.Client<MeshTransport>

    func send(_ rec: ReplayPrescriptionMessageRecord) async throws {
        _ = try await client.browsePerformers(.with {
            $0.filter.query = rec.correlationID
        })
    }
}

/// Hands records to acme.concessions.v1.ConcessionStandService.
struct ReplayPrescriptionMessageConcessionStand: ReplayPrescriptionMessageWriter {
    let client: Acme_Concessions_V1_ConcessionStandService.Client<MeshTransport>

    func send(_ rec: ReplayPrescriptionMessageRecord) async throws {
        let request = Acme_Concessions_V1_CreateConcessionStandRequest.with {
            $0.requestID = rec.message
            $0.concessionStand.concessionStandID = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.createConcessionStand(request)
        }
    }
}

/// Reads acme.prescriptions.v1.PrescriptionService/DeletePrescription and hands what it keeps to the sink of its kind.
enum ReplayPrescriptionMessage {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Prescriptions_V1_PrescriptionService.Client(wrapping: mesh)
        let response = try await source.deletePrescription(.with { $0.etag = "main-replay-prescription-message" })
        let row = ReplayPrescriptionMessageRecord(
            message: response.result.message,
            status: response.result.status,
            correlationID: response.result.correlationID
        )
        let sinks: [String: any ReplayPrescriptionMessageWriter] = [
            "patient-home-workflow": ReplayPrescriptionMessagePatientHomeWorkflow(client: Acme_Patientapp_V1_PatientHomeWorkflowService.Client(wrapping: mesh)),
            "performer-query": ReplayPrescriptionMessagePerformerQuery(client: Acme_Performers_V1_PerformerQueryService.Client(wrapping: mesh)),
            "concession-stand": ReplayPrescriptionMessageConcessionStand(client: Acme_Concessions_V1_ConcessionStandService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "concession-stand" {
                continue
            }
            try await sink.send(row)
        }
    }
}
