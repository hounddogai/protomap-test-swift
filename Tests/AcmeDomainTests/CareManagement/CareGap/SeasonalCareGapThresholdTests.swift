@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalCareGapThresholdTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newSeasonalCareGapThreshold("code-720", name: "name-729")
        #expect(item.status == CareManagement.SeasonalCareGapThresholdStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = CareManagement.newSeasonalCareGapThreshold("code-720", name: "name-729")
        try item.moveTo(CareManagement.SeasonalCareGapThresholdStatus.rejected)
        #expect(item.status == CareManagement.SeasonalCareGapThresholdStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newSeasonalCareGapThreshold("code-720", name: "name-729")
        item.status = CareManagement.SeasonalCareGapThresholdStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.SeasonalCareGapThresholdStatus.proposed) }
    }
}
