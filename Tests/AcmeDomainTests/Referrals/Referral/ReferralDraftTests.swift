@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralDraftTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newReferralDraft("code-408", name: "name-778")
        #expect(item.status == Referrals.ReferralDraftStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newReferralDraft("code-408", name: "name-778")
        try item.moveTo(Referrals.ReferralDraftStatus.rejected)
        #expect(item.status == Referrals.ReferralDraftStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newReferralDraft("code-408", name: "name-778")
        item.status = Referrals.ReferralDraftStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralDraftStatus.proposed) }
    }
}
