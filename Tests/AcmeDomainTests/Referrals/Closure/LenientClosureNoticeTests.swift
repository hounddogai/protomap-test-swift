@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientClosureNoticeTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newLenientClosureNotice("code-410", title: "title-788")
        #expect(item.status == Referrals.LenientClosureNoticeStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Referrals.newLenientClosureNotice("code-410", title: "title-788")
        try item.moveTo(Referrals.LenientClosureNoticeStatus.resolved)
        #expect(item.status == Referrals.LenientClosureNoticeStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newLenientClosureNotice("code-410", title: "title-788")
        item.status = Referrals.LenientClosureNoticeStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LenientClosureNoticeStatus.`open`) }
    }
}
