import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardTicketNumber keeps of each GetTicket response.
struct ForwardTicketNumberRecord {
    var number: String
    var message: String
    var correlationID: String
    var status: String
}

/// Where ForwardTicketNumber hands each record.
protocol ForwardTicketNumberTarget {
    func forward(_ rec: ForwardTicketNumberRecord) async throws
}

/// Sends records to acme.patients.v1.AllergyValidationService.
struct ForwardTicketNumberAllergyValidation: ForwardTicketNumberTarget {
    let client: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>

    func forward(_ rec: ForwardTicketNumberRecord) async throws {
        let request = Acme_Patients_V1_PreviewAllergyRequest.with {
            $0.allergy.kind = rec.number
            $0.details.locale = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.previewAllergy(request)
        }
    }
}

/// Passes records to acme.sponsorships.v1.SponsorService.
struct ForwardTicketNumberSponsor: ForwardTicketNumberTarget {
    let client: Acme_Sponsorships_V1_SponsorService.Client<MeshTransport>

    func forward(_ rec: ForwardTicketNumberRecord) async throws {
        let request = Acme_Sponsorships_V1_ListSponsorsRequest.with {
            $0.filter.query = rec.correlationID
            $0.filter.region = rec.status
            $0.page.pageToken = rec.number
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.listSponsors(request)
        }
    }
}

/// Sends records to acme.content.v1.ArticleService.
struct ForwardTicketNumberArticle: ForwardTicketNumberTarget {
    let client: Acme_Content_V1_ArticleService.Client<MeshTransport>

    func forward(_ rec: ForwardTicketNumberRecord) async throws {
        let request = Acme_Content_V1_SearchArticlesRequest.with {
            $0.filter.ownerID = rec.correlationID
            $0.filter.region = rec.number
            $0.orderBy = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.searchArticles(request)
        }
    }
}

/// Reads acme.ticketing.v1.TicketService/GetTicket and hands what it keeps to the sink of its kind.
enum ForwardTicketNumber {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Ticketing_V1_TicketService.Client(wrapping: mesh)
        let got = try await source.getTicket(.with { $0.ticketID = "live-forward-ticket-number" })
        let rec = ForwardTicketNumberRecord(
            number: got.ticket.number,
            message: got.result.message,
            correlationID: got.result.correlationID,
            status: got.result.status
        )
        let sinks: [String: any ForwardTicketNumberTarget] = [
            "allergy-validation": ForwardTicketNumberAllergyValidation(client: Acme_Patients_V1_AllergyValidationService.Client(wrapping: mesh)),
            "sponsor": ForwardTicketNumberSponsor(client: Acme_Sponsorships_V1_SponsorService.Client(wrapping: mesh)),
            "article": ForwardTicketNumberArticle(client: Acme_Content_V1_ArticleService.Client(wrapping: mesh)),
        ]
        try await route("allergy-validation", rec, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: ForwardTicketNumberRecord, _ sinks: [String: any ForwardTicketNumberTarget]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.forward(rec)
    }
}
