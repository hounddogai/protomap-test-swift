@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreVarianceTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newRiskScoreVariance("code-906", name: "name-885")
        #expect(item.status == CareManagement.RiskScoreVarianceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = CareManagement.newRiskScoreVariance("code-906", name: "name-885")
        try item.moveTo(CareManagement.RiskScoreVarianceStatus.queued)
        #expect(item.status == CareManagement.RiskScoreVarianceStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newRiskScoreVariance("code-906", name: "name-885")
        item.status = CareManagement.RiskScoreVarianceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreVarianceStatus.new) }
    }
}
