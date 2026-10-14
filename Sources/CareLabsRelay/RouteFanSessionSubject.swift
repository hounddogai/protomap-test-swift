import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RouteFanSessionSubject keeps of each LookupFanSession response.
struct RouteFanSessionSubjectRecord {
    var subject: String
    var fanSessionID: String
    var status: String
}

/// Where RouteFanSessionSubject hands each record.
protocol RouteFanSessionSubjectWriter {
    func send(_ rec: RouteFanSessionSubjectRecord) async throws
}

/// Passes records to acme.notifications.v1.NotificationQueryService.
struct RouteFanSessionSubjectNotificationQuery: RouteFanSessionSubjectWriter {
    let client: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>

    func send(_ rec: RouteFanSessionSubjectRecord) async throws {
        let request = Acme_Notifications_V1_BrowseNotificationsRequest.with {
            $0.filter.ownerID = rec.subject
            $0.orderBy = rec.status
            $0.filter.region = rec.fanSessionID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.browseNotifications(request)
        }
    }
}

/// Hands records to acme.prescriptions.v1.MedicationCalculationService.
struct RouteFanSessionSubjectMedicationCalculation: RouteFanSessionSubjectWriter {
    let client: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>

    func send(_ rec: RouteFanSessionSubjectRecord) async throws {
        let request = Acme_Prescriptions_V1_EstimateMedicationRequest.with {
            $0.medication.code = rec.subject
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.estimateMedication(request)
        }
    }
}

/// Sends records to acme.patients.v1.AllergyApprovalService.
struct RouteFanSessionSubjectAllergyApproval: RouteFanSessionSubjectWriter {
    let client: Acme_Patients_V1_AllergyApprovalService.Client<MeshTransport>

    func send(_ rec: RouteFanSessionSubjectRecord) async throws {
        _ = try await client.getAllergyApprovalStatus(.with {
            $0.allergyID = rec.subject
        })
    }
}

/// Reads acme.fanportal.v1.FanSessionQueryService/LookupFanSession and hands what it keeps to the sink of its kind.
enum RouteFanSessionSubject {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Fanportal_V1_FanSessionQueryService.Client(wrapping: mesh)
        let reply = try await source.lookupFanSession(.with { $0.fanSessionID = "primary-route-fan-session-subject" })
        let record = RouteFanSessionSubjectRecord(
            subject: reply.fanSession.subject,
            fanSessionID: reply.fanSession.fanSessionID,
            status: Kit.Text.normalize(reply.result.status)
        )
        let sinks: [String: any RouteFanSessionSubjectWriter] = [
            "notification-query": RouteFanSessionSubjectNotificationQuery(client: Acme_Notifications_V1_NotificationQueryService.Client(wrapping: mesh)),
            "medication-calculation": RouteFanSessionSubjectMedicationCalculation(client: Acme_Prescriptions_V1_MedicationCalculationService.Client(wrapping: mesh)),
            "allergy-approval": RouteFanSessionSubjectAllergyApproval(client: Acme_Patients_V1_AllergyApprovalService.Client(wrapping: mesh)),
        ]
        guard let sink = sinks[ProcessInfo.processInfo.environment["ROUTE_FAN_SESSION_SUBJECT_TARGET"] ?? ""] else {
            return
        }
        try await sink.send(record)
    }
}
