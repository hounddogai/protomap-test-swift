@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryClosureNoticeTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newPrimaryClosureNotice("code-627", title: "title-354")
        #expect(item.status == Referrals.PrimaryClosureNoticeStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Referrals.newPrimaryClosureNotice("code-627", title: "title-354")
        try item.moveTo(Referrals.PrimaryClosureNoticeStatus.active)
        #expect(item.status == Referrals.PrimaryClosureNoticeStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newPrimaryClosureNotice("code-627", title: "title-354")
        item.status = Referrals.PrimaryClosureNoticeStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PrimaryClosureNoticeStatus.draft) }
    }
}
