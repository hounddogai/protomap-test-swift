@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkNoticeTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newManualNetworkNotice("code-18", name: "name-434")
        #expect(item.status == Referrals.ManualNetworkNoticeStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Referrals.newManualNetworkNotice("code-18", name: "name-434")
        try item.moveTo(Referrals.ManualNetworkNoticeStatus.active)
        #expect(item.status == Referrals.ManualNetworkNoticeStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newManualNetworkNotice("code-18", name: "name-434")
        item.status = Referrals.ManualNetworkNoticeStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ManualNetworkNoticeStatus.draft) }
    }
}
