@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingRiskScoreRollupTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newPendingRiskScoreRollup("code-679", name: "name-695")
        #expect(item.status == CareManagement.PendingRiskScoreRollupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = CareManagement.newPendingRiskScoreRollup("code-679", name: "name-695")
        try item.moveTo(CareManagement.PendingRiskScoreRollupStatus.running)
        #expect(item.status == CareManagement.PendingRiskScoreRollupStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newPendingRiskScoreRollup("code-679", name: "name-695")
        item.status = CareManagement.PendingRiskScoreRollupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PendingRiskScoreRollupStatus.new) }
    }
}
