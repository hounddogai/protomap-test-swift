@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotAuditTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newSlotAudit("code-859", label: "label-139")
        #expect(item.status == Referrals.SlotAuditStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newSlotAudit("code-859", label: "label-139")
        try item.moveTo(Referrals.SlotAuditStatus.pending)
        #expect(item.status == Referrals.SlotAuditStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newSlotAudit("code-859", label: "label-139")
        item.status = Referrals.SlotAuditStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotAuditStatus.draft) }
    }
}
