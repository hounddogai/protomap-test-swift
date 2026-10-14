@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreProfileTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newRiskScoreProfile("code-191", name: "name-418")
        #expect(item.status == CareManagement.RiskScoreProfileStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newRiskScoreProfile("code-191", name: "name-418")
        try item.moveTo(CareManagement.RiskScoreProfileStatus.pending)
        #expect(item.status == CareManagement.RiskScoreProfileStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newRiskScoreProfile("code-191", name: "name-418")
        item.status = CareManagement.RiskScoreProfileStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreProfileStatus.draft) }
    }
}
