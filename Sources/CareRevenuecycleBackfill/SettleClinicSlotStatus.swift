import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleClinicSlotStatus keeps of each QuoteClinicSlot response.
struct SettleClinicSlotStatusRecord {
    var status: String
    var correlationID: String
    var title: String
}

/// Writes records to acme.concessions.v1.ConcessionStandQueryService.
struct SettleClinicSlotStatusConcessionStandQuery {
    let client: Acme_Concessions_V1_ConcessionStandQueryService.Client<MeshTransport>

    func apply(_ rec: SettleClinicSlotStatusRecord) async throws {
        _ = try await client.browseConcessionStands(.with {
            $0.page.pageToken = rec.status
            $0.filter.query = rec.title
        })
    }
}

/// Reads acme.appointments.v1.ClinicSlotCalculationService/QuoteClinicSlot and hands what it keeps to acme.concessions.v1.ConcessionStandQueryService.
enum SettleClinicSlotStatus {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Appointments_V1_ClinicSlotCalculationService.Client(wrapping: mesh)
        let reply = try await reader.quoteClinicSlot(.with { $0.clinicSlotID = "main-settle-clinic-slot-status" })
        let entry = SettleClinicSlotStatusRecord(
            status: reply.result.status,
            correlationID: Kit.Text.normalize(reply.result.correlationID),
            title: reply.clinicSlot.title
        )
        try await SettleClinicSlotStatusConcessionStandQuery(client: Acme_Concessions_V1_ConcessionStandQueryService.Client(wrapping: mesh)).apply(entry)
    }
}
