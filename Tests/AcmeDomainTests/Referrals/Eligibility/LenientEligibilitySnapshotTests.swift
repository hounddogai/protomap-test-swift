@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientEligibilitySnapshotTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newLenientEligibilitySnapshot("code-565", label: "label-616")
        #expect(item.status == Referrals.LenientEligibilitySnapshotStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Referrals.newLenientEligibilitySnapshot("code-565", label: "label-616")
        try item.moveTo(Referrals.LenientEligibilitySnapshotStatus.closed)
        #expect(item.status == Referrals.LenientEligibilitySnapshotStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newLenientEligibilitySnapshot("code-565", label: "label-616")
        item.status = Referrals.LenientEligibilitySnapshotStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LenientEligibilitySnapshotStatus.draft) }
    }
}
