@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalCareGapPlanTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newSeasonalCareGapPlan("code-279", title: "title-477")
        #expect(item.status == CareManagement.SeasonalCareGapPlanStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = CareManagement.newSeasonalCareGapPlan("code-279", title: "title-477")
        try item.moveTo(CareManagement.SeasonalCareGapPlanStatus.inProgress)
        #expect(item.status == CareManagement.SeasonalCareGapPlanStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newSeasonalCareGapPlan("code-279", title: "title-477")
        item.status = CareManagement.SeasonalCareGapPlanStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.SeasonalCareGapPlanStatus.planned) }
    }
}
