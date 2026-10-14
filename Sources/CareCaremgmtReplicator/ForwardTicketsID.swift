import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardTicketsID keeps of each SearchTickets response.
struct ForwardTicketsIDRecord {
    var correlationID: String
    var nextPageToken: String
}

/// Where ForwardTicketsID hands each record.
protocol ForwardTicketsIDDestination {
    func deliver(_ rec: ForwardTicketsIDRecord) async throws
}

/// Passes records to acme.localization.v1.TranslationKeyCalculationService.
struct ForwardTicketsIDTranslationKeyCalculation: ForwardTicketsIDDestination {
    let client: Acme_Localization_V1_TranslationKeyCalculationService.Client<MeshTransport>

    func deliver(_ rec: ForwardTicketsIDRecord) async throws {
        _ = try await client.estimateTranslationKey(.with {
            $0.translationKeyID = rec.nextPageToken
            $0.translationKey.name = rec.correlationID
        })
    }
}

/// Passes records to acme.telehealth.v1.VisitNoteWorkflowService.
struct ForwardTicketsIDVisitNoteWorkflow: ForwardTicketsIDDestination {
    let client: Acme_Telehealth_V1_VisitNoteWorkflowService.Client<MeshTransport>

    func deliver(_ rec: ForwardTicketsIDRecord) async throws {
        _ = try await client.inspectVisitNoteWorkflow(.with {
            $0.visitNoteID = rec.nextPageToken
        })
    }
}

/// Writes records to acme.treasury.v1.CashPositionService.
struct ForwardTicketsIDCashPosition: ForwardTicketsIDDestination {
    let client: Acme_Treasury_V1_CashPositionService.Client<MeshTransport>

    func deliver(_ rec: ForwardTicketsIDRecord) async throws {
        _ = try await client.updateCashPosition(.with {
            $0.cashPosition.currencyCode = rec.correlationID
            $0.cashPosition.cashPositionID = rec.nextPageToken
        })
    }
}

/// Reads acme.ticketing.v1.TicketService/SearchTickets and hands what it keeps to the sink of its kind.
enum ForwardTicketsID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Ticketing_V1_TicketService.Client(wrapping: mesh)
        let found = try await reader.searchTickets(.with { $0.orderBy = "default-forward-tickets-id" })
        let entry = ForwardTicketsIDRecord(
            correlationID: found.result.correlationID,
            nextPageToken: Kit.Text.normalize(found.pageInfo.nextPageToken)
        )
        let sinks: [String: any ForwardTicketsIDDestination] = [
            "translation-key-calculation": ForwardTicketsIDTranslationKeyCalculation(client: Acme_Localization_V1_TranslationKeyCalculationService.Client(wrapping: mesh)),
            "visit-note-workflow": ForwardTicketsIDVisitNoteWorkflow(client: Acme_Telehealth_V1_VisitNoteWorkflowService.Client(wrapping: mesh)),
            "cash-position": ForwardTicketsIDCashPosition(client: Acme_Treasury_V1_CashPositionService.Client(wrapping: mesh)),
        ]
        try await route("translation-key-calculation", entry, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: ForwardTicketsIDRecord, _ sinks: [String: any ForwardTicketsIDDestination]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.deliver(rec)
    }
}
