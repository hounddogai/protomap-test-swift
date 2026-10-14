@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosurePolicyTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newClosurePolicy("code-347", label: "label-94")
        #expect(item.status == Referrals.ClosurePolicyStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Referrals.newClosurePolicy("code-347", label: "label-94")
        try item.moveTo(Referrals.ClosurePolicyStatus.retired)
        #expect(item.status == Referrals.ClosurePolicyStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newClosurePolicy("code-347", label: "label-94")
        item.status = Referrals.ClosurePolicyStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosurePolicyStatus.created) }
    }
}
