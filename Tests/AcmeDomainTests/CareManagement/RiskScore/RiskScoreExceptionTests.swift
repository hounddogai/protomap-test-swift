@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreExceptionTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newRiskScoreException("code-348", title: "title-222")
        #expect(item.status == CareManagement.RiskScoreExceptionStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = CareManagement.newRiskScoreException("code-348", title: "title-222")
        try item.moveTo(CareManagement.RiskScoreExceptionStatus.ready)
        #expect(item.status == CareManagement.RiskScoreExceptionStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newRiskScoreException("code-348", title: "title-222")
        item.status = CareManagement.RiskScoreExceptionStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreExceptionStatus.idle) }
    }
}
