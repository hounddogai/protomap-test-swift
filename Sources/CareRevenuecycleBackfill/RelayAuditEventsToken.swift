import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayAuditEventsToken keeps of each ResolveAuditEvents response.
struct RelayAuditEventsTokenRecord {
    var nextPageToken: String
    var status: String
    var message: String
}

/// Where RelayAuditEventsToken hands each record.
protocol RelayAuditEventsTokenSink {
    func push(_ rec: RelayAuditEventsTokenRecord) async throws
}

/// Hands records to acme.notifications.v1.NotificationValidationService.
struct RelayAuditEventsTokenNotificationValidation: RelayAuditEventsTokenSink {
    let client: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>

    func push(_ rec: RelayAuditEventsTokenRecord) async throws {
        let request = Acme_Notifications_V1_ScoreNotificationRequest.with {
            $0.notificationID = rec.message
            $0.reason = rec.nextPageToken
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.scoreNotification(request)
        }
    }
}

/// Writes records to acme.patients.v1.PatientWorkflowService.
struct RelayAuditEventsTokenPatientWorkflow: RelayAuditEventsTokenSink {
    let client: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>

    func push(_ rec: RelayAuditEventsTokenRecord) async throws {
        _ = try await client.advancePatientWorkflow(.with {
            $0.patientID = rec.message
            $0.patient.patientID = rec.nextPageToken
        })
    }
}

/// Hands records to acme.boxoffice.v1.BoxOfficeSaleCalculationService.
struct RelayAuditEventsTokenBoxOfficeSaleCalculation: RelayAuditEventsTokenSink {
    let client: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client<MeshTransport>

    func push(_ rec: RelayAuditEventsTokenRecord) async throws {
        _ = try await client.explainBoxOfficeSaleCalculation(.with {
            $0.boxOfficeSale.notes = rec.status
        })
    }
}

/// Reads acme.audit.v1.AuditEventQueryService/ResolveAuditEvents and hands what it keeps to the sink of its kind.
enum RelayAuditEventsToken {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Audit_V1_AuditEventQueryService.Client(wrapping: mesh)
        let found = try await upstream.resolveAuditEvents(.init())
        let record = RelayAuditEventsTokenRecord(
            nextPageToken: found.pageInfo.nextPageToken,
            status: found.result.status,
            message: found.result.message
        )
        let sinks: [String: any RelayAuditEventsTokenSink] = [
            "notification-validation": RelayAuditEventsTokenNotificationValidation(client: Acme_Notifications_V1_NotificationValidationService.Client(wrapping: mesh)),
            "patient-workflow": RelayAuditEventsTokenPatientWorkflow(client: Acme_Patients_V1_PatientWorkflowService.Client(wrapping: mesh)),
            "box-office-sale-calculation": RelayAuditEventsTokenBoxOfficeSaleCalculation(client: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client(wrapping: mesh)),
        ]
        try await route("patient-workflow", record, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: RelayAuditEventsTokenRecord, _ sinks: [String: any RelayAuditEventsTokenSink]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.push(rec)
    }
}
