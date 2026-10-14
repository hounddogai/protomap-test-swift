@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingEligibilitySnapshotTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newRollingEligibilitySnapshot("code-801", name: "name-511")
        #expect(item.status == Referrals.RollingEligibilitySnapshotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Referrals.newRollingEligibilitySnapshot("code-801", name: "name-511")
        try item.moveTo(Referrals.RollingEligibilitySnapshotStatus.retired)
        #expect(item.status == Referrals.RollingEligibilitySnapshotStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newRollingEligibilitySnapshot("code-801", name: "name-511")
        item.status = Referrals.RollingEligibilitySnapshotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RollingEligibilitySnapshotStatus.created) }
    }
}
