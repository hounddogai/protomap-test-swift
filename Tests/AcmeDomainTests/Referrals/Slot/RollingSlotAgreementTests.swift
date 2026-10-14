@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingSlotAgreementTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newRollingSlotAgreement("code-323", name: "name-513")
        #expect(item.status == Referrals.RollingSlotAgreementStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newRollingSlotAgreement("code-323", name: "name-513")
        try item.moveTo(Referrals.RollingSlotAgreementStatus.approved)
        #expect(item.status == Referrals.RollingSlotAgreementStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newRollingSlotAgreement("code-323", name: "name-513")
        item.status = Referrals.RollingSlotAgreementStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RollingSlotAgreementStatus.proposed) }
    }
}
