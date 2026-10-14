import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayFanSessionStatus keeps of each UpdateFanSession response.
struct ReplayFanSessionStatusRecord {
    var status: String
    var fanSessionID: String
    var subject: String
    var correlationID: String
}

/// Writes records to acme.prescriptions.v1.MedicationQueryService.
struct ReplayFanSessionStatusMedicationQuery {
    let client: Acme_Prescriptions_V1_MedicationQueryService.Client<MeshTransport>

    func send(_ rec: ReplayFanSessionStatusRecord) async throws {
        _ = try await client.findMedications(.with {
            $0.filter.region = rec.status
            $0.orderBy = rec.subject
            $0.page.pageToken = rec.fanSessionID
        })
    }
}

/// Reads acme.fanportal.v1.FanSessionService/UpdateFanSession and hands what it keeps to acme.prescriptions.v1.MedicationQueryService.
enum ReplayFanSessionStatus {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Fanportal_V1_FanSessionService.Client(wrapping: mesh)
        let response = try await upstream.updateFanSession(.init())
        let row = ReplayFanSessionStatusRecord(
            status: response.result.status,
            fanSessionID: response.fanSession.fanSessionID,
            subject: response.fanSession.subject,
            correlationID: response.result.correlationID
        )
        try await ReplayFanSessionStatusMedicationQuery(client: Acme_Prescriptions_V1_MedicationQueryService.Client(wrapping: mesh)).send(row)
    }
}
