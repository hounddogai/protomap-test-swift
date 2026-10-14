@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledReferralAllocationTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newScheduledReferralAllocation("code-501", label: "label-405")
        #expect(item.status == Referrals.ScheduledReferralAllocationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newScheduledReferralAllocation("code-501", label: "label-405")
        try item.moveTo(Referrals.ScheduledReferralAllocationStatus.pending)
        #expect(item.status == Referrals.ScheduledReferralAllocationStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newScheduledReferralAllocation("code-501", label: "label-405")
        item.status = Referrals.ScheduledReferralAllocationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ScheduledReferralAllocationStatus.draft) }
    }
}
