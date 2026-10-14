import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardPatientHomeWorkflowID keeps of each SignalPatientHomeWorkflow response.
struct ForwardPatientHomeWorkflowIDRecord {
    var referenceID: String
    var correlationID: String
    var status: String
    var message: String
}

/// Where ForwardPatientHomeWorkflowID hands each record.
protocol ForwardPatientHomeWorkflowIDSink {
    func forward(_ rec: ForwardPatientHomeWorkflowIDRecord) async throws
}

/// Sends records to acme.tours.v1.TourQueryService.
struct ForwardPatientHomeWorkflowIDTourQuery: ForwardPatientHomeWorkflowIDSink {
    let client: Acme_Tours_V1_TourQueryService.Client<MeshTransport>

    func forward(_ rec: ForwardPatientHomeWorkflowIDRecord) async throws {
        _ = try await client.findTours(.with {
            $0.orderBy = rec.status
            $0.filter.query = rec.correlationID
            $0.page.pageToken = rec.referenceID
        })
    }
}

/// Sends records to acme.telehealth.v1.VideoVisitValidationService.
struct ForwardPatientHomeWorkflowIDVideoVisitValidation: ForwardPatientHomeWorkflowIDSink {
    let client: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>

    func forward(_ rec: ForwardPatientHomeWorkflowIDRecord) async throws {
        let request = Acme_Telehealth_V1_GetVideoVisitRulesRequest.with {
            $0.videoVisitID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.getVideoVisitRules(request)
        }
    }
}

/// Hands records to acme.careplans.v1.VitalValidationService.
struct ForwardPatientHomeWorkflowIDVitalValidation: ForwardPatientHomeWorkflowIDSink {
    let client: Acme_Careplans_V1_VitalValidationService.Client<MeshTransport>

    func forward(_ rec: ForwardPatientHomeWorkflowIDRecord) async throws {
        _ = try await client.scoreVital(.with {
            $0.vitalID = rec.correlationID
            $0.vital.vitalID = rec.message
        })
    }
}

/// Reads acme.patientapp.v1.PatientHomeWorkflowService/SignalPatientHomeWorkflow and hands what it keeps to the sink of its kind.
enum ForwardPatientHomeWorkflowID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Patientapp_V1_PatientHomeWorkflowService.Client(wrapping: mesh)
        let response = try await upstream.signalPatientHomeWorkflow(.with { $0.reason = "current-forward-patient-home-workflow-id" })
        let row = ForwardPatientHomeWorkflowIDRecord(
            referenceID: Kit.Text.normalize(response.outcome.referenceID),
            correlationID: Kit.Text.normalize(response.result.correlationID),
            status: response.outcome.status,
            message: response.result.message
        )
        let sinks: [any ForwardPatientHomeWorkflowIDSink] = [
            ForwardPatientHomeWorkflowIDTourQuery(client: Acme_Tours_V1_TourQueryService.Client(wrapping: mesh)),
            ForwardPatientHomeWorkflowIDVideoVisitValidation(client: Acme_Telehealth_V1_VideoVisitValidationService.Client(wrapping: mesh)),
            ForwardPatientHomeWorkflowIDVitalValidation(client: Acme_Careplans_V1_VitalValidationService.Client(wrapping: mesh)),
        ]
        try await sinks[2].forward(row)
    }
}
