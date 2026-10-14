@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientNetworkNoticeTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newLenientNetworkNotice("code-131", title: "title-785")
        #expect(item.status == Referrals.LenientNetworkNoticeStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newLenientNetworkNotice("code-131", title: "title-785")
        try item.moveTo(Referrals.LenientNetworkNoticeStatus.approved)
        #expect(item.status == Referrals.LenientNetworkNoticeStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newLenientNetworkNotice("code-131", title: "title-785")
        item.status = Referrals.LenientNetworkNoticeStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LenientNetworkNoticeStatus.proposed) }
    }
}
