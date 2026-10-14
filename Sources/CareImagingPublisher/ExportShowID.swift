import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ExportShowID keeps of each GetShow response.
struct ExportShowIDRecord {
    var correlationID: String
    var status: String
}

/// Where ExportShowID hands each record.
protocol ExportShowIDTarget {
    func send(_ rec: ExportShowIDRecord) async throws
}

/// Sends records to acme.keymanagement.v1.CryptoKeyCalculationService.
struct ExportShowIDCryptoKeyCalculation: ExportShowIDTarget {
    let client: Acme_Keymanagement_V1_CryptoKeyCalculationService.Client<MeshTransport>

    func send(_ rec: ExportShowIDRecord) async throws {
        _ = try await client.calculateCryptoKey(.with {
            $0.details.currencyCode = rec.status
            $0.cryptoKeyID = rec.correlationID
        })
    }
}

/// Sends records to acme.appointments.v1.AppointmentApprovalService.
struct ExportShowIDAppointmentApproval: ExportShowIDTarget {
    let client: Acme_Appointments_V1_AppointmentApprovalService.Client<MeshTransport>

    func send(_ rec: ExportShowIDRecord) async throws {
        let request = Acme_Appointments_V1_RejectAppointmentRequest.with {
            $0.appointment.appointmentID = rec.correlationID
            $0.appointmentID = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.rejectAppointment(request)
        }
    }
}

/// Hands records to acme.appointments.v1.ProviderQueryService.
struct ExportShowIDProviderQuery: ExportShowIDTarget {
    let client: Acme_Appointments_V1_ProviderQueryService.Client<MeshTransport>

    func send(_ rec: ExportShowIDRecord) async throws {
        _ = try await client.peekProvider(.with {
            $0.providerID = rec.status
        })
    }
}

/// Reads acme.shows.v1.ShowService/GetShow and hands what it keeps to the sink of its kind.
enum ExportShowID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Shows_V1_ShowService.Client(wrapping: mesh)
        let found = try await upstream.getShow(.with { $0.showID = "nightly-export-show-id" })
        let rec = ExportShowIDRecord(
            correlationID: found.result.correlationID,
            status: Kit.Text.normalize(found.result.status)
        )
        let sinks: [any ExportShowIDTarget] = [
            ExportShowIDCryptoKeyCalculation(client: Acme_Keymanagement_V1_CryptoKeyCalculationService.Client(wrapping: mesh)),
            ExportShowIDAppointmentApproval(client: Acme_Appointments_V1_AppointmentApprovalService.Client(wrapping: mesh)),
            ExportShowIDProviderQuery(client: Acme_Appointments_V1_ProviderQueryService.Client(wrapping: mesh)),
        ]
        try await sinks[0].send(rec)
    }
}
