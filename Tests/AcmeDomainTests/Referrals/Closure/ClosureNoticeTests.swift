@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureNoticeTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newClosureNotice("code-93", name: "name-340")
        #expect(item.status == Referrals.ClosureNoticeStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newClosureNotice("code-93", name: "name-340")
        try item.moveTo(Referrals.ClosureNoticeStatus.rejected)
        #expect(item.status == Referrals.ClosureNoticeStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newClosureNotice("code-93", name: "name-340")
        item.status = Referrals.ClosureNoticeStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureNoticeStatus.proposed) }
    }
}
