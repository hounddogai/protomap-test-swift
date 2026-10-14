@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalGoalDraftTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newSeasonalGoalDraft("code-736", label: "label-937")
        #expect(item.status == CareManagement.SeasonalGoalDraftStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = CareManagement.newSeasonalGoalDraft("code-736", label: "label-937")
        try item.moveTo(CareManagement.SeasonalGoalDraftStatus.rejected)
        #expect(item.status == CareManagement.SeasonalGoalDraftStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newSeasonalGoalDraft("code-736", label: "label-937")
        item.status = CareManagement.SeasonalGoalDraftStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.SeasonalGoalDraftStatus.proposed) }
    }
}
