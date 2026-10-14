@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreThresholdTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newRiskScoreThreshold("code-878", name: "name-870")
        #expect(item.status == CareManagement.RiskScoreThresholdStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newRiskScoreThreshold("code-878", name: "name-870")
        try item.moveTo(CareManagement.RiskScoreThresholdStatus.revoked)
        #expect(item.status == CareManagement.RiskScoreThresholdStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newRiskScoreThreshold("code-878", name: "name-870")
        item.status = CareManagement.RiskScoreThresholdStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreThresholdStatus.requested) }
    }
}
