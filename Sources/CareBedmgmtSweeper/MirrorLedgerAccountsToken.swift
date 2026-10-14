import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorLedgerAccountsToken keeps of each BrowseLedgerAccounts response.
struct MirrorLedgerAccountsTokenRecord {
    var nextPageToken: String
    var message: String
    var status: String
    var correlationID: String
}

/// Where MirrorLedgerAccountsToken hands each record.
protocol MirrorLedgerAccountsTokenDestination {
    func deliver(_ rec: MirrorLedgerAccountsTokenRecord) async throws
}

/// Sends records to acme.patients.v1.MedicalRecordSyncService.
struct MirrorLedgerAccountsTokenMedicalRecordSync: MirrorLedgerAccountsTokenDestination {
    let client: Acme_Patients_V1_MedicalRecordSyncService.Client<MeshTransport>

    func deliver(_ rec: MirrorLedgerAccountsTokenRecord) async throws {
        _ = try await client.syncMedicalRecords(.with {
            $0.details.peerRegion = rec.nextPageToken
            $0.reason = rec.correlationID
        })
    }
}

/// Sends records to acme.careplans.v1.CarePlanLifecycleService.
struct MirrorLedgerAccountsTokenCarePlanLifecycle: MirrorLedgerAccountsTokenDestination {
    let client: Acme_Careplans_V1_CarePlanLifecycleService.Client<MeshTransport>

    func deliver(_ rec: MirrorLedgerAccountsTokenRecord) async throws {
        _ = try await client.scheduleCarePlanExpiry(.with {
            $0.carePlan.notes = rec.status
        })
    }
}

/// Writes records to acme.appointments.v1.AppointmentQueryService.
struct MirrorLedgerAccountsTokenAppointmentQuery: MirrorLedgerAccountsTokenDestination {
    let client: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>

    func deliver(_ rec: MirrorLedgerAccountsTokenRecord) async throws {
        let request = Acme_Appointments_V1_CountAppointmentsRequest.with {
            $0.page.pageToken = rec.correlationID
            $0.filter.ownerID = rec.nextPageToken
            $0.filter.query = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.countAppointments(request)
        }
    }
}

/// Reads acme.ledger.v1.LedgerAccountQueryService/BrowseLedgerAccounts and hands what it keeps to the sink of its kind.
enum MirrorLedgerAccountsToken {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Ledger_V1_LedgerAccountQueryService.Client(wrapping: mesh)
        let response = try await reader.browseLedgerAccounts(.with { $0.orderBy = "main-mirror-ledger-accounts-token" })
        let entry = MirrorLedgerAccountsTokenRecord(
            nextPageToken: response.pageInfo.nextPageToken,
            message: Kit.Text.normalize(response.result.message),
            status: Kit.Text.normalize(response.result.status),
            correlationID: response.result.correlationID
        )
        let sinks: [any MirrorLedgerAccountsTokenDestination] = [
            MirrorLedgerAccountsTokenMedicalRecordSync(client: Acme_Patients_V1_MedicalRecordSyncService.Client(wrapping: mesh)),
            MirrorLedgerAccountsTokenCarePlanLifecycle(client: Acme_Careplans_V1_CarePlanLifecycleService.Client(wrapping: mesh)),
            MirrorLedgerAccountsTokenAppointmentQuery(client: Acme_Appointments_V1_AppointmentQueryService.Client(wrapping: mesh)),
        ]
        try await sinks[1].deliver(entry)
    }
}
