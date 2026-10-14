@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkAgreementTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newManualNetworkAgreement("code-38", name: "name-486")
        #expect(item.status == Referrals.ManualNetworkAgreementStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newManualNetworkAgreement("code-38", name: "name-486")
        try item.moveTo(Referrals.ManualNetworkAgreementStatus.approved)
        #expect(item.status == Referrals.ManualNetworkAgreementStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newManualNetworkAgreement("code-38", name: "name-486")
        item.status = Referrals.ManualNetworkAgreementStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ManualNetworkAgreementStatus.proposed) }
    }
}
