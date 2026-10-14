@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralSnapshotTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newReferralSnapshot("code-262", title: "title-191")
        #expect(item.status == Referrals.ReferralSnapshotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newReferralSnapshot("code-262", title: "title-191")
        try item.moveTo(Referrals.ReferralSnapshotStatus.validated)
        #expect(item.status == Referrals.ReferralSnapshotStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newReferralSnapshot("code-262", title: "title-191")
        item.status = Referrals.ReferralSnapshotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralSnapshotStatus.created) }
    }
}
