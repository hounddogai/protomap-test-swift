@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryFollowUpAdjustmentTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newPrimaryFollowUpAdjustment("code-658", label: "label-389")
        #expect(item.status == Referrals.PrimaryFollowUpAdjustmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newPrimaryFollowUpAdjustment("code-658", label: "label-389")
        try item.moveTo(Referrals.PrimaryFollowUpAdjustmentStatus.granted)
        #expect(item.status == Referrals.PrimaryFollowUpAdjustmentStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newPrimaryFollowUpAdjustment("code-658", label: "label-389")
        item.status = Referrals.PrimaryFollowUpAdjustmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PrimaryFollowUpAdjustmentStatus.requested) }
    }
}
