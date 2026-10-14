@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreSlotTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newRiskScoreSlot("code-247", title: "title-234")
        #expect(item.status == CareManagement.RiskScoreSlotStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newRiskScoreSlot("code-247", title: "title-234")
        try item.moveTo(CareManagement.RiskScoreSlotStatus.revoked)
        #expect(item.status == CareManagement.RiskScoreSlotStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newRiskScoreSlot("code-247", title: "title-234")
        item.status = CareManagement.RiskScoreSlotStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreSlotStatus.requested) }
    }
}
