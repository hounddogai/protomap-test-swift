@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScorePolicyTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newRiskScorePolicy("code-314", title: "title-5")
        #expect(item.status == CareManagement.RiskScorePolicyStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = CareManagement.newRiskScorePolicy("code-314", title: "title-5")
        try item.moveTo(CareManagement.RiskScorePolicyStatus.failed)
        #expect(item.status == CareManagement.RiskScorePolicyStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newRiskScorePolicy("code-314", title: "title-5")
        item.status = CareManagement.RiskScorePolicyStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScorePolicyStatus.new) }
    }
}
