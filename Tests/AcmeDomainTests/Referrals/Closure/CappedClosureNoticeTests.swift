@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedClosureNoticeTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newCappedClosureNotice("code-482", name: "name-726")
        #expect(item.status == Referrals.CappedClosureNoticeStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newCappedClosureNotice("code-482", name: "name-726")
        try item.moveTo(Referrals.CappedClosureNoticeStatus.validated)
        #expect(item.status == Referrals.CappedClosureNoticeStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newCappedClosureNotice("code-482", name: "name-726")
        item.status = Referrals.CappedClosureNoticeStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.CappedClosureNoticeStatus.created) }
    }
}
