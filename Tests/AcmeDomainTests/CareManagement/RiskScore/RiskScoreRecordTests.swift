@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreRecordTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newRiskScoreRecord("code-464", name: "name-858")
        #expect(item.status == CareManagement.RiskScoreRecordStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newRiskScoreRecord("code-464", name: "name-858")
        try item.moveTo(CareManagement.RiskScoreRecordStatus.revoked)
        #expect(item.status == CareManagement.RiskScoreRecordStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newRiskScoreRecord("code-464", name: "name-858")
        item.status = CareManagement.RiskScoreRecordStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreRecordStatus.requested) }
    }
}
