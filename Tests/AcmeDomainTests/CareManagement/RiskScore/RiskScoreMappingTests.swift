@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreMappingTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newRiskScoreMapping("code-351", name: "name-202")
        #expect(item.status == CareManagement.RiskScoreMappingStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = CareManagement.newRiskScoreMapping("code-351", name: "name-202")
        try item.moveTo(CareManagement.RiskScoreMappingStatus.scheduled)
        #expect(item.status == CareManagement.RiskScoreMappingStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newRiskScoreMapping("code-351", name: "name-202")
        item.status = CareManagement.RiskScoreMappingStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreMappingStatus.planned) }
    }
}
