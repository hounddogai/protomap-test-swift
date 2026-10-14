@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedReferralAllocationTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newCappedReferralAllocation("code-989", name: "name-368")
        #expect(item.status == Referrals.CappedReferralAllocationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Referrals.newCappedReferralAllocation("code-989", name: "name-368")
        try item.moveTo(Referrals.CappedReferralAllocationStatus.active)
        #expect(item.status == Referrals.CappedReferralAllocationStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newCappedReferralAllocation("code-989", name: "name-368")
        item.status = Referrals.CappedReferralAllocationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.CappedReferralAllocationStatus.draft) }
    }
}
