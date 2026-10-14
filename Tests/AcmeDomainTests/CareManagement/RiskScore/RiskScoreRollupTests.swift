@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreRollupTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newRiskScoreRollup("code-506", name: "name-563")
        #expect(item.status == CareManagement.RiskScoreRollupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = CareManagement.newRiskScoreRollup("code-506", name: "name-563")
        try item.moveTo(CareManagement.RiskScoreRollupStatus.active)
        #expect(item.status == CareManagement.RiskScoreRollupStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newRiskScoreRollup("code-506", name: "name-563")
        item.status = CareManagement.RiskScoreRollupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreRollupStatus.draft) }
    }
}
