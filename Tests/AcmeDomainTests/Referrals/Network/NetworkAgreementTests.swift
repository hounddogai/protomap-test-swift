@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkAgreementTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newNetworkAgreement("code-367", label: "label-694")
        #expect(item.status == Referrals.NetworkAgreementStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newNetworkAgreement("code-367", label: "label-694")
        try item.moveTo(Referrals.NetworkAgreementStatus.rejected)
        #expect(item.status == Referrals.NetworkAgreementStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newNetworkAgreement("code-367", label: "label-694")
        item.status = Referrals.NetworkAgreementStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkAgreementStatus.proposed) }
    }
}
