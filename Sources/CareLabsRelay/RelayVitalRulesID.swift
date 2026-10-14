import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayVitalRulesID keeps of each GetVitalRules response.
struct RelayVitalRulesIDRecord {
    var correlationID: String
    var resultCorrelationID: String
    var vitalID: String
    var message: String
}

/// Where RelayVitalRulesID hands each record.
protocol RelayVitalRulesIDDestination {
    func apply(_ rec: RelayVitalRulesIDRecord) async throws
}

/// Hands records to acme.shows.v1.ShowCalculationService.
struct RelayVitalRulesIDShowCalculation: RelayVitalRulesIDDestination {
    let client: Acme_Shows_V1_ShowCalculationService.Client<MeshTransport>

    func apply(_ rec: RelayVitalRulesIDRecord) async throws {
        _ = try await client.estimateShow(.with {
            $0.showID = rec.correlationID
            $0.show.title = rec.vitalID
        })
    }
}

/// Sends records to acme.patients.v1.AllergyCalculationService.
struct RelayVitalRulesIDAllergyCalculation: RelayVitalRulesIDDestination {
    let client: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>

    func apply(_ rec: RelayVitalRulesIDRecord) async throws {
        _ = try await client.simulateAllergy(.with {
            $0.reason = rec.resultCorrelationID
            $0.allergy.allergyID = rec.correlationID
        })
    }
}

/// Passes records to acme.sponsorships.v1.SponsorCalculationService.
struct RelayVitalRulesIDSponsorCalculation: RelayVitalRulesIDDestination {
    let client: Acme_Sponsorships_V1_SponsorCalculationService.Client<MeshTransport>

    func apply(_ rec: RelayVitalRulesIDRecord) async throws {
        _ = try await client.explainSponsorCalculation(.with {
            $0.reason = rec.correlationID
            $0.sponsorID = rec.message
            $0.sponsor.sponsorID = rec.vitalID
        })
    }
}

/// Sends records to acme.careplans.v1.VitalWorkflowService.
struct RelayVitalRulesIDVitalWorkflow: RelayVitalRulesIDDestination {
    let client: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>

    func apply(_ rec: RelayVitalRulesIDRecord) async throws {
        _ = try await client.retryVitalWorkflow(.with {
            $0.vital.kind = rec.vitalID
        })
    }
}

/// Reads acme.careplans.v1.VitalValidationService/GetVitalRules and hands what it keeps to the sink of its kind.
enum RelayVitalRulesID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Careplans_V1_VitalValidationService.Client(wrapping: mesh)
        let response = try await reader.getVitalRules(.with { $0.vitalID = "nightly-relay-vital-rules-id" })
        let rec = RelayVitalRulesIDRecord(
            correlationID: response.vital.correlationID,
            resultCorrelationID: response.result.correlationID,
            vitalID: response.vital.vitalID,
            message: Kit.Text.normalize(response.result.message)
        )
        try await act("show-calculation", rec, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: RelayVitalRulesIDRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "show-calculation": { try await RelayVitalRulesIDShowCalculation(client: Acme_Shows_V1_ShowCalculationService.Client(wrapping: mesh)).apply(rec) },
            "allergy-calculation": { try await RelayVitalRulesIDAllergyCalculation(client: Acme_Patients_V1_AllergyCalculationService.Client(wrapping: mesh)).apply(rec) },
            "sponsor-calculation": { try await RelayVitalRulesIDSponsorCalculation(client: Acme_Sponsorships_V1_SponsorCalculationService.Client(wrapping: mesh)).apply(rec) },
            "vital-workflow": { try await RelayVitalRulesIDVitalWorkflow(client: Acme_Careplans_V1_VitalWorkflowService.Client(wrapping: mesh)).apply(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
