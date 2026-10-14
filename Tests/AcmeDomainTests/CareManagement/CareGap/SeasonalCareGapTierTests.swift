@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalCareGapTierTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newSeasonalCareGapTier("code-904", name: "name-592")
        #expect(item.status == CareManagement.SeasonalCareGapTierStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = CareManagement.newSeasonalCareGapTier("code-904", name: "name-592")
        try item.moveTo(CareManagement.SeasonalCareGapTierStatus.running)
        #expect(item.status == CareManagement.SeasonalCareGapTierStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newSeasonalCareGapTier("code-904", name: "name-592")
        item.status = CareManagement.SeasonalCareGapTierStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.SeasonalCareGapTierStatus.new) }
    }
}
