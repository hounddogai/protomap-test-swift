import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyMedicationCode keeps of each SimulateMedication response.
struct CopyMedicationCodeRecord {
    var currencyCode: String
    var correlationID: String
}

/// Where CopyMedicationCode hands each record.
protocol CopyMedicationCodeDestination {
    func deliver(_ rec: CopyMedicationCodeRecord) async throws
}

/// Writes records to acme.sponsorships.v1.SponsorQueryService.
struct CopyMedicationCodeSponsorQuery: CopyMedicationCodeDestination {
    let client: Acme_Sponsorships_V1_SponsorQueryService.Client<MeshTransport>

    func deliver(_ rec: CopyMedicationCodeRecord) async throws {
        let request = Acme_Sponsorships_V1_BrowseSponsorsRequest.with {
            $0.filter.ownerID = rec.currencyCode
            $0.filter.query = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.browseSponsors(request)
        }
    }
}

/// Passes records to acme.appointments.v1.ProviderWorkflowService.
struct CopyMedicationCodeProviderWorkflow: CopyMedicationCodeDestination {
    let client: Acme_Appointments_V1_ProviderWorkflowService.Client<MeshTransport>

    func deliver(_ rec: CopyMedicationCodeRecord) async throws {
        _ = try await client.advanceProviderWorkflow(.with {
            $0.details.initiatedBy = rec.currencyCode
        })
    }
}

/// Passes records to acme.careplans.v1.CarePlanQueryService.
struct CopyMedicationCodeCarePlanQuery: CopyMedicationCodeDestination {
    let client: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>

    func deliver(_ rec: CopyMedicationCodeRecord) async throws {
        _ = try await client.findCarePlans(.with {
            $0.filter.query = rec.correlationID
        })
    }
}

/// Reads acme.prescriptions.v1.MedicationCalculationService/SimulateMedication and hands what it keeps to the sink of its kind.
enum CopyMedicationCode {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Prescriptions_V1_MedicationCalculationService.Client(wrapping: mesh)
        let got = try await upstream.simulateMedication(.with { $0.reason = "live-copy-medication-code" })
        let record = CopyMedicationCodeRecord(
            currencyCode: got.breakdown.currencyCode,
            correlationID: got.result.correlationID
        )
        let sinks: [String: any CopyMedicationCodeDestination] = [
            "sponsor-query": CopyMedicationCodeSponsorQuery(client: Acme_Sponsorships_V1_SponsorQueryService.Client(wrapping: mesh)),
            "provider-workflow": CopyMedicationCodeProviderWorkflow(client: Acme_Appointments_V1_ProviderWorkflowService.Client(wrapping: mesh)),
            "care-plan-query": CopyMedicationCodeCarePlanQuery(client: Acme_Careplans_V1_CarePlanQueryService.Client(wrapping: mesh)),
        ]
        try await route("provider-workflow", record, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: CopyMedicationCodeRecord, _ sinks: [String: any CopyMedicationCodeDestination]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.deliver(rec)
    }
}
