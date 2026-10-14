import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayVitalDecisionID keeps of each ExplainVitalDecision response.
struct RelayVitalDecisionIDRecord {
    var correlationID: String
    var vitalCorrelationID: String
    var kind: String
    var referenceID: String
}

/// Where RelayVitalDecisionID hands each record.
protocol RelayVitalDecisionIDSink {
    func deliver(_ rec: RelayVitalDecisionIDRecord) async throws
}

/// Passes records to acme.telehealth.v1.VideoVisitWorkflowService.
struct RelayVitalDecisionIDVideoVisitWorkflow: RelayVitalDecisionIDSink {
    let client: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>

    func deliver(_ rec: RelayVitalDecisionIDRecord) async throws {
        _ = try await client.retryVideoVisitWorkflow(.with {
            $0.reason = rec.kind
            $0.videoVisit.title = rec.vitalCorrelationID
            $0.details.initiatedBy = rec.referenceID
        })
    }
}

/// Hands records to acme.patientapp.v1.PatientHomeWorkflowService.
struct RelayVitalDecisionIDPatientHomeWorkflow: RelayVitalDecisionIDSink {
    let client: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>

    func deliver(_ rec: RelayVitalDecisionIDRecord) async throws {
        _ = try await client.cancelPatientHomeWorkflow(.with {
            $0.patientHome.patientHomeID = rec.correlationID
            $0.patientHomeID = rec.kind
        })
    }
}

/// Hands records to acme.patients.v1.MedicalRecordReportingService.
struct RelayVitalDecisionIDMedicalRecordReporting: RelayVitalDecisionIDSink {
    let client: Acme_Patients_V1_MedicalRecordReportingService.Client<MeshTransport>

    func deliver(_ rec: RelayVitalDecisionIDRecord) async throws {
        _ = try await client.listMedicalRecordReports(.with {
            $0.filter.ownerID = rec.referenceID
        })
    }
}

/// Reads acme.careplans.v1.VitalValidationService/ExplainVitalDecision and hands what it keeps to the sink of its kind.
enum RelayVitalDecisionID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Careplans_V1_VitalValidationService.Client(wrapping: mesh)
        let got = try await upstream.explainVitalDecision(.with { $0.reason = "main-relay-vital-decision-id" })
        let entry = RelayVitalDecisionIDRecord(
            correlationID: Kit.Text.normalize(got.result.correlationID),
            vitalCorrelationID: got.vital.correlationID,
            kind: got.vital.kind,
            referenceID: Kit.Text.normalize(got.outcome.referenceID)
        )
        let sinks: [String: any RelayVitalDecisionIDSink] = [
            "video-visit-workflow": RelayVitalDecisionIDVideoVisitWorkflow(client: Acme_Telehealth_V1_VideoVisitWorkflowService.Client(wrapping: mesh)),
            "patient-home-workflow": RelayVitalDecisionIDPatientHomeWorkflow(client: Acme_Patientapp_V1_PatientHomeWorkflowService.Client(wrapping: mesh)),
            "medical-record-reporting": RelayVitalDecisionIDMedicalRecordReporting(client: Acme_Patients_V1_MedicalRecordReportingService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "video-visit-workflow" {
                continue
            }
            try await sink.deliver(entry)
        }
    }
}
