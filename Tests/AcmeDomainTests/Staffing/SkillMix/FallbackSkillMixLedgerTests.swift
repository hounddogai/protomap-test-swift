@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackSkillMixLedgerTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newFallbackSkillMixLedger("code-66", label: "label-750")
        #expect(item.status == Staffing.FallbackSkillMixLedgerStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Staffing.newFallbackSkillMixLedger("code-66", label: "label-750")
        try item.moveTo(Staffing.FallbackSkillMixLedgerStatus.revoked)
        #expect(item.status == Staffing.FallbackSkillMixLedgerStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newFallbackSkillMixLedger("code-66", label: "label-750")
        item.status = Staffing.FallbackSkillMixLedgerStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FallbackSkillMixLedgerStatus.requested) }
    }
}
