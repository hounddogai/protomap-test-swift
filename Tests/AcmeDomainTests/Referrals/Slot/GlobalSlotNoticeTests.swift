@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalSlotNoticeTests {
    @Test func startsInNew() throws {
        let item = Referrals.newGlobalSlotNotice("code-105", title: "title-167")
        #expect(item.status == Referrals.GlobalSlotNoticeStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Referrals.newGlobalSlotNotice("code-105", title: "title-167")
        try item.moveTo(Referrals.GlobalSlotNoticeStatus.running)
        #expect(item.status == Referrals.GlobalSlotNoticeStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newGlobalSlotNotice("code-105", title: "title-167")
        item.status = Referrals.GlobalSlotNoticeStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.GlobalSlotNoticeStatus.new) }
    }
}
