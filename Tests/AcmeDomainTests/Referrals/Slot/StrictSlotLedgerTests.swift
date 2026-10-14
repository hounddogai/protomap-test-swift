@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictSlotLedgerTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newStrictSlotLedger("code-795", title: "title-306")
        #expect(item.status == Referrals.StrictSlotLedgerStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Referrals.newStrictSlotLedger("code-795", title: "title-306")
        try item.moveTo(Referrals.StrictSlotLedgerStatus.revoked)
        #expect(item.status == Referrals.StrictSlotLedgerStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newStrictSlotLedger("code-795", title: "title-306")
        item.status = Referrals.StrictSlotLedgerStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.StrictSlotLedgerStatus.requested) }
    }
}
