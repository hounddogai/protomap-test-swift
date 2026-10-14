@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureAllocationTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newClosureAllocation("code-569", label: "label-785")
        #expect(item.status == Referrals.ClosureAllocationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Referrals.newClosureAllocation("code-569", label: "label-785")
        try item.moveTo(Referrals.ClosureAllocationStatus.active)
        #expect(item.status == Referrals.ClosureAllocationStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newClosureAllocation("code-569", label: "label-785")
        item.status = Referrals.ClosureAllocationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureAllocationStatus.draft) }
    }
}
