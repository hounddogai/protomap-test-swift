@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedReferralSnapshotTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newCappedReferralSnapshot("code-292", name: "name-745")
        #expect(item.status == Referrals.CappedReferralSnapshotStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newCappedReferralSnapshot("code-292", name: "name-745")
        try item.moveTo(Referrals.CappedReferralSnapshotStatus.approved)
        #expect(item.status == Referrals.CappedReferralSnapshotStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newCappedReferralSnapshot("code-292", name: "name-745")
        item.status = Referrals.CappedReferralSnapshotStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.CappedReferralSnapshotStatus.proposed) }
    }
}
