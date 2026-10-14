@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingRiskScoreWindowTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newPendingRiskScoreWindow("code-555", label: "label-825")
        #expect(item.status == CareManagement.PendingRiskScoreWindowStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = CareManagement.newPendingRiskScoreWindow("code-555", label: "label-825")
        try item.moveTo(CareManagement.PendingRiskScoreWindowStatus.failed)
        #expect(item.status == CareManagement.PendingRiskScoreWindowStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newPendingRiskScoreWindow("code-555", label: "label-825")
        item.status = CareManagement.PendingRiskScoreWindowStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PendingRiskScoreWindowStatus.new) }
    }
}
