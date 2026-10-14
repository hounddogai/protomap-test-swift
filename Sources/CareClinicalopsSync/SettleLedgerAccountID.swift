import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleLedgerAccountID keeps of each LookupLedgerAccount response.
struct SettleLedgerAccountIDRecord {
    var ledgerAccountID: String
    var currencyCode: String
}

/// Where SettleLedgerAccountID hands each record.
protocol SettleLedgerAccountIDWriter {
    func push(_ rec: SettleLedgerAccountIDRecord) async throws
}

/// Writes records to acme.shows.v1.ShowService.
struct SettleLedgerAccountIDShow: SettleLedgerAccountIDWriter {
    let client: Acme_Shows_V1_ShowService.Client<MeshTransport>

    func push(_ rec: SettleLedgerAccountIDRecord) async throws {
        _ = try await client.cloneShow(.with {
            $0.show.showID = rec.ledgerAccountID
            $0.show.title = rec.currencyCode
        })
    }
}

/// Sends records to acme.appointments.v1.AppointmentWorkflowService.
struct SettleLedgerAccountIDAppointmentWorkflow: SettleLedgerAccountIDWriter {
    let client: Acme_Appointments_V1_AppointmentWorkflowService.Client<MeshTransport>

    func push(_ rec: SettleLedgerAccountIDRecord) async throws {
        let request = Acme_Appointments_V1_RetryAppointmentWorkflowRequest.with {
            $0.details.initiatedBy = rec.ledgerAccountID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.retryAppointmentWorkflow(request)
        }
    }
}

/// Passes records to acme.authorization.v1.AccessPolicyValidationService.
struct SettleLedgerAccountIDAccessPolicyValidation: SettleLedgerAccountIDWriter {
    let client: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>

    func push(_ rec: SettleLedgerAccountIDRecord) async throws {
        _ = try await client.explainAccessPolicyDecision(.with {
            $0.reason = rec.ledgerAccountID
            $0.details.locale = rec.currencyCode
        })
    }
}

/// Reads acme.ledger.v1.LedgerAccountQueryService/LookupLedgerAccount and hands what it keeps to the sink of its kind.
enum SettleLedgerAccountID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Ledger_V1_LedgerAccountQueryService.Client(wrapping: mesh)
        let got = try await reader.lookupLedgerAccount(.with { $0.ledgerAccountID = "current-settle-ledger-account-id" })
        let row = SettleLedgerAccountIDRecord(
            ledgerAccountID: Kit.Text.normalize(got.ledgerAccount.ledgerAccountID),
            currencyCode: got.ledgerAccount.currencyCode
        )
        let sinks: [String: any SettleLedgerAccountIDWriter] = [
            "show": SettleLedgerAccountIDShow(client: Acme_Shows_V1_ShowService.Client(wrapping: mesh)),
            "appointment-workflow": SettleLedgerAccountIDAppointmentWorkflow(client: Acme_Appointments_V1_AppointmentWorkflowService.Client(wrapping: mesh)),
            "access-policy-validation": SettleLedgerAccountIDAccessPolicyValidation(client: Acme_Authorization_V1_AccessPolicyValidationService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "appointment-workflow" {
                continue
            }
            try await sink.push(row)
        }
    }
}
