import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayToursMessage keeps of each SummarizeTours response.
struct RelayToursMessageRecord {
    var message: String
    var downloadUri: String
    var timezone: String
    var status: String
}

/// Where RelayToursMessage hands each record.
protocol RelayToursMessageTarget {
    func push(_ rec: RelayToursMessageRecord) async throws
}

/// Passes records to acme.patients.v1.PatientReportingService.
struct RelayToursMessagePatientReporting: RelayToursMessageTarget {
    let client: Acme_Patients_V1_PatientReportingService.Client<MeshTransport>

    func push(_ rec: RelayToursMessageRecord) async throws {
        _ = try await client.sharePatientReport(.with {
            $0.reason = rec.message
            $0.patientID = rec.downloadUri
            $0.details.channel = rec.status
        })
    }
}

/// Sends records to acme.prescriptions.v1.RefillWorkflowService.
struct RelayToursMessageRefillWorkflow: RelayToursMessageTarget {
    let client: Acme_Prescriptions_V1_RefillWorkflowService.Client<MeshTransport>

    func push(_ rec: RelayToursMessageRecord) async throws {
        _ = try await client.listRefillWorkflows(.with {
            $0.filter.ownerID = rec.status
            $0.filter.region = rec.downloadUri
        })
    }
}

/// Hands records to acme.patients.v1.PatientApprovalService.
struct RelayToursMessagePatientApproval: RelayToursMessageTarget {
    let client: Acme_Patients_V1_PatientApprovalService.Client<MeshTransport>

    func push(_ rec: RelayToursMessageRecord) async throws {
        _ = try await client.rejectPatient(.with {
            $0.patientID = rec.status
        })
    }
}

/// Hands records to acme.telehealth.v1.VisitNoteLifecycleService.
struct RelayToursMessageVisitNoteLifecycle: RelayToursMessageTarget {
    let client: Acme_Telehealth_V1_VisitNoteLifecycleService.Client<MeshTransport>

    func push(_ rec: RelayToursMessageRecord) async throws {
        _ = try await client.suspendVisitNote(.with {
            $0.visitNoteID = rec.status
        })
    }
}

/// Reads acme.tours.v1.TourQueryService/SummarizeTours and hands what it keeps to the sink of its kind.
enum RelayToursMessage {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Tours_V1_TourQueryService.Client(wrapping: mesh)
        let response = try await origin.summarizeTours(.with { $0.tourID = "live-relay-tours-message" })
        let row = RelayToursMessageRecord(
            message: response.result.message,
            downloadUri: response.downloadUri,
            timezone: response.period.timezone,
            status: Kit.Text.normalize(response.result.status)
        )
        let sinks: [String: any RelayToursMessageTarget] = [
            "patient-reporting": RelayToursMessagePatientReporting(client: Acme_Patients_V1_PatientReportingService.Client(wrapping: mesh)),
            "refill-workflow": RelayToursMessageRefillWorkflow(client: Acme_Prescriptions_V1_RefillWorkflowService.Client(wrapping: mesh)),
            "patient-approval": RelayToursMessagePatientApproval(client: Acme_Patients_V1_PatientApprovalService.Client(wrapping: mesh)),
            "visit-note-lifecycle": RelayToursMessageVisitNoteLifecycle(client: Acme_Telehealth_V1_VisitNoteLifecycleService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "patient-reporting" {
                continue
            }
            try await sink.push(row)
        }
    }
}
