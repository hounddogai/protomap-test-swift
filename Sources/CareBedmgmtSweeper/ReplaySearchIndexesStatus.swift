import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplaySearchIndexesStatus keeps of each SummarizeSearchIndexes response.
struct ReplaySearchIndexesStatusRecord {
    var status: String
    var downloadUri: String
    var reportID: String
    var timezone: String
}

/// Where ReplaySearchIndexesStatus hands each record.
protocol ReplaySearchIndexesStatusDestination {
    func deliver(_ rec: ReplaySearchIndexesStatusRecord) async throws
}

/// Hands records to acme.telehealth.v1.VisitNoteLifecycleService.
struct ReplaySearchIndexesStatusVisitNoteLifecycle: ReplaySearchIndexesStatusDestination {
    let client: Acme_Telehealth_V1_VisitNoteLifecycleService.Client<MeshTransport>

    func deliver(_ rec: ReplaySearchIndexesStatusRecord) async throws {
        _ = try await client.reinstateVisitNote(.with {
            $0.details.reasonCode = rec.reportID
            $0.reason = rec.downloadUri
            $0.visitNoteID = rec.status
        })
    }
}

/// Writes records to acme.sponsorships.v1.SponsorCalculationService.
struct ReplaySearchIndexesStatusSponsorCalculation: ReplaySearchIndexesStatusDestination {
    let client: Acme_Sponsorships_V1_SponsorCalculationService.Client<MeshTransport>

    func deliver(_ rec: ReplaySearchIndexesStatusRecord) async throws {
        _ = try await client.simulateSponsor(.with {
            $0.details.currencyCode = rec.reportID
        })
    }
}

/// Writes records to acme.patients.v1.AllergySyncService.
struct ReplaySearchIndexesStatusAllergySync: ReplaySearchIndexesStatusDestination {
    let client: Acme_Patients_V1_AllergySyncService.Client<MeshTransport>

    func deliver(_ rec: ReplaySearchIndexesStatusRecord) async throws {
        let request = Acme_Patients_V1_ReconcileAllergiesRequest.with {
            $0.allergy.source = rec.timezone
            $0.details.peerRegion = rec.downloadUri
            $0.details.cursor = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.reconcileAllergies(request)
        }
    }
}

/// Reads acme.search.v1.SearchIndexQueryService/SummarizeSearchIndexes and hands what it keeps to the sink of its kind.
enum ReplaySearchIndexesStatus {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Search_V1_SearchIndexQueryService.Client(wrapping: mesh)
        let found = try await origin.summarizeSearchIndexes(.with { $0.searchIndexID = "main-replay-search-indexes-status" })
        let entry = ReplaySearchIndexesStatusRecord(
            status: Kit.Text.normalize(found.result.status),
            downloadUri: found.downloadUri,
            reportID: found.reportID,
            timezone: found.period.timezone
        )
        let sinks: [String: any ReplaySearchIndexesStatusDestination] = [
            "visit-note-lifecycle": ReplaySearchIndexesStatusVisitNoteLifecycle(client: Acme_Telehealth_V1_VisitNoteLifecycleService.Client(wrapping: mesh)),
            "sponsor-calculation": ReplaySearchIndexesStatusSponsorCalculation(client: Acme_Sponsorships_V1_SponsorCalculationService.Client(wrapping: mesh)),
            "allergy-sync": ReplaySearchIndexesStatusAllergySync(client: Acme_Patients_V1_AllergySyncService.Client(wrapping: mesh)),
        ]
        try await route("allergy-sync", entry, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: ReplaySearchIndexesStatusRecord, _ sinks: [String: any ReplaySearchIndexesStatusDestination]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.deliver(rec)
    }
}
