@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictFollowUpAgreementTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newStrictFollowUpAgreement("code-480", name: "name-69")
        #expect(item.status == Referrals.StrictFollowUpAgreementStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newStrictFollowUpAgreement("code-480", name: "name-69")
        try item.moveTo(Referrals.StrictFollowUpAgreementStatus.rejected)
        #expect(item.status == Referrals.StrictFollowUpAgreementStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newStrictFollowUpAgreement("code-480", name: "name-69")
        item.status = Referrals.StrictFollowUpAgreementStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.StrictFollowUpAgreementStatus.proposed) }
    }
}
