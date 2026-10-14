import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillShowsID keeps of each CountShows response.
struct BackfillShowsIDRecord {
    var correlationID: String
    var message: String
}

/// Where BackfillShowsID hands each record.
protocol BackfillShowsIDSink {
    func push(_ rec: BackfillShowsIDRecord) async throws
}

/// Writes records to acme.concessions.v1.ConcessionStandCalculationService.
struct BackfillShowsIDConcessionStandCalculation: BackfillShowsIDSink {
    let client: Acme_Concessions_V1_ConcessionStandCalculationService.Client<MeshTransport>

    func push(_ rec: BackfillShowsIDRecord) async throws {
        let request = Acme_Concessions_V1_CalculateConcessionStandRequest.with {
            $0.concessionStandID = rec.correlationID
            $0.concessionStand.code = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.calculateConcessionStand(request)
        }
    }
}

/// Writes records to acme.appointments.v1.ProviderQueryService.
struct BackfillShowsIDProviderQuery: BackfillShowsIDSink {
    let client: Acme_Appointments_V1_ProviderQueryService.Client<MeshTransport>

    func push(_ rec: BackfillShowsIDRecord) async throws {
        let request = Acme_Appointments_V1_LookupProviderRequest.with {
            $0.providerID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.lookupProvider(request)
        }
    }
}

/// Hands records to acme.appointments.v1.ClinicSlotApprovalService.
struct BackfillShowsIDClinicSlotApproval: BackfillShowsIDSink {
    let client: Acme_Appointments_V1_ClinicSlotApprovalService.Client<MeshTransport>

    func push(_ rec: BackfillShowsIDRecord) async throws {
        let request = Acme_Appointments_V1_RejectClinicSlotRequest.with {
            $0.details.approverEmail = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.rejectClinicSlot(request)
        }
    }
}

/// Reads acme.shows.v1.ShowQueryService/CountShows and hands what it keeps to the sink of its kind.
enum BackfillShowsID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Shows_V1_ShowQueryService.Client(wrapping: mesh)
        let response = try await origin.countShows(.with { $0.orderBy = "default-backfill-shows-id" })
        let rec = BackfillShowsIDRecord(
            correlationID: Kit.Text.normalize(response.result.correlationID),
            message: Kit.Text.normalize(response.result.message)
        )
        let sinks: [any BackfillShowsIDSink] = [
            BackfillShowsIDConcessionStandCalculation(client: Acme_Concessions_V1_ConcessionStandCalculationService.Client(wrapping: mesh)),
            BackfillShowsIDProviderQuery(client: Acme_Appointments_V1_ProviderQueryService.Client(wrapping: mesh)),
            BackfillShowsIDClinicSlotApproval(client: Acme_Appointments_V1_ClinicSlotApprovalService.Client(wrapping: mesh)),
        ]
        try await sinks[0].push(rec)
    }
}
