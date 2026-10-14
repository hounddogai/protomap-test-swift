@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotNoticeTests {
    @Test func startsInNew() throws {
        let item = Referrals.newSlotNotice("code-464", title: "title-42")
        #expect(item.status == Referrals.SlotNoticeStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Referrals.newSlotNotice("code-464", title: "title-42")
        try item.moveTo(Referrals.SlotNoticeStatus.queued)
        #expect(item.status == Referrals.SlotNoticeStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newSlotNotice("code-464", title: "title-42")
        item.status = Referrals.SlotNoticeStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotNoticeStatus.new) }
    }
}
