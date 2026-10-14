@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreRequestTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newRiskScoreRequest("code-718", title: "title-911")
        #expect(item.status == CareManagement.RiskScoreRequestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = CareManagement.newRiskScoreRequest("code-718", title: "title-911")
        try item.moveTo(CareManagement.RiskScoreRequestStatus.running)
        #expect(item.status == CareManagement.RiskScoreRequestStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newRiskScoreRequest("code-718", title: "title-911")
        item.status = CareManagement.RiskScoreRequestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreRequestStatus.new) }
    }
}
