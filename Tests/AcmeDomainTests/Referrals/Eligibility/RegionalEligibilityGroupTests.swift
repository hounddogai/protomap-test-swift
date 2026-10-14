@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalEligibilityGroupTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newRegionalEligibilityGroup("code-723", label: "label-513")
        #expect(item.status == Referrals.RegionalEligibilityGroupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newRegionalEligibilityGroup("code-723", label: "label-513")
        try item.moveTo(Referrals.RegionalEligibilityGroupStatus.pending)
        #expect(item.status == Referrals.RegionalEligibilityGroupStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newRegionalEligibilityGroup("code-723", label: "label-513")
        item.status = Referrals.RegionalEligibilityGroupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RegionalEligibilityGroupStatus.draft) }
    }
}
