@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalRiskScorePreferenceTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newSeasonalRiskScorePreference("code-509", title: "title-86")
        #expect(item.status == CareManagement.SeasonalRiskScorePreferenceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = CareManagement.newSeasonalRiskScorePreference("code-509", title: "title-86")
        try item.moveTo(CareManagement.SeasonalRiskScorePreferenceStatus.validated)
        #expect(item.status == CareManagement.SeasonalRiskScorePreferenceStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newSeasonalRiskScorePreference("code-509", title: "title-86")
        item.status = CareManagement.SeasonalRiskScorePreferenceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.SeasonalRiskScorePreferenceStatus.created) }
    }
}
