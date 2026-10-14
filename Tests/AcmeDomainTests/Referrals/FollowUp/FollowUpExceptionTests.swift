@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpExceptionTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newFollowUpException("code-333", label: "label-681")
        #expect(item.status == Referrals.FollowUpExceptionStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Referrals.newFollowUpException("code-333", label: "label-681")
        try item.moveTo(Referrals.FollowUpExceptionStatus.resolved)
        #expect(item.status == Referrals.FollowUpExceptionStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newFollowUpException("code-333", label: "label-681")
        item.status = Referrals.FollowUpExceptionStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpExceptionStatus.`open`) }
    }
}
