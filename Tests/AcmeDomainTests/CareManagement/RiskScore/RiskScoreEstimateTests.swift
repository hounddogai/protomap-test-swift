@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreEstimateTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newRiskScoreEstimate("code-796", title: "title-330")
        #expect(item.status == CareManagement.RiskScoreEstimateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = CareManagement.newRiskScoreEstimate("code-796", title: "title-330")
        try item.moveTo(CareManagement.RiskScoreEstimateStatus.expired)
        #expect(item.status == CareManagement.RiskScoreEstimateStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newRiskScoreEstimate("code-796", title: "title-330")
        item.status = CareManagement.RiskScoreEstimateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreEstimateStatus.requested) }
    }
}
