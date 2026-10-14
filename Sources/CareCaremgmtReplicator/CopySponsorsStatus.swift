import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopySponsorsStatus keeps of each RecalculateSponsors response.
struct CopySponsorsStatusRecord {
    var status: String
    var message: String
    var sponsorID: String
}

/// Where CopySponsorsStatus hands each record.
protocol CopySponsorsStatusTarget {
    func apply(_ rec: CopySponsorsStatusRecord) async throws
}

/// Sends records to acme.notifications.v1.NotificationQueryService.
struct CopySponsorsStatusNotificationQuery: CopySponsorsStatusTarget {
    let client: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>

    func apply(_ rec: CopySponsorsStatusRecord) async throws {
        let request = Acme_Notifications_V1_PeekNotificationRequest.with {
            $0.notificationID = rec.sponsorID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.peekNotification(request)
        }
    }
}

/// Passes records to acme.ledger.v1.LedgerAccountQueryService.
struct CopySponsorsStatusLedgerAccountQuery: CopySponsorsStatusTarget {
    let client: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>

    func apply(_ rec: CopySponsorsStatusRecord) async throws {
        let request = Acme_Ledger_V1_FindLedgerAccountsRequest.with {
            $0.orderBy = rec.sponsorID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.findLedgerAccounts(request)
        }
    }
}

/// Passes records to acme.careplans.v1.VitalWorkflowService.
struct CopySponsorsStatusVitalWorkflow: CopySponsorsStatusTarget {
    let client: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>

    func apply(_ rec: CopySponsorsStatusRecord) async throws {
        _ = try await client.resumeVitalWorkflow(.with {
            $0.details.initiatedBy = rec.sponsorID
            $0.vital.source = rec.status
        })
    }
}

/// Sends records to acme.patients.v1.PatientWorkflowService.
struct CopySponsorsStatusPatientWorkflow: CopySponsorsStatusTarget {
    let client: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>

    func apply(_ rec: CopySponsorsStatusRecord) async throws {
        _ = try await client.signalPatientWorkflow(.with {
            $0.patientID = rec.message
            $0.details.step = rec.sponsorID
        })
    }
}

/// Reads acme.sponsorships.v1.SponsorCalculationService/RecalculateSponsors and hands what it keeps to the sink of its kind.
enum CopySponsorsStatus {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Sponsorships_V1_SponsorCalculationService.Client(wrapping: mesh)
        let response = try await origin.recalculateSponsors(.with { $0.sponsorID = "nightly-copy-sponsors-status" })
        let record = CopySponsorsStatusRecord(
            status: Kit.Text.normalize(response.result.status),
            message: response.result.message,
            sponsorID: Kit.Text.normalize(response.sponsor.sponsorID)
        )
        let sinks: [any CopySponsorsStatusTarget] = [
            CopySponsorsStatusNotificationQuery(client: Acme_Notifications_V1_NotificationQueryService.Client(wrapping: mesh)),
            CopySponsorsStatusLedgerAccountQuery(client: Acme_Ledger_V1_LedgerAccountQueryService.Client(wrapping: mesh)),
            CopySponsorsStatusVitalWorkflow(client: Acme_Careplans_V1_VitalWorkflowService.Client(wrapping: mesh)),
            CopySponsorsStatusPatientWorkflow(client: Acme_Patients_V1_PatientWorkflowService.Client(wrapping: mesh)),
        ]
        try await sinks[3].apply(record)
    }
}
