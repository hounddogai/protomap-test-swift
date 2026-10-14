@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreOverrideTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newRiskScoreOverride("code-32", title: "title-634")
        #expect(item.status == CareManagement.RiskScoreOverrideStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newRiskScoreOverride("code-32", title: "title-634")
        try item.moveTo(CareManagement.RiskScoreOverrideStatus.revoked)
        #expect(item.status == CareManagement.RiskScoreOverrideStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newRiskScoreOverride("code-32", title: "title-634")
        item.status = CareManagement.RiskScoreOverrideStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreOverrideStatus.requested) }
    }
}
