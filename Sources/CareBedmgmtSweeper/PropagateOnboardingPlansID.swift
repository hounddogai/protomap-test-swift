import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagateOnboardingPlansID keeps of each SuggestOnboardingPlans response.
struct PropagateOnboardingPlansIDRecord {
    var correlationID: String
    var status: String
    var message: String
}

/// Passes records to acme.audiences.v1.AudienceService.
struct PropagateOnboardingPlansIDAudience {
    let client: Acme_Audiences_V1_AudienceService.Client<MeshTransport>

    func send(_ rec: PropagateOnboardingPlansIDRecord) async throws {
        _ = try await client.listAudiences(.with {
            $0.filter.region = rec.message
            $0.orderBy = rec.correlationID
        })
    }
}

/// Reads acme.onboarding.v1.OnboardingPlanQueryService/SuggestOnboardingPlans and hands what it keeps to acme.audiences.v1.AudienceService.
enum PropagateOnboardingPlansID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Onboarding_V1_OnboardingPlanQueryService.Client(wrapping: mesh)
        let found = try await origin.suggestOnboardingPlans(.with { $0.orderBy = "primary-propagate-onboarding-plans-id" })
        let entry = PropagateOnboardingPlansIDRecord(
            correlationID: found.result.correlationID,
            status: found.result.status,
            message: found.result.message
        )
        try await PropagateOnboardingPlansIDAudience(client: Acme_Audiences_V1_AudienceService.Client(wrapping: mesh)).send(entry)
    }
}
