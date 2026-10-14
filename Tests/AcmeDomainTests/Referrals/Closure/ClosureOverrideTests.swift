@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureOverrideTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newClosureOverride("code-510", label: "label-512")
        #expect(item.status == Referrals.ClosureOverrideStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newClosureOverride("code-510", label: "label-512")
        try item.moveTo(Referrals.ClosureOverrideStatus.approved)
        #expect(item.status == Referrals.ClosureOverrideStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newClosureOverride("code-510", label: "label-512")
        item.status = Referrals.ClosureOverrideStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureOverrideStatus.proposed) }
    }
}
