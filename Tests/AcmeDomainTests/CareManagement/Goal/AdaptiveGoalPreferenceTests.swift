@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveGoalPreferenceTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newAdaptiveGoalPreference("code-227", label: "label-301")
        #expect(item.status == CareManagement.AdaptiveGoalPreferenceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = CareManagement.newAdaptiveGoalPreference("code-227", label: "label-301")
        try item.moveTo(CareManagement.AdaptiveGoalPreferenceStatus.rejected)
        #expect(item.status == CareManagement.AdaptiveGoalPreferenceStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newAdaptiveGoalPreference("code-227", label: "label-301")
        item.status = CareManagement.AdaptiveGoalPreferenceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AdaptiveGoalPreferenceStatus.proposed) }
    }
}
