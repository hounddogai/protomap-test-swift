@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreBaselineTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newRiskScoreBaseline("code-470", name: "name-856")
        #expect(item.status == CareManagement.RiskScoreBaselineStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = CareManagement.newRiskScoreBaseline("code-470", name: "name-856")
        try item.moveTo(CareManagement.RiskScoreBaselineStatus.retired)
        #expect(item.status == CareManagement.RiskScoreBaselineStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newRiskScoreBaseline("code-470", name: "name-856")
        item.status = CareManagement.RiskScoreBaselineStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreBaselineStatus.created) }
    }
}
