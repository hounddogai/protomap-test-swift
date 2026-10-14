@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveGoalBaselineTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newAdaptiveGoalBaseline("code-623", title: "title-146")
        #expect(item.status == CareManagement.AdaptiveGoalBaselineStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = CareManagement.newAdaptiveGoalBaseline("code-623", title: "title-146")
        try item.moveTo(CareManagement.AdaptiveGoalBaselineStatus.inProgress)
        #expect(item.status == CareManagement.AdaptiveGoalBaselineStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newAdaptiveGoalBaseline("code-623", title: "title-146")
        item.status = CareManagement.AdaptiveGoalBaselineStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AdaptiveGoalBaselineStatus.planned) }
    }
}
