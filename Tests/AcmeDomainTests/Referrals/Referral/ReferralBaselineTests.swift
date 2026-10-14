@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralBaselineTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newReferralBaseline("code-759", label: "label-184")
        #expect(item.status == Referrals.ReferralBaselineStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Referrals.newReferralBaseline("code-759", label: "label-184")
        try item.moveTo(Referrals.ReferralBaselineStatus.archived)
        #expect(item.status == Referrals.ReferralBaselineStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newReferralBaseline("code-759", label: "label-184")
        item.status = Referrals.ReferralBaselineStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralBaselineStatus.`open`) }
    }
}
