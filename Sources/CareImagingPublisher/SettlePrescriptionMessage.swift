import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettlePrescriptionMessage keeps of each ScorePrescription response.
struct SettlePrescriptionMessageRecord {
    var message: String
    var correlationID: String
    var notes: String
    var currencyCode: String
}

/// Where SettlePrescriptionMessage hands each record.
protocol SettlePrescriptionMessageDestination {
    func forward(_ rec: SettlePrescriptionMessageRecord) async throws
}

/// Hands records to acme.telehealth.v1.VideoVisitApprovalService.
struct SettlePrescriptionMessageVideoVisitApproval: SettlePrescriptionMessageDestination {
    let client: Acme_Telehealth_V1_VideoVisitApprovalService.Client<MeshTransport>

    func forward(_ rec: SettlePrescriptionMessageRecord) async throws {
        _ = try await client.listPendingVideoVisits(.with {
            $0.filter.region = rec.message
            $0.filter.ownerID = rec.currencyCode
            $0.page.pageToken = rec.correlationID
        })
    }
}

/// Hands records to acme.patientapp.v1.PatientHomeService.
struct SettlePrescriptionMessagePatientHome: SettlePrescriptionMessageDestination {
    let client: Acme_Patientapp_V1_PatientHomeService.Client<MeshTransport>

    func forward(_ rec: SettlePrescriptionMessageRecord) async throws {
        let request = Acme_Patientapp_V1_ListPatientHomesRequest.with {
            $0.filter.query = rec.notes
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.listPatientHomes(request)
        }
    }
}

/// Passes records to acme.patientapp.v1.PatientHomeNotificationService.
struct SettlePrescriptionMessagePatientHomeNotification: SettlePrescriptionMessageDestination {
    let client: Acme_Patientapp_V1_PatientHomeNotificationService.Client<MeshTransport>

    func forward(_ rec: SettlePrescriptionMessageRecord) async throws {
        _ = try await client.subscribePatientHomeUpdates(.with {
            $0.patientHomeID = rec.currencyCode
            $0.details.channel = rec.message
        })
    }
}

/// Hands records to acme.appointments.v1.ProviderWorkflowService.
struct SettlePrescriptionMessageProviderWorkflow: SettlePrescriptionMessageDestination {
    let client: Acme_Appointments_V1_ProviderWorkflowService.Client<MeshTransport>

    func forward(_ rec: SettlePrescriptionMessageRecord) async throws {
        let request = Acme_Appointments_V1_StartProviderWorkflowRequest.with {
            $0.details.step = rec.currencyCode
            $0.providerID = rec.notes
            $0.reason = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.startProviderWorkflow(request)
        }
    }
}

/// Reads acme.prescriptions.v1.PrescriptionValidationService/ScorePrescription and hands what it keeps to the sink of its kind.
enum SettlePrescriptionMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Prescriptions_V1_PrescriptionValidationService.Client(wrapping: mesh)
        let reply = try await reader.scorePrescription(.with { $0.reason = "main-settle-prescription-message" })
        let row = SettlePrescriptionMessageRecord(
            message: Kit.Text.normalize(reply.result.message),
            correlationID: reply.result.correlationID,
            notes: reply.prescription.notes,
            currencyCode: Kit.Text.normalize(reply.breakdown.currencyCode)
        )
        let sinks: [String: any SettlePrescriptionMessageDestination] = [
            "video-visit-approval": SettlePrescriptionMessageVideoVisitApproval(client: Acme_Telehealth_V1_VideoVisitApprovalService.Client(wrapping: mesh)),
            "patient-home": SettlePrescriptionMessagePatientHome(client: Acme_Patientapp_V1_PatientHomeService.Client(wrapping: mesh)),
            "patient-home-notification": SettlePrescriptionMessagePatientHomeNotification(client: Acme_Patientapp_V1_PatientHomeNotificationService.Client(wrapping: mesh)),
            "provider-workflow": SettlePrescriptionMessageProviderWorkflow(client: Acme_Appointments_V1_ProviderWorkflowService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "provider-workflow" {
                continue
            }
            try await sink.forward(row)
        }
    }
}
