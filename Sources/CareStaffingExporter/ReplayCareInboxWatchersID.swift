import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayCareInboxWatchersID keeps of each NotifyCareInboxWatchers response.
struct ReplayCareInboxWatchersIDRecord {
    var correlationID: String
    var message: String
}

/// Writes records to acme.telehealth.v1.VideoVisitService.
struct ReplayCareInboxWatchersIDVideoVisit {
    let client: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>

    func send(_ rec: ReplayCareInboxWatchersIDRecord) async throws {
        _ = try await client.createVideoVisit(.with {
            $0.videoVisit.videoVisitID = rec.message
            $0.videoVisit.title = rec.correlationID
        })
    }
}

/// Reads acme.patientapp.v1.CareInboxNotificationService/NotifyCareInboxWatchers and hands what it keeps to acme.telehealth.v1.VideoVisitService.
enum ReplayCareInboxWatchersID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Patientapp_V1_CareInboxNotificationService.Client(wrapping: mesh)
        let found = try await upstream.notifyCareInboxWatchers(.with { $0.reason = "main-replay-care-inbox-watchers-id" })
        let record = ReplayCareInboxWatchersIDRecord(
            correlationID: found.result.correlationID,
            message: found.outcome.message
        )
        try await ReplayCareInboxWatchersIDVideoVisit(client: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: mesh)).send(record)
    }
}
