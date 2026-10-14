@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalRiskScorePolicyTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newSeasonalRiskScorePolicy("code-425", name: "name-501")
        #expect(item.status == CareManagement.SeasonalRiskScorePolicyStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = CareManagement.newSeasonalRiskScorePolicy("code-425", name: "name-501")
        try item.moveTo(CareManagement.SeasonalRiskScorePolicyStatus.published)
        #expect(item.status == CareManagement.SeasonalRiskScorePolicyStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newSeasonalRiskScorePolicy("code-425", name: "name-501")
        item.status = CareManagement.SeasonalRiskScorePolicyStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.SeasonalRiskScorePolicyStatus.created) }
    }
}
