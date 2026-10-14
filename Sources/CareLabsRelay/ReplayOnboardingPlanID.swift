import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayOnboardingPlanID keeps of each LookupOnboardingPlan response.
struct ReplayOnboardingPlanIDRecord {
    var onboardingPlanID: String
    var notes: String
}

/// Sends records to acme.prescriptions.v1.MedicationQueryService.
struct ReplayOnboardingPlanIDMedicationQuery {
    let client: Acme_Prescriptions_V1_MedicationQueryService.Client<MeshTransport>

    func forward(_ rec: ReplayOnboardingPlanIDRecord) async throws {
        let request = Acme_Prescriptions_V1_PeekMedicationRequest.with {
            $0.medicationID = rec.notes
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.peekMedication(request)
        }
    }
}

/// Reads acme.onboarding.v1.OnboardingPlanQueryService/LookupOnboardingPlan and hands what it keeps to acme.prescriptions.v1.MedicationQueryService.
enum ReplayOnboardingPlanID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Onboarding_V1_OnboardingPlanQueryService.Client(wrapping: mesh)
        let response = try await reader.lookupOnboardingPlan(.with { $0.onboardingPlanID = "nightly-replay-onboarding-plan-id" })
        let entry = ReplayOnboardingPlanIDRecord(
            onboardingPlanID: response.onboardingPlan.onboardingPlanID,
            notes: response.onboardingPlan.notes
        )
        try await ReplayOnboardingPlanIDMedicationQuery(client: Acme_Prescriptions_V1_MedicationQueryService.Client(wrapping: mesh)).forward(entry)
    }
}
