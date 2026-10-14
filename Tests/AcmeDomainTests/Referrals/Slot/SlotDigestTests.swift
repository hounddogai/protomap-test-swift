@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotDigestTests {
    @Test func startsInNew() throws {
        let item = Referrals.newSlotDigest("code-264", title: "title-842")
        #expect(item.status == Referrals.SlotDigestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Referrals.newSlotDigest("code-264", title: "title-842")
        try item.moveTo(Referrals.SlotDigestStatus.queued)
        #expect(item.status == Referrals.SlotDigestStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newSlotDigest("code-264", title: "title-842")
        item.status = Referrals.SlotDigestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotDigestStatus.new) }
    }
}
